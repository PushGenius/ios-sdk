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

Install with Swift Package Manager: in Xcode, File → Add Package Dependencies → `https://github.com/PushGenius/ios-sdk.git`, from version `0.1.0`. (Releases are git tags, e.g. `git tag 0.1.0 && git push origin 0.1.0`.)

The SDK picks up the APNs device token by hooking your app delegate, and forwards notification-center callbacks to any delegate your app already set, so no AppDelegate changes are needed. Requires iOS 15+.

Enable Push Notifications and Background Modes → Remote notifications.

Sample: `Example/App.swift`.
