# FoodOder Production Checklist

## Required before first APK
1. Install Flutter stable and Android Studio.
2. From this project directory run `flutter create .` to generate platform folders if they are missing.
3. Register the Android app in your own Firebase project and download a matching `google-services.json` into `android/app/`.
4. Enable Firebase Authentication -> Email/Password.
5. Create Firestore and deploy:
   - `firebase deploy --only firestore:rules,firestore:indexes`
6. Create the first admin account manually in Firestore by changing that user's role to `admin` from a trusted/admin environment. Normal users cannot promote themselves.
7. Create vendor and rider accounts, then set their roles to `vendor` / `rider` from the trusted/admin environment.
8. Create/restrict a Google Maps key for Maps SDK for Android and the Directions API. Put it in the Android manifest or inject it during your Android build. Do not commit unrestricted keys.
9. For iOS, add the Maps key to the iOS AppDelegate/Info.plist and location usage descriptions.
10. Test on a physical Android device for GPS, notifications and map behavior.

## Payment
Cash on Delivery is implemented. Online payment (JazzCash, Easypaisa, card, etc.) is not considered production-ready until a provider account, server-side verification endpoint, webhook handling and reconciliation are configured. Never put merchant secrets in Flutter code.

## Push notifications
The current app has Firestore in-app notifications. True background push notifications require Firebase Cloud Messaging plus a trusted server/Cloud Function to send messages. Do not use a client-only implementation for payment or privileged notifications.

## Role safety
Customer signup always creates a `customer` role. Roles must be assigned by an administrator/trusted backend. Do not allow clients to edit their own role.

## QA checklist
- [ ] Sign up / login / logout
- [ ] Password reset
- [ ] Customer sees only own orders
- [ ] Vendor sees only own vendor orders/products
- [ ] Vendor status flow: placed -> accepted -> preparing -> ready
- [ ] Rider can claim ready order and progress: picked_up -> on_the_way -> delivered
- [ ] Customer can cancel only while order is placed
- [ ] Rider GPS updates in Firestore
- [ ] Customer sees rider on map
- [ ] Route/ETA works with a restricted Directions API key
- [ ] Delivered order can be reviewed once
- [ ] Admin can inspect users/orders
- [ ] Firestore rules are deployed
- [ ] No unrestricted API keys or service-account files are committed

## v14 Pre-launch hardening
- Run `flutter analyze` and `flutter test` locally and in CI.
- Deploy and validate Firestore/Storage rules with the Firebase Emulator Suite before production.
- Notification documents are now server/admin-created; client roles cannot forge arbitrary push/in-app notifications.
- Payment records and refund requests are constrained to the authenticated customer's real order and order total.
- Review edits cannot change order/customer/vendor identity or rating outside 1-5.
- Do not commit Google Maps keys, payment secrets, service-account JSON, or FCM server credentials.
- Test duplicate taps, airplane mode, app restart, interrupted checkout, rejected location permission, and repeated payment callbacks on real Android devices.


## v15 security/reliability
- [ ] Register Android/iOS apps in Firebase App Check and verify legitimate requests.
- [ ] Enable Crashlytics and confirm a test crash is visible in Firebase Console.
- [ ] Keep App Check in monitor mode during initial rollout; enforce after verification.
- [ ] Confirm no debug App Check token or payment secret is committed.
- [ ] Test app startup on a real Android device with App Check configured.
