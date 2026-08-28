// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "PushGenius",
  platforms: [.iOS(.v15), .macOS(.v12)],
  products: [
    .library(name: "PushGenius", targets: ["PushGenius"]),
  ],
  targets: [
    .target(name: "PushGenius", path: "Sources/PushGenius"),
  ]
)
