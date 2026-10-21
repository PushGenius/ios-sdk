# pushgenius-ios

Standalone Swift package. `BigBrain` API for APNs.

```swift
import PushGenius

PushGenius.setHost("https://api.pushgeni.us")
BigBrain.initialize("YOUR_APP_ID", withLaunchOptions: launchOptions)
BigBrain.Notifications.requestPermission(true) { _ in }
BigBrain.login("user-123")
BigBrain.User.addTag(key: "plan", value: "pro")
```

Install with Swift Package Manager: in Xcode, File → Add Package Dependencies → `https://github.com/PushGenius/ios-sdk.git`, from version `0.2.0`. (Releases are git tags, e.g. `git tag 0.2.0 && git push origin 0.2.0`.)

The SDK picks up the APNs device token by hooking your app delegate, and forwards notification-center callbacks to any delegate your app already set, so no AppDelegate changes are needed. Requires iOS 15+.

Enable Push Notifications and Background Modes → Remote notifications.

## Count notifications received in the background (iOS)

iOS doesn't run your app when a notification arrives in the background, so by default the SDK can only report notifications that arrive while the app is open. To count every notification, add a Notification Service Extension. iOS runs it for each notification, even when your app is closed.

1. In Xcode, choose **File → New → Target → Notification Service Extension** and name it `NotificationService`. Set its minimum iOS version to match your app's (iOS 15 or later).
2. Select the extension target, and under **General → Frameworks and Libraries** add **PushGeniusNotificationService** from the PushGenius package.
3. Replace the contents of the extension's `NotificationService.swift` with:

   ```swift
   import PushGeniusNotificationService

   class NotificationService: BigBrainNotificationService {}
   ```

If you call `setHost`, also override the host in the extension: `override var host: String { "https://your-host" }`.

Example app with the extension set up, for testing on a device: [`Example/`](Example/README.md).
