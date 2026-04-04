# Project Manifest: Private Tracker App

- **Session ID:** d1862318-0ed2-4784-bc95-eb24ec887652
- **Last Updated:** 2026-04-04T09:49:15Z
- **Session Health:** HEALTHY
- **Project Root:** /home/sungroa/git/private_tracker_app
- **STRICT_CONSTRAINTS:**
    - Privacy-First: No data sent to any server. Local only.
    - Zero Tech Debt: Follow Principal Engineer standards. Fix root causes.
    - Premium Aesthetics: High-fidelity (Glassmorphic) UI required.
    - Native Approach: Flutter implementation.
    - Testing: No feature is complete without passing tests.
- **Verification Token:** Principal Engineer skill confirmed accessible.
- **Context Budget:** ~5% (Turn 1)

## Progress Tracking

### [x] Recent Milestones
- [x] Feature: **Encrypted Backup & Restore**. Implemented AES-256 backup logic with PBKDF2, GZip compression, and versioning.
- [x] UI: Added Backup & Restore flows to SettingsPage.
- [x] Quality: Added unit tests for backup/restore round-trip.

### [/] Active Work
- [/] Quality: **Test Suite Stabilization**. Resolving remaining `pumpAndSettle` timeouts in `sheets_test.dart`.

### Next Steps
1. **UI Polishing**: Final visual tweaks to `TrackingCalendarPage` and micro-animations.
2. **Distribution**: Setup local build scripts and CI/CD foundations.


## Dead Ends & Lessons

- **Architecture**: Static-only services are difficult to mock. **Lesson**: Use Singletons with static setters for mocks.
- **Testing**: `DateTime` local comparisons fail when crossing DST boundaries. **Lesson**: Use `DateTime.utc` in tests.
- **Environment**: Multiple `flutter test` processes can hang. **Lesson**: Prune zombie `flutter_tester` tasks.
- **Environment**: `command_status` may report `RUNNING` even after a command (like `flutter pub add`) has effectively finished its file-system mutations. **Lesson**: Verify state via `view_file` or `list_dir` before over-waiting on long-running background tasks.
- **Artifacts**: New artifacts must be stored in the conversation-specific directory.

