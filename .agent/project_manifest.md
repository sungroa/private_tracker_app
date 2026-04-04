# Project Manifest: Private Tracker App

- **Session ID:** 70edbf91-2dab-43ca-a81b-51417dc62ff4
- **Last Updated:** 2026-04-03T23:15:00Z
- **Session Health:** HEALTHY
- **Project Root:** /home/sungroa/git/private_tracker_app
- **STRICT_CONSTRAINTS:**
    - Privacy-First: No data sent to any server.
    - Zero Tech Debt: Follow Principal Engineer standards.
    - Premium Aesthetics: High-fidelity (Glassmorphic) UI required.
    - Native Approach: Flutter implementation.

## Primary Objective

Create a simple, privacy-oriented women's health app (menstrual tracker) with industrial-grade standards and premium aesthetics.

## Best Known State

- **validation_command:** `flutter analyze && flutter test`
- **validation_status:** `FAILING (Test Regressions)`
- **Verification Token:** AuthService & Overlay tests PASS. Some widget tests (sheets_test) need stabilization due to animation timeouts.
- **Last Drift Audit:** 2026-04-03T23:10:00Z (PASSED - Services Refactored)

## Progress Tracking

### [x] Recent Milestones
- [x] Feature: **Biometric App Security** (local_auth). Implemented FaceID/TouchID/PIN lock on app-start and resume-from-background.
- [x] Architecture: **Core Service Refactoring**. `AuthService` and `EncryptedStorageService` converted to Singleton/DI pattern to support clean unit and widget testing.
- [x] Quality: Added 8+ new tests for biometrics and storage stability.
- [x] UI: Created high-fidelity glassmorphic `AuthenticationOverlay`.
- [x] Feature: Export Data functionality to CSV and native Share Sheet via `share_plus`.
- [x] Feature: Dynamic Custom Symptoms. Migrated from hardcoded list to user-customizable Hive-backed tags.

### [/] Active Work
- [/] Quality: **Test Suite Stabilization**. Resolving `pumpAndSettle` timeouts in `sheets_test.dart` and `widget_test.dart` caused by new app-lock orchestration.
- [/] Refactor: Deferring `EncryptedStorageService` initialization until after successful biometric authentication. (Integrated in `main.dart`).

### Next Steps
1. **Improve Predictive Accuracy**: Implement IQR outlier rejection and weighted averages (50/30/20) for cycle duration calculation in `CycleCalculator`.
2. **UI Polishing**: Final visual tweaks to `TrackingCalendarPage` and micro-animations.
3. **Distribution**: Setup local build scripts and CI/CD foundations.

## Dead Ends & Lessons

- **Architecture**: Static-only services (like the old `EncryptedStorageService`) are difficult to mock in Flutter widget tests. **Lesson**: Always use a Singleton with a `test` constructor and a static `instance` setter for high-integrity testing.
- **Testing**: `Hive.initFlutter()` fails in unit tests because it relies on `path_provider` platform channels. **Lesson**: Modify initialization to accept an optional `basePath` (e.g., `Directory.systemTemp`) for isolated test environments.

## Resumption Payload

"You are a persistent agent. Resume project from manifest: `/home/sungroa/git/private_tracker_app/.agent/project_manifest.md`. Current Goal: Stabilize the test suite (resolving remaining pumpAndSettle timeouts) and then proceed to implement IQR-based cycle prediction in CycleCalculator. Refer to the recent refactor of EncryptedStorageService and AuthService singletons."
