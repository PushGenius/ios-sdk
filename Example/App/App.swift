import SwiftUI
import PushGenius

/// Holds the last notification tap so the screen can show it, including the tap that launched the app.
final class ClickLog: ObservableObject {
  static let shared = ClickLog()
  @Published var last: String?
}

@main
struct PushGeniusExampleApp: App {
  init() {
    // Both values come from Local.xcconfig through Info.plist (see Config.xcconfig).
    let info = Bundle.main.infoDictionary ?? [:]
    if let host = info["PushGeniusHost"] as? String, !host.isEmpty { BigBrain.setHost(host) }
    BigBrain.initialize(info["PushGeniusAppId"] as? String ?? "")
    BigBrain.Notifications.addClickListener { event in
      ClickLog.shared.last = "\(event.notificationId)\n\(event.additionalData)"
    }
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

struct ContentView: View {
  @ObservedObject private var clicks = ClickLog.shared
  @State private var externalId = "user-1"
  @State private var status = "Not registered"
  @State private var ids = ""

  private var appIdMissing: Bool {
    (Bundle.main.object(forInfoDictionaryKey: "PushGeniusAppId") as? String ?? "").isEmpty
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Text("PushGenius").font(.largeTitle)
        if appIdMissing {
          Text("Set PUSHGENIUS_APP_ID in Example/Local.xcconfig").foregroundStyle(.red)
        }
        Text(status).font(.caption)
        Button("Request permission") {
          BigBrain.Notifications.requestPermission(true) { granted in
            status = granted ? "Permission granted" : "Denied"
          }
        }
        TextField("External ID", text: $externalId)
          .textFieldStyle(.roundedBorder)
          .textInputAutocapitalization(.never)
        Button("Login") { BigBrain.login(externalId) }
        Button("Tag plan=pro") { BigBrain.User.addTag(key: "plan", value: "pro") }
        Button("Refresh IDs") { refreshIds() }
        Text(ids).font(.caption.monospaced()).textSelection(.enabled)
        if let last = clicks.last {
          Text("Last tap:\n\(last)").font(.caption.monospaced()).textSelection(.enabled)
        }
      }
      .padding()
    }
    .onAppear(perform: refreshIds)
  }

  private func refreshIds() {
    let sub = BigBrain.User.pushSubscription
    ids = """
      External ID: \(BigBrain.User.externalId ?? "-")
      Subscription: \(sub.id ?? "-")
      Opted in: \(sub.optedIn)
      Token: \(sub.token.map { String($0.prefix(16)) + "…" } ?? "-")
      """
  }
}
