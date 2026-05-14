# 🌸 Private Tracker

A premium, privacy-focused health and cycle tracking application built with Flutter. Designed for zero-knowledge security and a luxury aesthetic.

![Hero Shot](file:///home/sungroa/.gemini/antigravity/brain/86932ca1-504f-4dc9-8f12-7b52df67c1fb/private_tracker_hero_1775545127090.png)

## ✨ Feature Highlights

- **🔒 Privacy First**: Zero-knowledge encryption. Your data never leaves your device unencrypted.
- **📈 Advanced Trends**: Isolate-powered "Cold Start to Hybrid ARIMA" statistical forecasting for period and fertility windows.
- **🔄 Secure Cloud Sync**: Multi-provider support (Google Drive / iCloud) with record-level Last-Write-Wins (LWW) conflict resolution.
- **🔔 Personalized Notifications**: Configurable reminder schedules for period predictions and fertility windows.
- **📄 Medical-Grade Export**: Comprehensive, journal-style CSV data export for easy sharing with healthcare providers.
- **💎 Premium UI**: Glassmorphic design with smooth micro-animations and low-latency calendar interactions.
- **🧪 Industrial Grade**: 100% test coverage for domain logic and high-fidelity persistence audits.

## 🏗️ Technical Architecture

This project follows **Clean Architecture** principles to ensure long-term maintainability and zero technical debt.

- **Layered Decoupling**: 
    - **Presentation**: Flutter + Provider (Selective Rebuilds).
    - **Domain**: Pure Dart models, Use Cases, and Isolate-driven Calculators.
    - **Data**: Repository pattern with Hive-backed encrypted storage and DTO mapping.
- **Thread Safety**: Heavy computations (Trends calculation, Sync parsing, LWW merge) are offloaded to background **Isolates** to maintain 60FPS UI performance.
- **Conflict Resolution**: Record-level merging using **Last-Write-Wins (LWW)** ensures consistent state across multiple devices without centralized servers.

## 🚀 Getting Started for Engineers

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Stable channel)
- [Android Studio](https://developer.android.com/studio) or [Xcode](https://developer.apple.com/xcode/)

### 2. Setup
```bash
# Clone and install dependencies
git clone <repo-url>
cd private_tracker_app
flutter pub get

# Generate Hive adapters
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Run
```bash
flutter run
```

## 🧪 Testing State
We maintain a strict "Zero Technical Debt" policy. No PR should be merged without passing all tests:
```bash
# Run all tests with expanded output
flutter test --reporter expanded
```

## 📦 Building for Production

Ensure all tests pass and Hive adapters are generated (`flutter pub run build_runner build`) before building.

### Android

#### 🔐 App Signing Setup (Release Mode)

For production builds, the app must be signed with a secure keystore.

1. **Generate Keystore**: Run the following command from the project root:
   ```bash
   keytool -genkey -v -keystore android/app/upload-keystore.jks \
           -keyalg RSA -keysize 2048 -validity 10000 \
           -alias upload
   ```

2. **Configure Credentials**: Edit `android/key.properties` and fill in the passwords you used in the step above:
   ```properties
   storePassword=YOUR_STORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=upload
   storeFile=../app/upload-keystore.jks
   ```

3. **Security**: Both `upload-keystore.jks` and `key.properties` are excluded from git. **Ensure you back up these files securely.** Loss of these files will prevent you from updating the app on the Play Store.

#### Build Commands

```bash
# Build APK (Release)
flutter build apk --release

# Build App Bundle (Release)
flutter build appbundle --release
```

### iOS
*Note: Requires macOS and Xcode.*
```bash
# Build IPA (Release)
flutter build ipa --release
```

### Web
```bash
# Build Web (Release)
flutter build web --release
```

## 📘 Further Reading
- [DEVELOPMENT.md](file:///home/sungroa/git/private_tracker_app/DEVELOPMENT.md): Detailed guide on architecture, security protocols, and coding standards.
