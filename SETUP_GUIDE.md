# 🛠️ Complete Setup Guide

## Quick Start (5 Minutes)

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Add Project"
3. Name it "Smart Glasses App"
4. Disable Google Analytics (optional for MVP)
5. Create project

### 3. Add Firebase to Your Apps

#### Android Setup
1. In Firebase Console, click "Add app" → Android icon
2. Package name: `com.smartglasses.app`
3. Download `google-services.json`
4. Place it in `android/app/`

#### iOS Setup
1. In Firebase Console, click "Add app" → iOS icon
2. Bundle ID: `com.smartglasses.app`
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/`

### 4. Enable Firebase Authentication

1. In Firebase Console → Authentication
2. Click "Get Started"
3. Enable "Email/Password" provider
4. Save

### 5. Get Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select existing
3. Enable these APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Directions API
   - Geocoding API
4. Create credentials → API Key
5. Copy the API key

### 6. Add API Key to Project

**Android**: Edit `android/app/src/main/AndroidManifest.xml`
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE"/>
```

**iOS**: Edit `ios/Runner/Info.plist`
```xml
<key>GMSApiKey</key>
<string>YOUR_API_KEY_HERE</string>
```

### 7. Run the App
```bash
# Connect a device or start an emulator
flutter devices

# Run the app
flutter run
```

---

## Detailed Setup

### Prerequisites

- **Flutter SDK**: 3.0 or higher
  ```bash
  flutter --version
  ```

- **Dart SDK**: 3.0 or higher (comes with Flutter)

- **IDE**: VS Code or Android Studio

- **Platform Tools**:
  - **For Android**: Android Studio, Android SDK
  - **For iOS**: Xcode 14+, CocoaPods

### Development Tools

#### VS Code Extensions
- Flutter
- Dart
- Error Lens
- GitLens
- Flutter BLoC (optional)

#### Android Studio Plugins
- Flutter plugin
- Dart plugin

---

## Firebase Configuration

### Step-by-Step

1. **Create Firebase Project**
   ```
   Firebase Console → Add Project → Name: "SmartGlasses"
   ```

2. **Register Apps**
   - Add Android app (package: com.smartglasses.app)
   - Add iOS app (bundle: com.smartglasses.app)

3. **Download Config Files**
   - `google-services.json` for Android
   - `GoogleService-Info.plist` for iOS

4. **Place Config Files**
   ```
   android/app/google-services.json
   ios/Runner/GoogleService-Info.plist
   ```

5. **Enable Authentication**
   - Firebase Console → Authentication → Sign-in method
   - Enable Email/Password
   - (Optional) Enable Google Sign-In

6. **Create Test User** (for development)
   - Authentication → Users → Add User
   - Email: test@smartglasses.com
   - Password: Test123!

---

## Google Maps Setup

### Enable APIs

In Google Cloud Console, enable:
1. **Maps SDK for Android**
2. **Maps SDK for iOS**
3. **Directions API** (for route calculation)
4. **Geocoding API** (for address search)
5. **Places API** (for location search)

### Restrict API Key (Production)

For security, restrict your API key:
- Application restrictions: Android apps / iOS apps
- API restrictions: Only selected APIs
- Add your app's package name / bundle ID

### Test the API Key

```bash
# Test with curl
curl "https://maps.googleapis.com/maps/api/geocode/json?address=1600+Amphitheatre+Parkway&key=YOUR_KEY"
```

---

## Platform-Specific Setup

### Android

1. **Minimum SDK Version**
   Edit `android/app/build.gradle`:
   ```gradle
   minSdkVersion 23  // Required for BLE
   targetSdkVersion 33
   compileSdkVersion 33
   ```

2. **Permissions**
   Already configured in `AndroidManifest.xml`

3. **Gradle Dependencies**
   Already configured in `build.gradle`

4. **Build and Run**
   ```bash
   flutter run -d <android-device-id>
   ```

### iOS

1. **Minimum iOS Version**
   Edit `ios/Podfile`:
   ```ruby
   platform :ios, '12.0'
   ```

2. **Permissions**
   Already configured in `Info.plist`

3. **Install Pods**
   ```bash
   cd ios
   pod install
   cd ..
   ```

4. **Signing**
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select Runner → Signing & Capabilities
   - Select your Team
   - Xcode will generate a provisioning profile

5. **Build and Run**
   ```bash
   flutter run -d <ios-device-id>
   ```

