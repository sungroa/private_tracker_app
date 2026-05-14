# 🧭 Project Manifest: Private Tracker

## 📊 Session Data
- **Last Updated:** 2026-05-14T10:50:00+09:00
- **Session ID:** `cfa849bc-4d24-4317-9ba4-2fe681e2b34b`
- **Session Health:** NOMINAL
- **Context Budget:** ~25% (Turn 2)

## 🎯 Objectives & Constraints
- **Primary Objective:** Implement optional donation flow using Google Play Billing.
- **Constraints:** Zero tech debt, clean architecture, secure local persistence, high-fidelity UI.

## 🛠️ Validation & State
- **fast_validation_command:** `flutter analyze`
- **full_validation_command:** `flutter test`
- **Verification Token:** `Analytic validation passed with minor info lints.`

- [x] Phase 1: Environment Setup (Install dependencies)
- [x] Phase 2: Domain Layer (DonationProduct, IDonationRepository)
- [x] Phase 3: Data Layer (PlayBillingDonationRepository)
- [x] Phase 4: presentation Layer (DonationProvider, DonationSheet)
- [x] Phase 5: Verification & Polishing

- [x] Phase 1: Diagnose Sync Failure
- [ ] Phase 2: User updates Google Cloud Console with new SHA-1/Package ID
- [ ] Phase 3: Verify Sync functionality

## 🚫 Dead Ends / Blockers
- **Google Sign-In Error [28444]:** Caused by missing OAuth 2.0 Client ID for `com.sry_developer.private_tracker_app` in Google Cloud Console.

## 💡 Learnings
- **Google Sign-In [28444]**: This error code specifically indicates that the Android Client ID for the current package name/SHA-1 pair is missing or misconfigured in the Google Cloud Console.
- **Gradle Signing Report**: `adb shell pidof` can return multiple PIDs if multiple versions of the app (different package names) are installed and running. Always verify the target PID before running `logcat`.
- **SHA-1 Consistency**: When changing package names, all cloud-dependent services (Google Drive, Firebase, etc.) must be updated with the new package identifier and corresponding fingerprints.
