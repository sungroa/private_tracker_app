# Development Guide

This document outlines the architectural patterns, development workflows, and standards for the Private Tracker App.

## Architecture

The app follows a clean, decoupled architecture:

- **Domain Layer**: Contains plain Dart models and pure logic (e.g., `CycleCalculator`). It has zero dependencies on persistence or UI frameworks.
- **Data Layer**: Implements persistence using Hive. Services (like `EncryptedStorageService`) manage the bridge between Hive DTOs and Domain Models.
- **Presentation Layer**: Built with Flutter and Provider for state management. Uses a "Glassmorphism" design system defined in `AppTheme`.

## Storage Architecture

We use a layered storage approach for security and reliability:

1.  **SecureKeyStorage**: Uses `flutter_secure_storage` for storing encryption keys and sensitive preferences.
2.  **LocalDatabaseManager**: Orchestrates Hive box lifecycles and provides a Future-based initialization guard to prevent race conditions.
3.  **DataSources**: Repositories interact with specific DataSources (e.g., `CycleDataSource`) which handle the Hive operations.

## Testing

Stability is a priority. All major logic and UI flows must have tests.

- **Unit Tests**: Found in `test/domain/`. Focus on logic and model transformations.
- **Widget Tests**: Found in `test/presentation/`. Verify UI components and Provider integrations.
- **Mocking**: Use `mocktail` for dependency isolation.

### Running Tests
```bash
flutter test
```

## Security

- **Encryption**: All personal health data is stored in encrypted Hive boxes.
- **Partner Sharing**: Uses AES-CTR + HMAC-SHA256 authenticated encryption. Keys are shared via secure deep links.
- **Biometrics**: Integrated via `local_auth` and managed by `AuthService`.

## Build System

The project is configured for Android 12+ (SDK 31+). Ensure all activities and services in `AndroidManifest.xml` have `android:exported` explicitly set.

### Release Build
```bash
flutter build apk --release
```
