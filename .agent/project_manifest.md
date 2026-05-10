# 🧭 Project Manifest: Private Tracker

## 📊 Session Data
- **Last Updated:** 2026-05-10T11:00:30Z
- **Session ID:** `3b3ddb43-ce48-4b3b-ae29-1c8d0377dee6`
- **Session Health:** NOMINAL
- **Context Budget:** ~25% — NOMINAL

## 🎯 Objectives & Constraints
- **Primary Objective:** Fix cloud sync password friction + add passphrase update flow.
- **Constraints:** Zero tech debt, mandatory testing, clean architecture.

## 🛠️ Validation & State
- **fast_validation_command:** `flutter analyze`
- **full_validation_command:** `flutter test`
- **Verification Token:** Pass: `flutter test` = All 117 tests passed. Timezone initialization fixed.

## 🐛 Confirmed Remaining Bugs
- None currently.

## 📋 Next Steps
- Validate reminders setting toggle explicitly on user device.

## 🚫 Dead Ends / Blockers
- None currently.

## 💡 Learnings
- **google_sign_in ^7.0 breaking change**: `initialize()` must be called before `runApp()`, not lazily.
- **Android Credential Manager**: `attemptLightweightAuthentication()` may show UI on Android 12+.
- **Metadata Masking**: Google Drive API may mask `appProperties`. Redundancy is required for cross-device discovery without full scopes.
- **Flutter Local Notifications permissions**: `requestNotificationsPermission()` and `requestExactAlarmsPermission()` return `null` on older Android OS versions where permissions are implicitly granted. This `null` must be explicitly handled as `true`.
- **Android 14 Exact Alarms**: `requestExactAlarmsPermission()` launches the system settings page and disrupts standard toggles. To avoid this UX disruption while maintaining exact alarm precision, the `USE_EXACT_ALARM` permission can be declared in the manifest for eligible applications (e.g., calendar or reminder apps), which grants the permission automatically without a user prompt.
- **flutter_timezone v5.0.2**: `getLocalTimezone()` now returns a `TimezoneInfo` object instead of a `String`. Access the `identifier` property to get the IANA timezone ID.
