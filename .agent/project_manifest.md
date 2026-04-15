# 🧭 Project Manifest: Private Tracker

## 📊 Session Data
- **Last Updated:** 2026-04-14T22:22:30
- **Session ID:** `996d8062-f8d8-4669-bf23-422bb88e6d5b`
- **Session Health:** NOMINAL
- **Context Budget:** ~60% (Turn 15)

## 🎯 Objectives & Constraints
- **Primary Objective:** Zero Technical Debt Refactor (Comprehensive Audit Follow-up).
- **STRICT_CONSTRAINTS:**
  1. Maintain 100% architectural separation (Domain/Data/Presentation).
  2. All repository methods MUST be asynchronous (`Future`).
  3. No heavy computation on the UI thread (Isolates for Trends).
  4. Privacy-First Logging (No PII leakage in release).

## 🛠️ Validation & State
- **fast_validation_command:** `flutter analyze`
- **full_validation_command:** `flutter test --reporter expanded`
- **Best Known State:**
  - **Clean Audit**: Comprehensive audit complete. Implementation plan created.
- **Verification Token:** Pass: `flutter analyze`

## 📋 Action Plan
- [x] **Audit**: Conduct merciless architectural audit.
- [x] **Regression Fix**: Restore legacy data compatibility (updatedAt).
- [ ] **Infrastructure**: Refactor HiveRegistry and SecurityLogger.
- [ ] **Data Layer**: Migrate Repositories to Async.
- [ ] **Domain Layer**: Clean up Models and Use Cases.
- [ ] **Presentation**: Implement AppInitializer and Optimize Provider.
- [ ] **Verification**: 100% Test Coverage validation.

## 🚫 Dead Ends
- **Sync Repository Methods**: Avoid returning `List<T>` directly from repositories; always wrap in `Future`.

## 💡 Learnings
- **Isolate.run**: Ideal for offloading `TrendsCalculator` from use cases without complex messaging.

## Next Steps
- User to test the release build for Notification fix.
- User to provide `logcat` output for the Sync Error diagnostics.
- Triage sync failure based on logs.
