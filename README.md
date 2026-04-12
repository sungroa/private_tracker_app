# 🌸 Private Tracker

A premium, privacy-focused health and cycle tracking application built with Flutter. Designed for zero-knowledge security and a luxury aesthetic.

![Hero Shot](file:///home/sungroa/.gemini/antigravity/brain/86932ca1-504f-4dc9-8f12-7b52df67c1fb/private_tracker_hero_1775545127090.png)

## 🛡️ Privacy & Security (Zero-Knowledge)

Private Tracker is built on a "Privacy First" philosophy. No health data ever leaves your device unless you explicitly export an encrypted backup.

- **Zero-Knowledge Storage**: All health data is encrypted on-device before persistence using Hive's encrypted boxes.
- **AES-SIC & HMAC**: We use industry-standard Authenticated Encryption (AES-SIC-256 + HMAC-SHA256) to ensure both confidentiality and data integrity.
- **Biometric Locking**: Optional protection using `local_auth` ensures only you can open the app.
- **Secure Key derivation**: Encryption keys are stored in the system's Secure Enclave/KeyStore using `flutter_secure_storage`.

## 🏗️ Technical Architecture

This project follows **Clean Architecture** principles to ensure long-term maintainability and zero technical debt.

- **Domain-Driven Design**: Core business logic is encapsulated in pure Dart models and "Calculators" that have zero dependencies on external frameworks.
- **Decoupled Persistence**: Our storage layer uses a DTO (Data Transfer Object) pattern, allowing the database schema to evolve without breaking business logic.
- **Granular State Management**: Built with `Provider`, utilizing selective rebuilds (`Selector`, `Consumer2`) to achieve 60FPS calendar performance even with years of data.
- **Automated Verification**: A rigorous suite of 89+ tests covers 100% of domain logic and critical UI flows.

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
