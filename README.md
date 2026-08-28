# pushgenius-ios

Standalone Swift package. OneSignal-shaped API for APNs.

```swift
import PushGenius

PushGenius.setHost("https://api.pushgeni.us")
OneSignal.initialize("YOUR_APP_ID", withLaunchOptions: launchOptions)
OneSignal.Notifications.requestPermission(true) { _ in }
OneSignal.login("user-123")
OneSignal.User.addTag(key: "plan", value: "pro")
```

In Xcode: File → Add Package Dependency → this repo URL (or a local checkout).

Enable Push Notifications and Background Modes → Remote notifications.

Sample: `Example/App.swift`.
