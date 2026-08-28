import Foundation

actor Client {
  static let shared = Client()

  var onesignalId: String?
  var externalId: String?
  var subscriptionId: String?
  var optedIn: Bool = true
  nonisolated var clickListeners: [(NotificationClickEvent) -> Void] {
    get { Self._clicks }
    set { Self._clicks = newValue }
  }
  nonisolated var foregroundListeners: [(NotificationWillDisplayEvent) -> Void] {
    get { Self._fg }
    set { Self._fg = newValue }
  }

  nonisolated(unsafe) private static var _clicks: [(NotificationClickEvent) -> Void] = []
  nonisolated(unsafe) private static var _fg: [(NotificationWillDisplayEvent) -> Void] = []

  func register() async {
    guard !PushGenius.appId.isEmpty else { return }
    var subscriptions: [[String: Any]] = []
    if let token = DeviceTokenStore.shared.token {
      subscriptions.append([
        "type": "iOSPush",
        "token": token,
        "enabled": optedIn,
        "notification_types": optedIn ? 1 : -2,
        "sdk": "pushgenius/0.1.0",
        "device_os": "iOS",
      ])
    }
    var identity: [String: String] = [:]
    if let externalId { identity["external_id"] = externalId }
    if let onesignalId { identity["onesignal_id"] = onesignalId }
    let body: [String: Any] = [
      "identity": identity,
      "subscriptions": subscriptions,
    ]
    if let json = await post(path: "/sdk/apps/\(PushGenius.appId)/users", body: body) {
      apply(json)
    }
  }

  func login(externalId: String) async {
    self.externalId = externalId
    var body: [String: Any] = ["external_id": externalId]
    if let subscriptionId { body["subscription_id"] = subscriptionId }
    if let json = await post(path: "/sdk/apps/\(PushGenius.appId)/login", body: body) {
      apply(json)
    }
  }

  func logout() async {
    externalId = nil
    onesignalId = nil
    await register()
  }

  func patch(properties: [String: Any]? = nil, identity: [String: String]? = nil) async {
    var body: [String: Any] = [:]
    if let properties { body["properties"] = properties }
    if let identity { body["identity"] = identity }
    guard let onesignalId else {
      await register()
      return
    }
    _ = await patch(
      path: "/sdk/apps/\(PushGenius.appId)/users/by/onesignal_id/\(onesignalId)",
      body: body
    )
  }

  func setPermission(_ granted: Bool) async {
    optedIn = granted
    if let subscriptionId {
      _ = await post(path: "/sdk/apps/\(PushGenius.appId)/events", body: [
        "event": "permission",
        "subscription_id": subscriptionId,
        "permission": granted,
      ])
    }
    await register()
  }

  nonisolated func emitClick(_ event: NotificationClickEvent) {
    DispatchQueue.main.async { Self._clicks.forEach { $0(event) } }
  }

  nonisolated func emitForeground(_ event: NotificationWillDisplayEvent) {
    DispatchQueue.main.async { Self._fg.forEach { $0(event) } }
  }

  nonisolated func track(event: String, notificationId: String) {
    Task {
      guard let subscriptionId = await self.subscriptionId else { return }
      _ = await self.post(path: "/sdk/apps/\(PushGenius.appId)/events", body: [
        "event": event,
        "notification_id": notificationId,
        "subscription_id": subscriptionId,
      ])
    }
  }

  private func apply(_ json: [String: Any]) {
    if let identity = json["identity"] as? [String: Any] {
      onesignalId = identity["onesignal_id"] as? String
      externalId = identity["external_id"] as? String
    }
    if let subs = json["subscriptions"] as? [[String: Any]], let first = subs.first {
      subscriptionId = first["id"] as? String
      if let enabled = first["enabled"] as? Bool { optedIn = enabled }
    }
  }

  private func post(path: String, body: [String: Any]) async -> [String: Any]? {
    await request(method: "POST", path: path, body: body)
  }

  private func patch(path: String, body: [String: Any]) async -> [String: Any]? {
    await request(method: "PATCH", path: path, body: body)
  }

  private func request(method: String, path: String, body: [String: Any]) async -> [String: Any]? {
    guard let url = URL(string: PushGenius.host + path) else { return nil }
    var req = URLRequest(url: url)
    req.httpMethod = method
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.httpBody = try? JSONSerialization.data(withJSONObject: body)
    do {
      let (data, _) = try await URLSession.shared.data(for: req)
      return (try JSONSerialization.jsonObject(with: data) as? [String: Any])
    } catch {
      return nil
    }
  }
}
