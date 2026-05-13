# 🧭 Project Manifest: Private Tracker

## 📊 Session Data
- **Last Updated:** 2026-05-13T15:48:40+09:00
- **Session ID:** `6e1cf4f2-c532-4ac5-9b52-e51c235d7cb0`
- **Session Health:** NOMINAL
- **Context Budget:** ~45% (Turn 2)

## 🎯 Objectives & Constraints
- **Primary Objective:** Fix symptom duplication in daily log logging.
- **Constraints:** Zero tech debt, mandatory testing, clean architecture.

## 🛠️ Validation & State
- **fast_validation_command:** `flutter analyze`
- **full_validation_command:** `flutter test`
- **Verification Token:** `No issues found! (Lints fixed in tests)`

- [x] Identify root cause of symptom duplication (random IDs in seeding).
- [x] Transition default tags to deterministic UUID v5 IDs in `DataSeedingService`.
- [x] Implement one-time cleanup/migration for existing duplicate default tags.
- [x] Update `AddTagUseCase` to prevent duplicate tag names.
- [x] Add safety deduplication in `TagProvider.refresh()`.
- [x] Verify fix with unit tests.


## 🚫 Dead Ends / Blockers
- None currently.

## 💡 Learnings
- **google_sign_in ^7.0 breaking change**: `initialize()` must be called before `runApp()`, not lazily.
- **Android Credential Manager**: `attemptLightweightAuthentication()` may show UI on Android 12+.
- **Metadata Masking**: Google Drive API may mask `appProperties`. Redundancy is required for cross-device discovery without full scopes.
- **Flutter Local Notifications permissions**: `requestNotificationsPermission()` and `requestExactAlarmsPermission()` return `null` on older Android OS versions where permissions are implicitly granted. This `null` must be explicitly handled as `true`.
- **Android 14 Exact Alarms**: `requestExactAlarmsPermission()` launches the system settings page and disrupts standard toggles. To avoid this UX disruption while maintaining exact alarm precision, the `USE_EXACT_ALARM` permission can be declared in the manifest for eligible applications (e.g., calendar or reminder apps), which grants the permission automatically without a user prompt.
- **Deterministic IDs for Default Data**: When seeding default records that may be synced across devices, always use deterministic IDs (e.g., UUID v5 based on name) to prevent duplication during merge operations.
- **Isolate-Safe Deduplication**: When merging data in background isolates, ID-based deduplication is standard, but name-based deduplication should be enforced at the domain/provider layer for user-facing categories.
