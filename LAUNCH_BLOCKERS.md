# FoodOder Release Gate

This repository has a CI build gate that runs `flutter pub get`, formats Dart source,
`flutter analyze`, `flutter test`, and produces a release APK + AAB.

The GitHub CI build uses a temporary CI signing key only to verify that Android release
compilation works. That key is **not** a production Play Store signing key.

Before a public production launch, complete these items:

1. Configure a restricted `GOOGLE_MAPS_API_KEY` GitHub secret and enable the required Maps APIs.
2. Configure Google Maps/Directions restrictions and verify maps on a physical device.
3. Use Google Play App Signing with a controlled upload key for the Play Store release.
4. Register Firebase App Check and verify Play Integrity on the production package.
5. Enable and verify Crashlytics on the production Firebase project.
6. Deploy and test `firestore.rules`, `storage.rules`, indexes, and Cloud Functions.
7. Complete Firebase Emulator security tests for customer, home-chef/vendor, rider, and admin roles.
8. Complete real-device tests for login, location, notifications, cart, COD order flow, cancellation,
   rider tracking, and app upgrade/recovery.
9. Keep online card/JazzCash/Easypaisa payments disabled until merchant credentials,
   server-side verification, and webhook/signature handling are fully configured and tested.

The Android build can succeed without a Maps secret, but Google Maps features require a valid,
restricted production key at runtime.
