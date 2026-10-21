// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "PushGenius",
  platforms: [.iOS(.v15), .macOS(.v12)],
  products: [
    .library(name: "PushGenius", targets: ["PushGenius"]),
    // Add to your Notification Service Extension target to report receipt while the app isn't running.
    .library(name: "PushGeniusNotificationService", targets: ["PushGeniusNotificationService"]),
  ],
  targets: [
    .target(
      name: "PushGenius",
      path: "Sources/PushGenius",
      resources: [.copy("PrivacyInfo.xcprivacy")]
    ),
    .target(name: "PushGeniusNotificationService", path: "Sources/PushGeniusNotificationService"),
  ]
)
