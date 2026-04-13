# 🧭 Project Manifest: Private Tracker

## 📊 Session Data
- **Last Updated:** 2026-04-13T06:42:00
- **Session ID:** `d4b61b00-4dfe-453b-b359-838c08941bd2`
- **Session Health:** HEALTHY
- **Context Budget:** ~70% (Turn 10+)

## 🎯 Objectives & Constraints
- **Primary Objective:** Zero Technical Debt Architectural Audit & Refactor.
- **STRICT_CONSTRAINTS:**
  1. Maintain 100% architectural separation (Domain/Data/Presentation).
  2. No serialization logic in Domain models.
  3. No framework dependencies in Domain.

## 🛠️ Validation & State
- **fast_validation_command:** `flutter analyze`
- **full_validation_command:** `flutter test --reporter expanded`
- **Best Known State:**
  - **Stability restored**: All smoke tests pass.
  - **Architecture purified**: Domain models decoupled from serialization.
  - **SRP Enforced**: EncryptedStorageService decomposed.
- **Verification Token:** Pass: `flutter test test/widget_test.dart test/presentation/provider_scope_test.dart`

## 📋 Action Plan
- [x] **Audit**: Conduct merciless architectural audit. ([Report Generated](file:///home/sungroa/.gemini/antigravity/brain/d4b61b00-4dfe-453b-b359-838c08941bd2/audit_report.md))
- [x] **Phase 1**: Fix failing smoke tests and initialization race conditions.
- [x] **Phase 2**: Purify Domain models (remove `toMap`/`fromMap`).
- [x] **Phase 3**: Optimize `restoreData` and batch DB writes.
- [x] **Phase 4**: Decompose `EncryptedStorageService` (SRP compliance).

## 🚫 Dead Ends
- **Isolate.run**: Must ensure only serializable data passes through isolate boundaries.
- **Collection Literals**: In Dart, `{ for ... MapEntry }` creates a `Set<MapEntry>`, not a `Map`. Use `Map.fromEntries` or `key: value` syntax.

## 💡 Learnings
- **Initialization Order**: Accessing providers in `initState` or early build phases via `Provider.of/context.read` can lead to race conditions if not guarded by `mounted` or deferred.
- **SRP in Data Layer**: Decomposing storage services into orchestrators (BackupOrchestrator) and low-level managers (LocalDatabaseManager) improves testability and readability.

## Next Steps
- Refactor complete. Standing by for further instructions or feature development.
