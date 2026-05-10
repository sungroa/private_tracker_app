# 🧭 Project Manifest: Private Tracker

## 📊 Session Data
- **Last Updated:** 2026-05-10T10:35:00Z
- **Session ID:** `19425d98-fb5d-4d21-92d0-3edb2f393279`
- **Session Health:** NOMINAL
- **Context Budget:** ~5% — NOMINAL

## 🎯 Objectives & Constraints
- **Primary Objective:** Fix cloud sync password friction + add passphrase update flow.
- **Constraints:** Zero tech debt, mandatory testing, clean architecture.

## 🛠️ Validation & State
- **fast_validation_command:** `flutter analyze`
- **full_validation_command:** `flutter test`
- **Verification Token:** Pass: `flutter test` = All tests passed. Key rotation logic fixed. Physical verification completed.

## 🐛 Confirmed Remaining Bugs
- None currently.

## 📋 Next Steps

## 🚫 Dead Ends / Blockers
- None currently.

## 💡 Learnings
- **google_sign_in ^7.0 breaking change**: `initialize()` must be called before `runApp()`, not lazily.
- **Android Credential Manager**: `attemptLightweightAuthentication()` may show UI on Android 12+.
- **Metadata Masking**: Google Drive API may mask `appProperties`. Redundancy is required for cross-device discovery without full scopes.
