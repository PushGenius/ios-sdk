import Foundation
import UserNotifications

/// Base class for your app's Notification Service Extension. iOS runs the extension for every
/// PushGenius notification, even when your app isn't running, so it can report that the
/// notification reached the device.
///
/// In your extension's NotificationService.swift:
///
///     import PushGeniusNotificationService
///
///     class NotificationService: BigBrainNotificationService {}
///
/// This target only uses APIs that are allowed in app extensions; it doesn't depend on the main SDK.
open class BigBrainNotificationService: UNNotificationServiceExtension {
  /// The PushGenius API host. Override this if your app calls `BigBrain.setHost`.
  open var host: String { "https://api.pushgeni.us" }

  private let lock = NSLock()
  private var contentHandler: ((UNNotificationContent) -> Void)?
  private var content: UNNotificationContent?

  open override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    lock.lock()
    self.contentHandler = contentHandler
    content = request.content
    lock.unlock()

    guard
      let data = request.content.userInfo["data"] as? [String: Any],
      let appId = data["app_id"] as? String,
      let notificationId = data["notification_id"] as? String,
      let subscriptionId = data["subscription_id"] as? String,
      let url = URL(string: "\(host.trimmingCharacters(in: CharacterSet(charactersIn: "/")))/sdk/apps/\(appId)/events")
    else {
      finish()
      return
    }

    var req = URLRequest(url: url, timeoutInterval: 20)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.httpBody = try? JSONSerialization.data(withJSONObject: [
      "event": "received",
      "notification_id": notificationId,
      "subscription_id": subscriptionId,
    ])
    URLSession.shared.dataTask(with: req) { [weak self] _, _, _ in self?.finish() }.resume()
  }

  /// iOS is about to stop the extension; show the notification as is.
  open override func serviceExtensionTimeWillExpire() {
    finish()
  }

  /// Shows the notification. Only the first call does anything.
  private func finish() {
    lock.lock()
    let handler = contentHandler
    let content = content
    contentHandler = nil
    lock.unlock()
    if let handler, let content { handler(content) }
  }
}
