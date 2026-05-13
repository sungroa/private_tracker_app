# Privacy Policy – Private Tracker

**Last Updated: May 13, 2026**

Your privacy is the core of this application. This document outlines our "Zero-Knowledge" approach to your personal health data, including how we handle optional cloud synchronization.

## 1. Zero Data Collection & Local Sovereignty
**By default, Private Tracker does not collect, transmit, or store any of your data on external servers.** 
- There are no user accounts.
- Your primary data stays exclusively on your physical device.
- There are no third-party analytics or tracking SDKs.

## 2. On-Device Encryption
All sensitive data (cycle logs, symptoms, notes) is protected using industry-standard authenticated encryption:
- **Algorithm**: AES-256-GCM (Galois/Counter Mode).
- **Zero-Knowledge**: Encryption keys are generated on your device and stored in secure hardware (Android Keystore / iOS Keychain). We (the developers) have no access to your keys or your data.
- **Pre-Transmission Encryption**: If you enable Cloud Sync, your data is encrypted **on your device** before it is transmitted to your cloud provider.

## 3. Optional Cloud Synchronization
You may optionally enable Cloud Sync to back up your data to your personal **Google Drive** or private cloud storage.
- **Hidden Storage**: The app uses a hidden "App Data Folder" on your Google Drive. This storage is isolated to the app and is not visible in your regular Google Drive file list.
- **Ownership**: You retain full ownership and control of your cloud backups. We cannot access, read, or modify these files.
- **Passphrase Recovery**: If you enable cloud sync, you can set a recovery passphrase. This passphrase is used to derive a secondary encryption key that allows you to recover your data on a new device. We never see or store this passphrase.

## 4. Biometric Protection
You may optionally enable Biometric Lock (FaceID, Fingerprint, or Device Passcode). When enabled, your device's secure hardware must verify your identity before the application will decrypt and display your data.

## 5. Your Control
- **Data Deletion**: You can delete all your data at any time by uninstalling the app or clearing the app storage. If Cloud Sync is enabled, you can use the "Wipe Cloud Data" feature to purge all backups from your personal cloud storage.
- **Backups**: If you choose to manually export your data, it is your responsibility to store those files securely.

## 6. Third-Party Services
This app does not integrate with any third-party services except for the optional cloud storage providers (e.g., Google) that you explicitly authorize. There are no advertisements.

---

**Privacy is not a feature; it is a right.**
Thank you for trusting Private Tracker.
