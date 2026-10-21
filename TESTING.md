# PushGenius device testing

Last updated 2026-10-21.

## When to run this

Run these tests on a real Android phone and a real iPhone before releasing any SDK version, and after any backend change to how notifications are sent or counted. Simulators and emulators can't stand in: push delivery, background display and the iOS extension only behave correctly on real devices.

Each test sends one notification in one app state, then checks that it showed and that the dashboard counted it once. The test apps live in the SDK repos and use the SDK code in that repo, so they test your local changes:

- Android: [`sdks/android/sample/`](https://github.com/PushGenius/android-sdk/tree/main/sample) (setup in its README)
- iOS: [`sdks/ios/Example/`](Example/README.md) (setup in its README)

## One-time setup

Use one PushGenius app in the dashboard just for testing, so test sends never reach real users.

1. Create the test app in the dashboard and note its **app ID** and **REST API key** (both under Settings).
2. **Android credentials:** in Firebase, add an Android app with package name `us.pushgeni.sample`. Save that Firebase project's service account under **Settings → Android**, and keep its `google-services.json` for the sample.
3. **iOS credentials:** save your APNs `.p8` key, key ID, team ID and a bundle ID only you use (for example `com.yourname.pushgenius-test`) under **Settings → iOS**.
4. **Turn Production APNs off** for this app. Builds run from Xcode get sandbox tokens, which production APNs rejects. Turn it on only when testing a TestFlight or App Store build.
5. **Android sample config** (not committed):
   - Put `google-services.json` in `sdks/android/sample/`.
   - Add `pushgenius.appId=YOUR_APP_ID` to `sdks/android/local.properties`.
6. **iOS example config** (not committed): copy `sdks/ios/Example/Local.example.xcconfig` to `Local.xcconfig` and fill in the bundle ID, your Apple team ID and the app ID.

These files stay on your machine between test runs, so later runs skip straight to installing the apps.

## Sending a test and reading the result

Send every test to the external ID the test app logged in as (`user-1` by default), with a title that names the platform, state and attempt. A unique title is how you find each message on the dashboard.

```sh
curl -X POST https://api.pushgeni.us/notifications \
  -H "Authorization: Key YOUR_REST_API_KEY" -H "Content-Type: application/json" \
  -d '{"app_id":"YOUR_APP_ID","headings":{"en":"Android swiped 1"},"contents":{"en":"test"},"data":{"order_id":"42"},"include_aliases":{"external_id":["user-1"]}}'
```

A response with an empty `id` and an `errors` array means nobody matched: the app hasn't logged in, or isn't registered yet.

Then open the dashboard's **Messages** page and find the message by its title:

- **Sent 1:** APNs or FCM accepted it. Sent 0 points at the credentials or the token.
- **Received 1:** the device reported it arrived.
- **Clicked 1:** it was tapped. A tap also counts as received.

Each device counts at most once per message, so with one test phone every number should be 0 or 1. Counts can take a few seconds to show; refresh before deciding a test failed.

## Android

Install the sample from `sdks/android/` with the phone plugged in and USB debugging on:

```sh
./gradlew :sample:installDebug
```

In the app, tap **Request permission** (Android 13 and later asks), **Login user-1**, then **Refresh IDs**. A subscription ID means the phone is registered. Then send one message per row:

| # | App state | How to get there | Expect |
| --- | --- | --- | --- |
| 1 | Open | App on screen | Notification shows with the bell icon; Received 1 |
| 2 | Background | Press Home | Notification shows; Received 1 |
| 3 | Swiped away | Swipe it out of recents | Notification shows; Received 1 |
| 4 | Tap | Tap the notification from row 3 | App opens and shows the tap's ID and `order_id: 42`; Clicked 1, Received stays 1 |
| 5 | Tap again | Send another, tap it, then reopen it from the shade if it's still there | Clicked stays 1 |
| 6 | Force-stopped | Settings → Apps → Force stop | Nothing arrives; Sent 1, Received 0. Android blocks it by design |

- [ ] Rows 1–5 pass
- [ ] Row 6 behaves as expected

Row 3 is the one this setup exists for: the SDK shows the notification itself, so it's counted even though the app isn't running.

## iOS

Open `sdks/ios/Example/PushGeniusExample.xcodeproj`, choose your iPhone and run. The first run on a new phone needs **Developer Mode** on (Settings → Privacy & Security) and the developer profile trusted (Settings → General → VPN & Device Management).

In the app, tap **Request permission**, **Login**, then **Refresh IDs**. A subscription ID means the phone is registered. Then send one message per row:

| # | App state | How to get there | Expect |
| --- | --- | --- | --- |
| 1 | Open | App on screen | Banner shows; Received 1 |
| 2 | Background | Swipe up to Home | Notification shows; Received 1 |
| 3 | Closed | Swipe it away in the app switcher, or press Stop in Xcode | Notification shows; Received 1 |
| 4 | Tap | Tap the notification from row 3 | App opens and shows the tap's ID and `order_id`; Clicked 1, Received stays 1 |
| 5 | Control: no extension | In the app target's Build Phases, remove NotificationService from Embed Foundation Extensions; run, close the app, send | Notification shows; Received 0 |

- [ ] Rows 1–4 pass
- [ ] Row 5 shows Received 0, then put the extension back

Row 3 is what the extension is for: iOS runs it for every notification even when the app is closed. Row 5 proves it's the extension doing the counting. Run it on every release.

## Troubleshooting

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| curl returns an empty `id` and `errors` | No device matches `user-1` | Tap Login in the app, then Refresh IDs and check there's a subscription ID |
| Subscription ID stays empty | Wrong app ID, no permission, or (Android) no `google-services.json` | Check the local config file, allow notifications, reinstall |
| Sent 0 on iOS | Production APNs is on for a build run from Xcode, or the bundle ID doesn't match | Turn Production APNs off; make the dashboard bundle ID match `Local.xcconfig` |
| Sent 0 on Android | Service account is from a different Firebase project than `google-services.json` | Save the service account from the same Firebase project |
| Android: swiped-away app gets nothing | Battery saver holding messages (common on Samsung and Xiaomi) | Set the app's battery use to Unrestricted and resend |
| Android: icon is a white square | No monochrome small icon set | The sample has one; in real apps set `default_notification_icon` in the manifest |
| iOS: Received 0 when closed, notification still shows | Extension isn't running | Check the extension's minimum iOS version isn't newer than the phone's, and that it's embedded in the app |
| iOS: still unsure if the extension runs | | In Xcode, Debug → Attach to Process by PID or Name → `NotificationService`, send, and see whether breakpoints hit |
| Counts look doubled | More than one test device logged in as `user-1` | Log out on the other device, or use a different external ID per device |

## Release checklist

Work through this in order for each new SDK version. Testing comes before tagging, because a pushed tag is what SPM and JitPack users install.

- [ ] Bump the version the SDK reports: `SDK_VERSION` in Android `Client.kt` and `sdkVersion` in iOS `Client.swift`. The backend uses it to decide how to send, so don't skip it
- [ ] Bump the wrappers: React Native and Ionic `package.json`, Flutter `pubspec.yaml`, podspec, `android/build.gradle.kts` and `CHANGELOG.md`
- [ ] Copy the native code into the wrappers: `npm run sync-native` (React Native, Ionic) and `scripts/sync-native.sh` (Flutter)
- [ ] Run the Android tests above on a real phone
- [ ] Run the iOS tests above on a real iPhone
- [ ] Tag and push iOS and Android, then confirm JitPack built the Android tag
- [ ] Publish from your own terminal (npm asks for 2FA): `npm publish` in `sdks/react-native` and `sdks/ionic`, `flutter pub publish` in `sdks/flutter`
- [ ] Update the versions on the marketing docs' Install section and deploy the marketing site
