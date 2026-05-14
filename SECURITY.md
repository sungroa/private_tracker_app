# Security & Privacy Protocol

Private Tracker is designed with a **Privacy-First** architecture. This document outlines the technical measures taken to ensure that user health data remains private and secure.

## 🛡️ Zero-Knowledge Architecture

We follow a "Zero-Knowledge" model. The application does not have a central server that stores user data. All data is stored locally on the device and is only synchronized via user-controlled cloud providers in an encrypted state.

### 1. Encryption at Rest (Local Storage)

- **Engine**: We use **Hive** (a high-performance key-value store) with native AES-256-SIC encryption.
- **Scope**: All sensitive boxes (`cycle_logs`, `symptom_logs`, `custom_tags`) are encrypted.
- **Disk Format**: Data is serialized to binary DTOs and encrypted before being written to the filesystem.

### 2. Key Management (Master Key)

- **Generation**: A unique 256-bit cryptographically strong master key is generated during the first application launch.
- **Storage**: The master key is stored in the platform's **Secure Storage**:
    - **iOS**: Apple KeyChain.
    - **Android**: Android Keystore (with hardware-backed protection where available).
- **Access Control**: The key is only accessible by the application and is never logged or exposed to the UI layer.

### 3. Authenticated Backups & Cloud Sync

When synchronizing data to Google Drive or iCloud, we use an additional layer of protection:

- **Algorithm**: AES-256-GCM (providing both confidentiality and authenticity).
- **Derivation**: Backup encryption keys are derived from a user-provided password using **PBKDF2 with HMAC-SHA256** (10,000+ iterations).
- **Integrity**: Every cloud payload includes a SHA-256 checksum to prevent data corruption or tampering during transfer.

## 👁️ Privacy-First Engineering

### No Tracking/Analytics
Private Tracker contains **zero** third-party analytics (no Firebase Analytics, no Mixpanel, etc.). We do not track user behavior or app usage patterns.

### PII Leakage Prevention
Our logging strategy is designed to prevent Personally Identifiable Information (PII) from entering system logs:
- **Filtered Logs**: Production logs never include raw health data or encryption keys.
- **Diagnostic Tags**: We use `dart:developer` logging with the `PrivacyTracker.Prediction` tag for forecasting auditability. These logs contain only statistical metadata and timing information, never user content.
- **Event-Only Logging**: We only log structural events (e.g., "Backup Successfully Restored") rather than content events.

### Biometric Lock
Users can enable optional Biometric Authentication (FaceID/TouchID/Fingerprint) to lock the application interface. This utilizes the `local_auth` Flutter package and interacts directly with system-level security prompts.

## 🩹 Vulnerability Disclosure
If you discover a security vulnerability, please contact the development team directly via the project's repository issues or private security email (if provided).
