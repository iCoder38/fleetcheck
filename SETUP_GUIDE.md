# FleetCheck Flutter App — Setup & Build Guide

## Package Name: `com.fleetCheck.evs`

---

## 1. Prerequisites

```bash
flutter --version      # Should be 3.x stable
dart --version
java -version          # 11 or 17
```

---

## 2. Firebase Setup (Required before first run)

### Step A: Create Firebase project
1. Go to https://console.firebase.google.com
2. Create project: **FleetCheck**
3. Enable: **Authentication**, **Cloud Messaging**, **Analytics**, **Crashlytics**

### Step B: Add Android App
- Package name: `com.fleetCheck.evs`
- Download `google-services.json`
- Place at: `android/app/google-services.json`

### Step C: Add iOS App
- Bundle ID: `com.fleetCheck.evs`
- Download `GoogleService-Info.plist`
- Place at: `ios/Runner/GoogleService-Info.plist`

### Step D: Generate firebase_options.dart
```bash
dart pub global activate flutterfire_cli
flutterfire configure \
  --project=your-firebase-project-id \
  --platforms=android,ios
```
This generates `lib/firebase_options.dart` automatically.

---

## 3. Google Maps API Key

### Android — `android/app/src/main/AndroidManifest.xml`
Add inside `<application>`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

### iOS — `ios/Runner/AppDelegate.swift`
```swift
import GoogleMaps
GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
```

---

## 4. Install Dependencies

```bash
cd fleetcheck_app
flutter pub get
```

---

## 5. Run

```bash
# Android
flutter run --debug

# iOS (Mac only)
flutter run --debug -d iPhone

# With flavor (if configured)
flutter run --flavor dev
```

---

## 6. Build for Release

### Android APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (for Play Store)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS IPA (Mac only)
```bash
flutter build ios --release
# Then open in Xcode, Archive → Distribute
```

---

## 7. Signing (Android)

Generate keystore:
```bash
keytool -genkey -v -keystore ~/fleetcheck.keystore \
  -alias fleetcheck -keyalg RSA -keysize 2048 -validity 10000
```

Create `android/key.properties`:
```
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=fleetcheck
storeFile=/Users/YOU/fleetcheck.keystore
```

Update `android/app/build.gradle`:
```groovy
def keyProperties = new Properties()
def keyPropertiesFile = rootProject.file('key.properties')
keyProperties.load(new FileInputStream(keyPropertiesFile))

signingConfigs {
    release {
        keyAlias     keyProperties['keyAlias']
        keyPassword  keyProperties['keyPassword']
        storeFile    file(keyProperties['storeFile'])
        storePassword keyProperties['storePassword']
    }
}
```

---

## 8. API Backend

The app connects to:
```
Base URL: https://demo1.evirtualservices.com/fleetcheck/api
```

Build the PHP API endpoints in the sub-admin backend. All endpoints are defined in:
`lib/core/constants/api_constants.dart`

---

## 9. Project Structure

```
lib/
├── core/
│   ├── constants/     — Colors, strings, API URLs, checklist data
│   ├── network/       — Dio API service with auth interceptor
│   ├── services/      — Secure storage, shared prefs
│   ├── theme/         — Material 3 light + dark theme
│   └── utils/         — Date formatters, helpers
├── models/            — DriverModel, QrData, InspectionSubmission, etc.
├── repositories/      — AuthRepository, InspectionRepository
├── routes/            — GoRouter with all 18 routes
├── screens/
│   ├── auth/          — Splash, Intro (4), Login, ForgotPwd, OTP, CreatePwd
│   ├── dashboard/     — Dashboard with stats + bottom nav
│   ├── inspection/    — QR Scanner, Type, TruckInfo, Checklist, GPS, Review, Success
│   │   └── checklist/ — Handles all 6/7 sections, progress bar, validation
│   ├── profile/       — Driver profile, edit, change password
│   ├── notifications/ — All/Unread filter, 3 types, tap detail
│   ├── history/       — Filter list + full detail view
│   └── help/          — Logo, contact boxes with url_launcher
└── main.dart
```

---

## 10. Screens Implemented

| # | Screen | Status |
|---|--------|--------|
| 1 | Splash Screen | ✅ |
| 2-5 | Intro (4 slides) | ✅ |
| 6 | Login | ✅ |
| 7 | Forgot Password | ✅ |
| 8 | Verify OTP (6-digit + countdown) | ✅ |
| 9 | Create New Password | ✅ |
| 10 | Dashboard + Bottom Nav + Logout confirm | ✅ |
| 11 | QR Scanner (camera + torch + overlay) | ✅ |
| 12 | Inspection Type Select | ✅ |
| 13 | Truck Information (auto-filled) | ✅ |
| 14-19 | Pre-Trip Checklist (6 sections) | ✅ |
| 20 | Pre-Trip Overview | ✅ (via checklist flow) |
| 21 | GPS Verification (auto-capture + geocode) | ✅ |
| 22 | Inspection Review (edit + submit) | ✅ |
| 23 | Submission Success (PDF + Share) | ✅ |
| 24-30 | Post-Trip Checklist (7 sections + Defect) | ✅ |
| 31 | Driver Profile (view + edit + change pwd) | ✅ |
| 32 | Notifications (All/Unread + detail) | ✅ |
| 33 | Inspection History (filters + list) | ✅ |
| 34 | Inspection History Detail | ✅ |
| 35 | Help & Support (phone + email + website) | ✅ |
