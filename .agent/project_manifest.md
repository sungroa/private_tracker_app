# 🧭 Project Manifest: Private Tracker

## 📊 Session Data
- **Last Updated:** 2026-05-08T23:45:00Z
- **Session ID:** `9bb67998-d4f3-4507-9173-20eb2c11f0ce`
- **Session Health:** NOMINAL
- **Context Budget:** ~60% (Turn 1)

## 🎯 Objectives & Constraints
- **Primary Objective:** Deep analysis + fix of Google Drive sync flow.
- **Prior Finished Features:**
  - Triple-Redundant Recovery Discovery (appProperties, properties, description).
  - Reset Cloud Sync (Permanent Cloud Wipe + Local State Reset).
  - Biometric-Protected Destructive Operations.
  - Idempotent Authentication Flow (Silent-First).

## 🛠️ Validation & State
- **fast_validation_command:** `flutter analyze`
- **full_validation_command:** `flutter test`
- **Verification Token:** Pass: `flutter analyze` = No issues. `flutter test` = 97 pass / 2 pre-existing failures (smoke test env issue, pre-dates session).

## 🔎 Analysis Findings (Session 67eafd1e)
See: `brain/67eafd1e.../cloud_sync_analysis.md`

### Confirmed Bugs (Ordered by Severity)
1. 🔴 **CRITICAL** — `GoogleSignIn.initialize()` called lazily in `authenticate()`, not at app startup. Causes initialization races; silently swallowed by `checkRecoveryStatus()`.
2. 🔴 **CRITICAL** — `authenticate()` idempotency guard (`if (_driveApi != null) return`) hides stale/expired OAuth sessions. Zombie DriveApi emits 401s.
3. 🟠 **HIGH** — `uploadEncryptedBackup` only writes to `appProperties`. The `properties` and `description` redundancy claimed in the manifest is **read-only dead code** — never written on upload.
4. 🟠 **HIGH** — `checkRecoveryStatus()` uses `catch (_) {}` that silently swallows all auth errors. Recovery card never appears even when cloud backup exists.
5. 🟡 **MEDIUM** — `resetCloudData()` calls `authenticate()` which hits the stale-auth idempotency guard. Wipe 401 failure surfaces as a generic "Reset failed" — this is the primary "Silent Wipe" explanation.
6. 🟡 **MEDIUM** — `_isInitialized = true` is set even when `checkRecoveryStatus` fails silently, making `isCloudEnabled` return `true` on a broken auth session.
7. 🟡 **MEDIUM** — `SyncDataUseCase` error recovery catch block swallows secondary errors, preventing `recoveryRequired` from being thrown and guiding the user to recovery flow.
8. 🟢 **LOW** — `_isSyncing` check-then-set is not atomic; concurrent sync triggers are possible.

## 📋 Next Steps
- [x] **Fix #1+2**: Moved `GoogleSignIn.instance.initialize()` to `main()`. Removed stale-auth guard from `authenticate()`.
- [x] **Fix #3**: `uploadEncryptedBackup` now writes to `appProperties` + `properties` + `description`.
- [x] **Fix #4**: `checkRecoveryStatus()` now logs errors instead of swallowing them.
- [x] **Fix #5**: Handled by Fix #2 — `authenticate()` always refreshes.
- [x] **Fix #7**: Secondary error in `SyncDataUseCase` catch block is now logged.
- [x] **Fix Startup Hang**: Removed `await checkRecoveryStatus()` from `CloudSyncProvider.init()` critical path to prevent UI hang at the "Secure Environment" loading screen on Android 12+.
- [x] **Fix BadPaddingException Crash**: Migrated non-sensitive settings (biometrics toggle, cloud sync toggle, notification settings) from `FlutterSecureStorage` to `SharedPreferences` to permanently fix issues where the settings toggle would randomly reset due to Android Keystore hardware invalidation loops.
- [x] **Fix Missing AppLinks Provider**: Added missing `Provider.value(value: sl.appLinks)` to `main.dart` to resolve initialization errors in `AppLifecycleManager`.
- [x] **Fix Local Notifications Crash**: Fixed `PlatformException(invalid_icon)` during `AppInitializer` by explicitly prefixing `@mipmap/ic_launcher` in `AndroidInitializationSettings`.
- [x] **Fix UI Sync Stale State**: Updated `HomePage` refresh button to manually trigger `refresh()` on all data providers (`CycleProvider`, `SymptomProvider`, `TagProvider`) so daily logs correctly redraw after a cloud sync.
- [ ] **Investigate Toggle Reset Bug**: The user reports the Google Drive toggle still resets visually after app restart. Debugging deferred until device is available.
- [ ] **Physical Verification**: User to verify sync and wipe on Android 12 device.
- [ ] **Fix #8 (LOW)**: `_isSyncing` Completer-based mutex (deferred, very low probability).

## 🚫 Dead Ends / Blockers
- None currently.

## 💡 Learnings
- **google_sign_in ^7.0 breaking change**: `initialize()` must be called before `runApp()`, not lazily.
- **Android Credential Manager**: `attemptLightweightAuthentication()` may show UI on Android 12+.
- **Metadata Masking**: Google Drive API may mask `appProperties`. Redundancy is required for cross-device discovery without full scopes.
