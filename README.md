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

In Xcode: File → Add Package Dependency → this repo URL (or a local checkout).

Enable Push Notifications and Background Modes → Remote notifications.

Sample: `Example/App.swift`.
