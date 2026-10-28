# flutter-demo-app

A demo of New Relic monitoring for a Flutter iOS app, with two Node services to
show distributed tracing end to end.

```
Flutter app  ->  flutter-front-end (:3001)  ->  flutter-back-end (:3002)
```

| Folder | What it is |
|---|---|
| [nr_flutter_demo](nr_flutter_demo) | Flutter iOS app: custom events, network requests, distributed tracing, handled exceptions, crashes, breadcrumbs and logs |
| [flutter-front-end](flutter-front-end) | Node/Express service called by the app; calls the back end |
| [flutter-back-end](flutter-back-end) | Node/Express service that randomly returns errors |

See [nr_flutter_demo/README.md](nr_flutter_demo/README.md) for setup and running instructions.

## Secrets

No tokens or keys are stored in this repository. Supply them at run time:

- Mobile app token: `flutter run --dart-define=NR_IOS_TOKEN=<token>`
- Node license key: `NEW_RELIC_LICENSE_KEY=<key> npm start`
