# 🧭 Project Manifest: Private Tracker

## 📊 Session Data
- **Last Updated:** 2026-05-13T15:25:00+09:00
- **Session ID:** `bbc67404-d80f-459c-b054-6daf8b32045c`
- **Session Health:** NOMINAL
- **Context Budget:** ~15% — NOMINAL

## 🎯 Objectives & Constraints
- **Primary Objective:** Make full privacy policy available in-app without direct file references.
- **Constraints:** Zero tech debt, mandatory testing, clean architecture, no mention of `PRIVACY_POLICY.md`.

## 🛠️ Validation & State
- **fast_validation_command:** `flutter analyze`
- **full_validation_command:** `flutter test`
- **Verification Token:** `No issues found!`

## 📋 Next Steps
- [x] Obtain user approval for the implementation plan.
- [x] Create `PrivacyPolicyPage` widget.
- [x] Embed privacy policy text.
- [x] Integrate into `SecuritySummarySheet`. (Updated: Bypassed and removed summary sheet)
- [x] Add regression tests.


## 🚫 Dead Ends / Blockers
- None currently.

## 💡 Learnings
- **google_sign_in ^7.0 breaking change**: `initialize()` must be called before `runApp()`, not lazily.
- **Android Credential Manager**: `attemptLightweightAuthentication()` may show UI on Android 12+.
- **Metadata Masking**: Google Drive API may mask `appProperties`. Redundancy is required for cross-device discovery without full scopes.
- **Flutter Local Notifications permissions**: `requestNotificationsPermission()` and `requestExactAlarmsPermission()` return `null` on older Android OS versions where permissions are implicitly granted. This `null` must be explicitly handled as `true`.
- **Android 14 Exact Alarms**: `requestExactAlarmsPermission()` launches the system settings page and disrupts standard toggles. To avoid this UX disruption while maintaining exact alarm precision, the `USE_EXACT_ALARM` permission can be declared in the manifest for eligible applications (e.g., calendar or reminder apps), which grants the permission automatically without a user prompt.
- **flutter_timezone v5.0.2**: `getLocalTimezone()` now returns a `TimezoneInfo` object instead of a `String`. Access the `identifier` property to get the IANA timezone ID.
