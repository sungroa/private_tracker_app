# 🧭 Project Manifest: Private Tracker Refactor

## 📊 Session Data
- **Last Updated:** 2026-04-08T05:38:00
- **Session ID:** `8bfa25d8-b994-461d-a094-1d3d31cd901c`
- **Session Health:** STABLE
- **Context Budget:** ~30% (Turn 1)

## 🎯 Objectives & Constraints
- **Primary Objective:** Execute a "Zero Technical Debt" refactor focusing on Clean Architecture, Performance, and Premium UI.
- **STRICT_CONSTRAINTS:**
  1. No global singletons for storage (use Provider).
  2. Domain models must remain pure Dart (no Hive annotations).
  3. 100% test pass rate with zero local hangs.

## 🛠️ Validation & State
- **fast_validation_command:** `flutter test test/domain/storage_test.dart`
- **full_validation_command:** `for f in $(find test -name "*.dart"); do flutter test "$f" || exit 1; done`
- **Best Known State:**
  - **Mission Complete:** Phases 1-6 are 100% verified.
  - **Android 12 Fix:** `android:exported` explicitly set for all components in `AndroidManifest.xml`.
  - **Zero-Shift UI:** `UnifiedLoggingSheet` uses a fixed height (80% of screen) for both modes.
  - **Build Error Found:** `android/app/build.gradle` has an invalid `plugins {}` block placement (Line 24).
- **Verification Token:** Fail: `assembleRelease` failed with exit code 1 (Plugins block error).

## 📋 Action Plan

### Final Summary
- [x] **Phase 1-2 (Storage)**: Split singletons into DataSources and repositories.
- [x] **Phase 3 (Performance)**: Implement `O(1)` calendar lookups in providers.
- [x] **Phase 4 (Logic)**: Modularize calculations into specialized domain calculators.
- [x] **Phase 5 (Polish)**: Implement glassmorphism selection indicators and haptics.
- [x] **Phase 6 (Refinement)**: Fix transparency and finalize fixed-height logging sheets.
- [x] **Hotfix**: Resolve Android 12 `android:exported` build error.
- [/] **Codebase Cleanup**: Resolve analysis issues, fix test hangs, and improve documentation.
- **Context Budget:** ~35% (Turn 1)