---

## Testing the Setup

### 1. Test Build
```bash
flutter doctor -v
flutter pub get
flutter analyze
flutter build apk --debug  # For Android
flutter build ios --debug  # For iOS
```

### 2. Test Firebase Connection
- Run the app
- Try to login with test user
- Check Firebase Console → Authentication → Users

### 3. Test Bluetooth
- Enable Bluetooth on your device
- Grant permissions when prompted
- Navigate to Device Connection screen
- Should see available BLE devices

### 4. Test Voice Recognition
- Grant microphone permission
- Tap voice assistant button
- Speak a command
- Should see transcription

### 5. Test GPS/Navigation
- Grant location permission
- Navigate to Navigation screen
- Enter a destination
- Should see route on map

---

## Troubleshooting

### Common Issues

#### 1. Firebase Not Working
**Error**: `firebase_core` initialization error

**Solution**:
- Verify `google-services.json` / `GoogleService-Info.plist` are in correct location
- Check package name / bundle ID matches
- Run `flutter clean` and rebuild

#### 2. Google Maps Not Showing
**Error**: Blank map or "Failed to load map"

**Solution**:
- Verify API key is correct
- Check APIs are enabled in Google Cloud Console
- Add restrictions for your app
- For iOS: Check `Info.plist` has `GMSApiKey`

#### 3. Bluetooth Not Working
**Error**: "Bluetooth not supported" or permissions denied

**Solution**:
- Android: Check minSdkVersion >= 23
- iOS: Check iOS version >= 12
- Grant all Bluetooth permissions
- On Android 12+, need BLUETOOTH_SCAN and BLUETOOTH_CONNECT

#### 4. Voice Recognition Not Working
**Error**: Speech recognition initialization failed

**Solution**:
- Grant microphone permission
- Check device has speech recognition support
- For iOS: May need to test on physical device
- Check internet connection (required for speech_to_text)

#### 5. Build Errors
**Error**: Dependency conflicts

**Solution**:
```bash
flutter clean
flutter pub get
flutter pub upgrade
```

---

## Development Workflow

### 1. Daily Development
```bash
# Start development
flutter run

# Hot reload: Press 'r' in terminal
# Hot restart: Press 'R' in terminal
# Quit: Press 'q'
```

### 2. Code Quality
```bash
# Analyze code
flutter analyze

# Format code
flutter format lib/

# Run tests
flutter test
```

### 3. Debugging
```bash
# Debug mode with logs
flutter run --verbose

# Profile mode (performance testing)
flutter run --profile

# Release mode
flutter run --release
```

### 4. Device Logs
```bash
# Android logs
adb logcat | grep flutter

# iOS logs (use Xcode console)
```

---

## Environment Variables (Optional)

For managing different environments (dev/staging/prod):

1. Create `.env` file:
```env
API_BASE_URL=https://api.smartglasses.com
GOOGLE_MAPS_API_KEY=your_key
ENVIRONMENT=development
```

2. Add to `.gitignore`:
```
.env
.env.local
.env.*.local
```

3. Use in code:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future main() async {
  await dotenv.load();
  String? apiUrl = dotenv.env['API_BASE_URL'];
}
```

---

## CI/CD Setup (Future)

### GitHub Actions (Android)
```yaml
name: Android CI
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test
      - run: flutter build apk
```

### Fastlane (iOS)
```ruby
lane :beta do
  build_app
  upload_to_testflight
end
```

---

## Production Checklist

Before releasing to App Store / Play Store:

- [ ] Update app version in `pubspec.yaml`
- [ ] Set proper app icons
- [ ] Configure splash screen
- [ ] Add privacy policy URL
- [ ] Configure deep linking
- [ ] Set up crash reporting (Firebase Crashlytics)
- [ ] Add analytics (Firebase Analytics)
- [ ] Test on multiple devices
- [ ] Test on different OS versions
- [ ] Optimize app size
- [ ] Enable ProGuard (Android)
- [ ] Configure code signing (iOS)
- [ ] Prepare store listings
- [ ] Record demo video
- [ ] Prepare screenshots

---

## Support

If you encounter issues:

1. Check [Flutter Documentation](https://flutter.dev/docs)
2. Check [Firebase Documentation](https://firebase.google.com/docs)
3. Search [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)
4. Check GitHub issues in package repositories

---

**Happy Coding! 🚀**

