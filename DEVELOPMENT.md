# Engineering & Development Guide

This guide provides a deep dive into the technical standards and architectural patterns of the Private Tracker App.

## 🏛 Clean Architecture Standards

We adhere to a strict 3-tier Clean Architecture to ensure business logic is isolated, testable, and reusable.

### 1. Domain Layer (`lib/domain/`)
- **Content**: Pure Dart models, Repository interfaces, and specialized Calculators.
- **Constraints**: **ZERO** dependencies on Flutter, Hive, or any external framework.
- **Key Files**: 
  - `models/`: Immutable business entities.
  - `calculators/`: Logic for predictions and trends analysis.

### 2. Data Layer (`lib/data/`)
- **Content**: Persistence implementations, DTOs, and External Service clients.
- **Pattern**: The **Repository Pattern** is used to abstract storage details from the domain. DataSources handle low-level Hive ops.
- **Key Files**:
  - `storage/hive_dtos.dart`: The disk-serialized schema.
  - `storage/encrypted_storage_service.dart`: The security orchestration layer.

### 3. Presentation Layer (`lib/presentation/`)
- **Content**: Flutter widgets, UI-only theme logic, and Providers.
- **State Management**: [Provider](https://pub.dev/packages/provider).
- **Standards**:
  - Use `Selector` or `Consumer` for granular rebuilds.
  - No business logic in Widgets; delegate to Providers or Domain Extensions.
  - Design tokens must be pulled from `AppTheme`.

---

## 🛡 Security & Encryption Protocols

Private Tracker uses a Multi-Layered Encryption approach:

1.  **Encryption at Rest**:
    - Algorithm: AES-256-SIC (Streaming mode for efficiency).
    - Provider: `hive_flutter` with encrypted boxes.
2.  **Key Management**:
    - The 256-bit AES master key is generated on first launch.
    - Stored in **Platform Secure Storage** (KeyChain on iOS, KeyStore on Android).
3.  **Authenticated Backup**:
    - Password-based key derivation using PBKDF2 (10,000+ iterations).
    - Encrypted payload with HMAC-SHA256 integrity verification.

---

## 🧪 Testing Protocol

A feature is considered **Incomplete** if it lacks associated tests.

- **Unit Tests (`test/domain/`)**: Test all calculators and model transformations.
- **Data Tests (`test/data/`)**: verify storage serialization and encryption/backup flows.
- **UI Tests (`test/presentation/`)**: Smoke tests for navigation and critical logging flows.

### Verification Command
```bash
# Verify the entire codebase in one go
flutter test --reporter expanded
```

---

## 📜 Coding Standards & Linting

1.  **Immutability**: Maintain `@immutable` domain models. Use `copyWith` for state transitions.
2.  **Documentation**: All public APIs in `domain` and `data` MUST have `///` docstrings.
3.  **Haptics**: Standardized tactile feedback must be used for all primary user actions:
    - `HapticFeedback.lightImpact()`: Navigation/Selecting.
    - `HapticFeedback.mediumImpact()`: Saving/Logging.
    - `HapticFeedback.heavyImpact()`: Deleting/Critical actions.

---

## 🛠 Build & Environment

- **Flutter**: 3.x+ (Stable)
- **Min SDK**: Android 21 / iOS 12.0
- **Android 12+ Compliance**: All intent-filters must have `android:exported` set.
