# PushGenius example app

An iPhone app with the SDK and a Notification Service Extension already set up, for testing pushes on a real device. It uses the SDK from this repo, so it tests your local changes.

## Set up

1. In the dashboard, save your APNs key under **Settings → iOS** with the bundle ID you'll use below. Turn **Production APNs** off: builds run from Xcode get sandbox tokens.
2. Copy `Local.example.xcconfig` to `Local.xcconfig` and fill in your bundle ID, team ID and PushGenius app ID. `Local.xcconfig` isn't committed.
3. Open `PushGeniusExample.xcodeproj`, choose your iPhone and run. Xcode registers the app and extension IDs and the push capability for your team.
4. In the app, tap **Request permission**, then **Login** (as `user-1` by default), then **Refresh IDs**. A subscription ID means the device is registered.

## Test

Send a test to the logged-in user:

```sh
curl -X POST https://api.pushgeni.us/notifications \
  -H "Authorization: Key YOUR_REST_API_KEY" -H "Content-Type: application/json" \
  -d '{"app_id":"YOUR_APP_ID","headings":{"en":"iOS closed 1"},"contents":{"en":"test"},"data":{"order_id":"42"},"include_aliases":{"external_id":["user-1"]}}'
```

Send one with the app open, one in the background, and one after swiping it away, then check each message's counts on the dashboard's Messages page. Each should show Received 1, and Clicked 1 once tapped. The app shows the last tap's ID and data.

If Received stays at 0 while the app is closed, the extension isn't running. In Xcode, choose **Debug → Attach to Process by PID or Name**, enter `NotificationService`, send another push and see whether breakpoints in `NotificationService.swift` hit.

## Changing the project

The project is generated from `project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen). After editing `project.yml`, run `xcodegen` in this folder and commit the regenerated project.
