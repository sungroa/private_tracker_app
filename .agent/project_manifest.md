# 🧭 Project Manifest: Private Tracker

## 📊 Session Data
- **Last Updated:** 2026-05-14T11:20:00+09:00
- **Session ID:** `d153c0ed-d611-4293-aa2e-187327b0df0b`
- **Session Health:** NOMINAL
- **Context Budget:** ~35% (Turn 1)

## 🎯 Objectives & Constraints
- **Primary Objective:** Debug sync errors following package name change.
- **Constraints:** Zero tech debt, maintain local data integrity.

## 🛠️ Validation & State
- **fast_validation_command:** `flutter analyze`
- **full_validation_command:** `flutter test`
- **Verification Token:** `Analytic validation passed with minor lints.`

- [x] Phase 1: Diagnose Sync Failure
- [ ] Phase 2: User updates Google Cloud Console with new SHA-1/Package ID
- [ ] Phase 3: Verify Sync functionality

## 🚫 Dead Ends / Blockers
- **Google Sign-In Error [28444]:** Caused by missing OAuth 2.0 Client ID for `com.sry_developer.private_tracker_app` in Google Cloud Console.

## 💡 Learnings
- **Google Sign-In [28444]**: This error code specifically indicates that the Android Client ID for the current package name/SHA-1 pair is missing or misconfigured in the Google Cloud Console.
- **Gradle Signing Report**: `adb shell pidof` can return multiple PIDs if multiple versions of the app (different package names) are installed and running. Always verify the target PID before running `logcat`.
- **SHA-1 Consistency**: When changing package names, all cloud-dependent services (Google Drive, Firebase, etc.) must be updated with the new package identifier and corresponding fingerprints.
