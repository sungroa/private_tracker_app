# 🧭 Project Manifest: Private Tracker

## 📊 Session Data
- **Last Updated:** 2026-05-10T22:45:00Z
- **Session ID:** `843c0057-c283-4c8d-93bd-591c51de6dc5`
- **Session Health:** NOMINAL — Bug C+D fixed; pending physical verification
- **Context Budget:** ~65% — ELEVATED

## 🎯 Objectives & Constraints
- **Primary Objective:** Fix cloud sync password friction + add passphrase update flow.
- **Prior Finished Features:**
  - Triple-Redundant Recovery Discovery (appProperties, properties, description).
  - Reset Cloud Sync (Permanent Cloud Wipe + Local State Reset).
  - Biometric-Protected Destructive Operations.
  - Idempotent Authentication Flow (Silent-First).

## 🛠️ Validation & State
- **fast_validation_command:** `flutter analyze`
- **full_validation_command:** `flutter test`
- **Verification Token:** Pass: `flutter analyze` = No issues. `flutter test` = 113 pass, 2 pre-existing. Commits: `f2764f1`, `fe7e20a`, `e5f8f0d`, `3ad9f34`, `e3c7ad0` (Bug D root cause fix).

## 🐛 Confirmed Remaining Bugs (Post-Commit e3c7ad0)
**Bug C — FIXED:** `_triggerSync()` guards in all 3 providers + `sync()` top-level early-return for `requiresRecoveryPrompt || isOrphanKey`.

**Bug D — ROOT CAUSE CONFIRMED + FIX APPLIED (commit e3c7ad0):**
- Diagnostic log revealed: `isRecoveryEnabled=true, pendingRecoverySalt=null, requiresRecoveryPrompt=false`
- `isRecoveryEnabled=true` (stale SharedPrefs) prevented card from showing even after `_pendingRecoverySalt='pending'` was set
- Drive metadata has no `recovery_salt` (uploaded pre-triple-redundant feature); SyncDataUseCase found salt in `ISyncMetadataRepository` local store, threw `recoveryRequired`
- Fix: On `recoveryRequired` catch: force `_isRecoveryEnabled=false` + fetch real salt from `PreferencesService` as fallback
- Fix: `restoreRecovery()` resolves `'pending'` sentinel via `PreferencesService.getRecoverySalt()` so passphrase entry can derive the real key
- **Next step**: Physical verification — launch app, open Settings, confirm orange RECOVER CLOUD DATA card appears

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
- [x] **Fix Startup Hang**: Removed `await checkRecoveryStatus()` from `CloudSyncProvider.init()` critical path.
- [x] **Fix BadPaddingException Crash**: Migrated non-sensitive settings to `SharedPreferences`.
- [x] **Fix Missing AppLinks Provider**: Added missing `Provider.value(value: sl.appLinks)` to `main.dart`.
- [x] **Fix Local Notifications Crash (PERMANENT)**: Root cause was R8 resource shrinker renaming `@drawable/ic_notification` in release builds. Fixed by: (1) adding `<meta-data android:name="com.dexterous.flutterlocalnotifications.default_icon" android:resource="@drawable/ic_notification"/>` to `AndroidManifest.xml`; (2) adding `res/raw/keep.xml` with `tools:keep`; (3) regenerating `ic_notification.png` as RGBA white-on-transparent. Verified: `[Notifications] Initialization complete.` ✅
- [x] **Fix UI Sync Stale State**: Updated `HomePage` refresh button to trigger all data providers.
- [x] **Fix Stale PreferencesService Test**: Rewrote `preferences_service_test.dart` to use `SharedPreferences.setMockInitialValues()` after migration from `FlutterSecureStorage`. 17/17 pass.
- [x] **Add Wipe Diagnostic Logs (WIPE-DIAG-1 through 7)**: Inserted numbered checkpoints throughout `_handleResetCloudSync`. Also added `barrierDismissible: false` to the confirmation dialog. Verified `flutter analyze` = No issues.
- [x] **Fix Silent Auth Prompt**: Refactored `authenticate()` in `GoogleDriveSyncRepository` to cache `GoogleSignInAccount` after first auth. Subsequent sync calls reuse the warm token from the cached account's `authorizationClient`, avoiding Credential Manager UI. Removed `promptIfNecessary: true` fallback (root cause of sign-in sheet on every sync/edit). Added `clearCachedAccount()` and updated `dispose()` to null the cached account. `flutter analyze` = No issues.
- [ ] **Physical Verification**: User to hot-restart build and confirm no more sign-in prompts during edits/sync.
- [ ] **Fix #8 (LOW)**: `_isSyncing` Completer-based mutex (deferred, very low probability).
- [x] **[NEW] Fix Sync-Before-Passphrase Friction**: Guard `sync()` in `toggleGoogleDrive`.
- [x] **[NEW] Add Change Passphrase**: `changePassphrase(old, new)` in provider + dialog.
- [x] **[NEW] Fix UI Lie**: Remove "CANNOT be reset" message.
- [x] **[NEW] Fix AppInitializer Race**: `init()` awaits `checkRecoveryStatus`. AppInitializer guarded.
- [x] **[NEW] Orphan Key Recovery**: `isOrphanKey` + `overwriteCloudWithLocal()` + card UI.
- [x] **[DONE] Fix data-write provider guards (Bug C)**: Added `!requiresRecoveryPrompt && !isOrphanKey` to `_triggerSync()` in all 3 providers. Commit: `e5f8f0d`.
- [x] **[DONE] Fix sync() loop (Bug C root fix)**: Added early-return guard to `sync()` itself. Commit: `3ad9f34`.
- [x] **[DONE] Add diagnostic logging**: `init()` logs all 5 state flags. `checkRecoveryStatus()` logs salt found/missing.
- [x] **[DONE] Disable SYNC NOW during recovery**: Button disabled when requiresRecoveryPrompt or isOrphanKey.
- [x] **[DONE] Fix Bug D root cause**: Force `_isRecoveryEnabled=false` on `recoveryRequired`; fetch real salt from PrefsService. `restoreRecovery()` resolves 'pending' sentinel. Commit: `e3c7ad0`.
- [ ] **[NEXT] Physical verification (Bug D)**: Launch app → Settings → Cloud Sync → confirm orange RECOVER CLOUD DATA card visible → enter passphrase → verify sync succeeds.

## 🚫 Dead Ends / Blockers
- None currently.

## 💡 Learnings
- **google_sign_in ^7.0 breaking change**: `initialize()` must be called before `runApp()`, not lazily.
- **Android Credential Manager**: `attemptLightweightAuthentication()` may show UI on Android 12+.
- **Metadata Masking**: Google Drive API may mask `appProperties`. Redundancy is required for cross-device discovery without full scopes.
