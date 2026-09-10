# Frontend Local Data Mode

This Flutter app now runs in **local-only mode** and does not require the Laravel backend for normal use.

## How data works
- Appliance data is stored on the device using `SQLite` (`sqflite`).
- Dashboard metrics/charts/costs are calculated in-app.
- First launch seeds default appliances automatically.

## Run
```bash
flutter pub get
flutter run
```

## Notes
- No host/domain/API is needed for Android publishing.
- Data is per-device. If user clears app data or reinstalls, local data resets.
- Existing local JSON data is auto-migrated to SQLite on first launch after update.
- Existing backend folder is optional and no longer required by the mobile app.
- Android requests notification permission at runtime on Android 13+.
- A daily local reminder notification is scheduled (default: 20:00) after permission is granted.
- You can set today's outage minutes from the dashboard; billing adjusts automatically.
- Android hardening is enabled: backups disabled, cleartext traffic blocked, network security config enabled, and release minification/resource shrinking active.

## Android Release (Play Store)
1) Create an upload keystore:
```bash
keytool -genkeypair -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
2) Create `android/key.properties` from `android/key.properties.example`.
3) Build release bundle:
```bash
flutter build appbundle --release
```
4) Upload `build/app/outputs/bundle/release/app-release.aab` to Google Play Console.
