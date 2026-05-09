# 🧭 Project Manifest: Private Tracker

## 📊 Session Data
- **Last Updated:** 2026-05-09T23:05:00Z
- **Session ID:** `1372f709-3eb4-44ec-8220-d9a063f3e82d`
- **Session Health:** NOMINAL
- **Context Budget:** ~5% — NOMINAL

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
- **Verification Token:** Pass: `flutter analyze` = No issues. Codebase cleaned of tautological docs; meaningful architectural docs added to 5 core files.

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
- [ ] **Physical Verification**: User to hot-restart build and confirm no more sign-in prompts during edits/sync.
- [ ] **Fix #8 (LOW)**: `_isSyncing` Completer-based mutex (deferred, very low probability).
- [ ] **[NEXT] Physical verification (Bug D)**: Launch app → Settings → Cloud Sync → confirm orange RECOVER CLOUD DATA card visible → enter passphrase → verify sync succeeds.
- [ ] **Documentation Cleanup**: Clean up `README.md`, `DEVELOPMENT.md`, and generate code docstrings.

## 🚫 Dead Ends / Blockers
- None currently.

## 💡 Learnings
- **google_sign_in ^7.0 breaking change**: `initialize()` must be called before `runApp()`, not lazily.
- **Android Credential Manager**: `attemptLightweightAuthentication()` may show UI on Android 12+.
- **Metadata Masking**: Google Drive API may mask `appProperties`. Redundancy is required for cross-device discovery without full scopes.
