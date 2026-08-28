import SwiftUI
import PushGenius

@main
struct PushGeniusExampleApp: App {
  init() {
    PushGenius.setHost("http://localhost:3001")
    OneSignal.initialize("YOUR_APP_ID")
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

struct ContentView: View {
  @State private var externalId = "user-1"
  @State private var status = "Not registered"

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("PushGenius").font(.largeTitle)
      Text(status).font(.caption)
      Button("Request permission") {
        OneSignal.Notifications.requestPermission(true) { granted in
          status = granted ? "Permission granted" : "Denied"
        }
      }
      TextField("External ID", text: $externalId)
      Button("Login") { OneSignal.login(externalId) }
      Button("Tag plan=pro") { OneSignal.User.addTag(key: "plan", value: "pro") }
    }
    .padding()
  }
}
