import Foundation
import PushGeniusNotificationService

/// Reports every notification as received, even while the app isn't running.
class NotificationService: BigBrainNotificationService {
  // Only needed because the example can point at a local backend. Apps that don't call setHost can leave this out.
  override var host: String {
    let host = Bundle.main.object(forInfoDictionaryKey: "PushGeniusHost") as? String ?? ""
    return host.isEmpty ? super.host : host
  }
}
