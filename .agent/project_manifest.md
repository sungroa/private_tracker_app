# Project Manifest: Private Tracker App

- **Session ID:** 4b7ed6bc-9ef0-42b2-8341-40463e7885c9
- **Last Updated:** 2026-04-05T23:00:00Z
- **Session Health:** NOMINAL
- **Project Root:** /home/sungroa/git/private_tracker_app
- **STRICT_CONSTRAINTS:**
    - Privacy-First: No data sent to any server. Local only.
    - Zero Tech Debt: Follow Principal Engineer standards. Fix root causes.
    - Premium Aesthetics: High-fidelity (Glassmorphic) UI required.
    - Native Approach: Flutter implementation.
    - Testing: No feature is complete without passing tests.
- [x] Phase 4: Verification
    - [x] Write unit test for `CycleProvider` prediction shift.
    - [x] Run `flutter test`.
- **Verification Token:** PASSED (CycleProvider prediction shift test)
- **Context Budget:** ~30% (Turn 1)

## Progress Tracking

### [ ] Feature: Extend Symptom Log Edit Capability
- [ ] Rename repository methods to `updateSymptomLog` / `deleteSymptomLog`
- [ ] Rename provider methods to `addSymptomLog` / `updateSymptomLog` / `deleteSymptomLog`
- [ ] Update `SymptomLoggingSheet` implementation
- [ ] Add regression tests for BBT editing

### [x] Recent Milestones
- [x] Feature: Automatic cycle and fertility prediction updates in `CycleProvider`.
- [x] Refactor: Consolidated medical-grade logic (IQR, weighted avg) in `TrendsCalculator`.
- [x] UI: High-fidelity prediction markers in `CalendarGrid` and `CalendarDayCell`.
- [x] Unit Testing: Added regression test for prediction shift on past data update.

### Active Work
- Planning: Symptom Log Edit Extension

### Next Steps
1. **Approval**: Wait for user approval on `implementation_plan.md`.
2. **Execution**: Execute the renames and UI updates.
3. **Verification**: Run comprehensive widget tests.



## Handoff Payload

### Completed This Session
- Research on `CycleLog` model, `CycleProvider`, and `CycleLoggingSheet`.
- Created `implementation_plan.md` for refactoring cycle logging.

### In-Flight Work
- Refactor Cycle Logging: Analysis of Hive impact and naming consistency.

### Blockers / Dead Ends
- None currently.

### Critical Files
- `lib/domain/models/cycle_log.dart`
- `lib/presentation/sheets/cycle_logging_sheet.dart`
- `lib/presentation/providers/cycle_provider.dart`
- `lib/domain/repositories/cycle_log_repository.dart`
- `lib/data/storage/encrypted_storage_service.dart`

## Dead Ends & Lessons
- **Provider Scope**: Pushed routes in a `Navigator` do not inherit providers from the `home` widget's tree if the `Navigator` is an ancestor of that widget. Lifing providers to the root is the robust fix.
