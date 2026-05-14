# 🧭 Project Manifest: Private Tracker

## 📊 Session Data
- **Last Updated:** 2026-05-14T09:55:00+09:00
- **Session ID:** `4b5c902b-6414-4946-8804-8d4f6628dc01`
- **Session Health:** NOMINAL
- **Context Budget:** ~30% (Turn 2)

## 🎯 Objectives & Constraints
- **Primary Objective:** Update and synchronize all project documentation with the current state of the app.
- **Constraints:** Zero tech debt, maintain architectural clarity, remove redundancy.

## 🛠️ Validation & State
- **fast_validation_command:** `flutter analyze`
- **full_validation_command:** `flutter test`
- **Verification Token:** `Analytic validation passed with minor lints.`

- [x] Phase 1: Codebase Analysis
- [x] Phase 2: Implementation Plan & User Approval
- [x] Phase 3: Implement `CycleLengthForecaster`
- [x] Phase 4: Integration & Testing
- [x] Phase 5: Final Verification

## 🚫 Dead Ends / Blockers
- None.

## 💡 Learnings
- **Lightweight ARIMA**: For very small datasets (n < 20), a grid-search MLE for ARIMA(1,1,1) is stable, fast, and removes the need for external math dependencies in Dart.
- **Median Imputation vs Dropping**: In time-series forecasting, replacing outliers with the median preserves the chronological distance between data points, which is crucial for the "Integrated" (d=1) part of ARIMA.
- **google_sign_in ^7.0 breaking change**: `initialize()` must be called before `runApp()`, not lazily.
- **Android Credential Manager**: `attemptLightweightAuthentication()` may show UI on Android 12+.
- **Metadata Masking**: Google Drive API may mask `appProperties`. Redundancy is required for cross-device discovery without full scopes.
- **Flutter Local Notifications permissions**: `requestNotificationsPermission()` and `requestExactAlarmsPermission()` return `null` on older Android OS versions where permissions are implicitly granted. This `null` must be explicitly handled as `true`.
- **Android 14 Exact Alarms**: `requestExactAlarmsPermission()` launches the system settings page and disrupts standard toggles. To avoid this UX disruption while maintaining exact alarm precision, the `USE_EXACT_ALARM` permission can be declared in the manifest for eligible applications (e.g., calendar or reminder apps), which grants the permission automatically without a user prompt.
- **Deterministic IDs for Default Data**: When seeding default records that may be synced across devices, always use deterministic IDs (e.g., UUID v5 based on name) to prevent duplication during merge operations.
- **Isolate-Safe Deduplication**: When merging data in background isolates, ID-based deduplication is standard, but name-based deduplication should be enforced at the domain/provider layer for user-facing categories.
- **Clean Architecture & Domain Logic**: Complex prediction logic should be encapsulated in specialized domain calculators (e.g., `CycleLengthForecaster`) to keep `UseCase` and `Calculator` classes focused.
- **Documentation Consolidation**: Centralizing troubleshooting guides (e.g., Release SHA-1 fixes) and legal docs (assets/docs/) reduces maintenance overhead and prevents state divergence.
- **Diagnostic Logging without PII**: Using specific tags like `PrivacyTracker.Prediction` with `dart:developer` allows for production auditability of complex algorithms while maintaining a strict zero-knowledge privacy stance.
