# Development Setup Guide

This guide will help you set up your development environment for Synther Professional Holographic.

---

## Prerequisites

### 1. Flutter SDK (Required)

**Version**: Flutter 3.27.1+ with Dart 3.8.1+

**Installation**:

```bash
# macOS/Linux
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Verify installation
flutter doctor

# Install dependencies
flutter precache
```

**Windows**:
Download from: https://docs.flutter.dev/get-started/install/windows

### 2. Development Tools

#### Android Development (for Android builds)
- **Android Studio**: https://developer.android.com/studio
- **Android SDK**: Install via Android Studio
- **Android NDK**: Install via Android Studio SDK Manager

```bash
# Verify Android setup
flutter doctor --android-licenses
```

#### iOS Development (macOS only)
- **Xcode**: Install from Mac App Store
- **CocoaPods**: `sudo gem install cocoapods`

```bash
# Verify iOS setup
xcodebuild -version
pod --version
```

#### Web Development
```bash
# Enable web support
flutter config --enable-web

# Verify
flutter devices
# Should show "Chrome" or "Web Server"
```

### 3. Additional Tools

#### Git
```bash
git --version
# Should be 2.0+
```

#### Firebase CLI (for cloud features)
```bash
npm install -g firebase-tools
firebase login
```

---

## Project Setup

### 1. Clone Repository

```bash
git clone https://github.com/Domusgpt/synther-professional-holographic.git
cd synther-professional-holographic
```

### 2. Install Dependencies

```bash
# Install Flutter packages
flutter pub get

# Clean and regenerate if needed
flutter clean
flutter pub get
```

### 3. Configure Firebase (Optional)

If you want AI preset generation features:

```bash
# Initialize Firebase
firebase init

# Deploy functions
cd functions
npm install
cd ..
firebase deploy --only functions
```

### 4. Verify Setup

```bash
# Check for issues
flutter doctor -v

# Analyze code
flutter analyze

# Run tests
flutter test
```

---

## Running the Application

### Web (Recommended for Development)

```bash
flutter run -d chrome --web-port=8080
```

Or run the enhanced demo:

```bash
flutter run -d chrome --web-port=8080 lib/main_enhanced_demo.dart
```

### Android

```bash
# List available devices
flutter devices

# Run on connected device
flutter run

# Or specify device
flutter run -d <device-id>
```

### iOS (macOS only)

```bash
# Open in Xcode
open ios/Runner.xcworkspace

# Or run directly
flutter run -d ios
```

### Desktop

```bash
# macOS
flutter run -d macos

# Linux
flutter run -d linux

# Windows
flutter run -d windows
```

---

## Development Workflow

### 1. Hot Reload

While the app is running, press:
- `r` - Hot reload
- `R` - Hot restart
- `q` - Quit

### 2. Code Analysis

```bash
# Run analyzer
flutter analyze

# Fix formatting
dart format .

# Check for updates
flutter pub outdated
flutter pub upgrade
```

### 3. Building for Production

#### Web
```bash
flutter build web --release
# Output: build/web/
```

#### Android APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

#### Android App Bundle (for Google Play)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

#### iOS
```bash
flutter build ios --release
# Then use Xcode to archive and upload
```

---

## Project Structure

```
lib/
├── core/
│   └── enhanced_synth_engine.dart      # Main synthesis orchestrator
├── synthesis/
│   ├── engines/
│   │   ├── wavetable_engine.dart       # Wavetable synthesis
│   │   └── granular_engine.dart        # Granular synthesis
│   └── modulation/
│       └── modulation_matrix.dart      # Modulation system
├── visualization/
│   ├── quaternion_sensor_bridge.dart   # Device sensors
│   ├── vib34d_sdk_wrapper.dart        # Visualizer integration
├── state/
│   └── synth_app_state.dart           # App state management
├── main_enhanced_demo.dart             # Enhanced demo app
└── main_unified.dart                   # Original app

assets/
└── vib34d-integration.html             # WebGL visualizer
```

---

## Testing

### Unit Tests

```bash
# Run all tests
flutter test

# Run specific test
flutter test test/wavetable_engine_test.dart

# With coverage
flutter test --coverage
```

### Integration Tests

```bash
# Run integration tests
flutter test integration_test/
```

### Widget Tests

```bash
# Test UI components
flutter test test/widgets/
```

---

## Debugging

### VSCode

1. Install Flutter extension
2. Open project folder
3. Press F5 to start debugging

**launch.json**:
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter",
      "request": "launch",
      "type": "dart",
      "program": "lib/main_enhanced_demo.dart"
    }
  ]
}
```

### Android Studio

1. Open project
2. Select device
3. Click "Run" or "Debug"

### Chrome DevTools

```bash
# Run with DevTools
flutter run -d chrome --web-port=8080 --dart-define=FLUTTER_WEB_USE_SKIA=true
```

---

## Common Issues

### 1. Dependencies Not Found

```bash
flutter clean
flutter pub get
```

### 2. Gradle Issues (Android)

```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### 3. CocoaPods Issues (iOS)

```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
```

### 4. WebView Not Working

Ensure you have the latest webview_flutter:
```bash
flutter pub upgrade webview_flutter
```

### 5. Sensor Permissions

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSMotionUsageDescription</key>
<string>This app uses device motion for visualization</string>
```

---

## Performance Optimization

### Profile Mode

```bash
# Run in profile mode
flutter run --profile

# Build profile version
flutter build apk --profile
```

### Performance Overlay

```dart
MaterialApp(
  showPerformanceOverlay: true,
  // ...
)
```

### Memory Profiling

```bash
# Use DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

---

## Code Quality

### Linting

The project uses `analysis_options.yaml` for linting:

```bash
# Run analyzer
flutter analyze

# Fix issues
dart fix --apply
```

### Formatting

```bash
# Format all files
dart format .

# Format specific file
dart format lib/main_enhanced_demo.dart
```

---

## Continuous Integration

### GitHub Actions Example

Create `.github/workflows/flutter.yml`:

```yaml
name: Flutter CI

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.1'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
      - run: flutter build web
```

---

## Additional Resources

### Documentation
- Flutter: https://docs.flutter.dev
- Dart: https://dart.dev/guides
- WebView Flutter: https://pub.dev/packages/webview_flutter
- Sensors Plus: https://pub.dev/packages/sensors_plus

### Community
- Flutter Discord: https://discord.gg/flutter
- Stack Overflow: https://stackoverflow.com/questions/tagged/flutter

### This Project
- Architecture: See `ENHANCED_ARCHITECTURE.md`
- Refactoring Summary: See `REFACTORING_SUMMARY.md`
- API Reference: See `API_REFERENCE.md`

---

## Getting Help

If you encounter issues:

1. Check `flutter doctor -v` for setup problems
2. Review error messages carefully
3. Search GitHub issues
4. Ask in Flutter community channels

---

**Happy coding!** 🚀
