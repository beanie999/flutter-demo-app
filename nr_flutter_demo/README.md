# nr_flutter_demo

A small Flutter app for demoing New Relic mobile monitoring on the iOS simulator
(built and tested on an iPhone 16 Pro simulator). It is paired with two Node
services that show distributed tracing from the app through a front end and a
back end.

```
Flutter app  ->  flutter-front-end (:3001)  ->  flutter-back-end (:3002)
```

The Node services live in sibling folders: `../flutter-front-end` and
`../flutter-back-end`.

## Features

| Screen | What it does | New Relic feature |
|---|---|---|
| Home | Editable username, plus a custom event with `country` and `animal` attributes | User ID, custom events |
| Network stats | Sends 10 requests to httpbin.org with randomly weighted status codes | HTTP requests and errors |
| Distributed tracing | Sends 10 calls to the front end, passing the username in an `x-username` header | Distributed tracing |
| Handled exceptions | Throws and catches 5 random exceptions | Handled exceptions |
| Crash | Triggers a random native crash | Crash analysis |

The app also records:
- **Breadcrumbs:** `navigation` (screen changes) and `UserAction` (button presses, tagged with the username).
- **Logs:** sent to New Relic from every screen, with the username appended. See `appLog` in `lib/app_state.dart`.

## Requirements

- Flutter (tested with 3.47.8) and Xcode with an iOS simulator
- iOS plugins are fetched with Swift Package Manager, so no Podfile or CocoaPods setup is needed
- Node 18 or later (for the services)
- A New Relic **mobile app token** for the iOS app, and a **license key** for the Node services

## Run the app

```
flutter pub get
flutter run -d "iPhone 16 Pro" --dart-define=NR_IOS_TOKEN=<mobile app token>
```

The token is passed at run time and is not stored in the source. Do not commit it.

Keep the `flutter run` session open while testing. This is a debug build, so
relaunching the app from the simulator home screen after the session ends will
show an old build or fail to start. After a crash, start a new session so the
crash report is sent.

### Plugin version

`newrelic_mobile` is pinned to `1.3.0` in `pubspec.yaml`. Version 1.3.4 failed to
build with Xcode 26.0 because its bundled iOS framework could not be parsed. Try
the latest version again after updating Xcode.

## Run the services

Start the back end first, each in its own terminal:

```
cd ../flutter-back-end  && NEW_RELIC_LICENSE_KEY=<license key> npm start
cd ../flutter-front-end && NEW_RELIC_LICENSE_KEY=<license key> npm start
```

For an EU account also set `NEW_RELIC_HOST=collector.eu01.nr-data.net`.

- About 25% of back-end calls fail (change with `ERROR_RATE`, for example `ERROR_RATE=0.5`).
- Both services tag traces with `enduser.id` and `username` from the `x-username` header.
- The front end returns 502 when the back end fails.

The iOS app reaches the services at `http://localhost:3001`. `Info.plist` allows
local HTTP with `NSAllowsLocalNetworking`.

## Troubleshooting

**`HandshakeException: CERTIFICATE_VERIFY_FAILED` on the Network screen**
A TLS-inspecting proxy (for example Cloudflare Gateway/WARP) is re-signing
traffic, and the simulator does not trust its root certificate. Export the
root CA from your Mac keychain and install it in the simulator:

```
xcrun simctl keychain booted add-root-cert <root-ca>.pem
```

**A new button or screen is missing after a hot restart and relaunch**
Hot restart only updates the running session. Stop it and run `flutter run` again
for a full reinstall.

## Where to look in New Relic

- Custom events: `SELECT * FROM MobileCustomEvent SINCE 30 minutes ago` (or `DemoEvent`)
- HTTP: Mobile app > Network / HTTP requests
- Handled exceptions: Mobile app > Handled exceptions
- Crashes: Mobile app > Crash analysis
- Traces: Distributed tracing for `flutter-front-end` and `flutter-back-end`
- Logs: filter on `username=<name>`
