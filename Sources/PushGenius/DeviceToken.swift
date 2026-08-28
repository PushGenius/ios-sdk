import Foundation
#if canImport(UserNotifications)
import UserNotifications
import UIKit
#endif

final class DeviceTokenStore: NSObject {
  static let shared = DeviceTokenStore()
  private(set) var token: String?

  func start() {
#if canImport(UIKit)
    UIApplication.shared.registerForRemoteNotifications()
#endif
    PushGeniusSwizzle.install()
  }

  func requestPermission(completion: @escaping (Bool) -> Void) {
#if canImport(UserNotifications)
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
      DispatchQueue.main.async {
#if canImport(UIKit)
        UIApplication.shared.registerForRemoteNotifications()
#endif
        completion(granted)
      }
    }
#else
    completion(false)
#endif
  }

  func didRegister(deviceToken: Data) {
    token = deviceToken.map { String(format: "%02x", $0) }.joined()
    Task { await Client.shared.register() }
  }
}

enum PushGeniusSwizzle {
  static func install() {
#if canImport(UIKit)
    NotificationCenter.default.addObserver(forName: UIApplication.didFinishLaunchingNotification, object: nil, queue: .main) { _ in
      UIApplication.shared.registerForRemoteNotifications()
    }
#endif
  }
}

#if canImport(UserNotifications)
extension DeviceTokenStore: UNUserNotificationCenterDelegate {
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let userInfo = notification.request.content.userInfo
    let id = (userInfo["notification_id"] as? String) ?? ""
    Client.shared.emitForeground(NotificationWillDisplayEvent(notificationId: id, body: notification.request.content.body))
    Client.shared.track(event: "received", notificationId: id)
    completionHandler([.banner, .sound, .badge])
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    let id = (userInfo["notification_id"] as? String) ?? ""
    var extra: [String: Any] = [:]
    if let data = userInfo["data"] as? [String: Any] { extra = data }
    Client.shared.emitClick(NotificationClickEvent(notificationId: id, additionalData: extra))
    Client.shared.track(event: "clicked", notificationId: id)
    completionHandler()
  }
}
#endif
