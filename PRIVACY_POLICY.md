# Privacy Policy – Private Tracker

**Last Updated: April 11, 2026**

Your privacy is the core of this application. This document outlines our "Zero-Knowledge" approach to your personal health data.

## 1. Zero Data Collection
**Private Tracker does not collect, transmit, or store any of your data on external servers.** 
- There are no user accounts.
- There is no cloud synchronization.
- There are no third-party analytics or tracking SDKs.
- Your data stays exclusively on your physical device.

## 2. On-Device Encryption
All sensitive data (cycle logs, symptoms, notes) is protected using industry-standard authenticated encryption:
- **Algorithm**: AES-256-GCM (Galois/Counter Mode).
- **Key Management**: Encryption keys are generated on your device and stored in the secure hardware-backed keystore (Android Keystore / iOS Keychain).
- **Isolation**: No other application on your device can access this encrypted database.

## 3. Biometric Protection
You may optionally enable Biometric Lock (FaceID, Fingerprint, or Device Passcode). When enabled, your device's secure hardware must verify your identity before the application will decrypt and display your data.

## 4. Your Control
- **Data Deletion**: You can delete all your data at any time by uninstalling the app or clearing the app storage in your device settings.
- **Backups**: If you choose to export or backup your data, it is your responsibility to store those files securely. The app only creates encrypted backup files.

## 5. Third-Party Services
This app does not integrate with any third-party services. There are no advertisements.

---

**Privacy is not a feature; it is a right.**
Thank you for trusting Private Tracker.
