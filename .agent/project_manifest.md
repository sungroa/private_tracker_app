# Project Manifest: Private Tracker Refactor

## Context & Session Info
- **Session ID**: `5bc302f4-139f-4fda-8d33-a32266359197`
- **Phase**: Principal Refactor (Zero Technical Debt)
- **Current Health**: GREEN (Fully functional, tests passing)
- **Progress**: 25% (Phase 1 Complete)

## Active Work & State
- **Objective**: Execute a "Zero Technical Debt" refactor focusing on Clean Architecture, Domain Purity, and Storage Decomposition.
- **Last Milestone**: Phase 1 (Domain Purity & Hive Decoupling) COMPLETED.
    - Removed all Hive dependencies from Domain layer.
    - Implemented DTO-based storage in `lib/data/storage/hive_dtos.dart`.
    - Hardened `AppLockWrapper` initialization to solve intermittent test hangs.
    - Verified with +18 passing tests.
- **Audit Report**: [audit_report.md](file:///home/sungroa/.gemini/antigravity/brain/5bc302f4-139f-4fda-8d33-a32266359197/audit_report.md)
- **Implementation Plan**: [implementation_plan.md](file:///home/sungroa/.gemini/antigravity/brain/5bc302f4-139f-4fda-8d33-a32266359197/implementation_plan.md)
- **Task List**: [task.md](file:///home/sungroa/.gemini/antigravity/brain/5bc302f4-139f-4fda-8d33-a32266359197/task.md)

## Next Steps (Phase 2)
1.  **Decompose Storage Service**: Split `EncryptedStorageService` into specialized DataSources (Cycle, Symptom, Tag) under `lib/data/storage/data_sources/`.
2.  **Repository Refactor**: Update repositories to depend on granular DataSources.
3.  **UI Performance**: Optimize `TrendsCalculator` and `CustomCalendarGrid`.

## Technical Notes
- **Hive Type IDs**: Standardized on 10 (Cycle), 11 (Symptom), 12 (Tag) for DTOs to avoid conflict with stale adapters.
- **Initialization**: `LocalDatabaseManager` now includes diagnostic logging and explicit `timeout` to prevent environmental hangs.
- **Verification**: Run `flutter test test/domain/storage_test.dart test/presentation/sheets_test.dart test/presentation/provider_scope_test.dart test/widget_test.dart`.

## Prompt for the next agent (delete)
Role: Principal Staff Software Engineer (Clean Architecture Specialist). Project: Private Tracker App. Context: We are executing a "Zero Technical Debt" refactor. Phase 1 (Domain Purity & Hive Decoupling) is 100% complete and fully verified with +18 passing tests. The domain layer is now pure Dart. Current State:

Health: GREEN (All tests passing).
Key Files: lib/data/storage/hive_dtos.dart (DTO Layer), lib/data/storage/encrypted_storage_service.dart (Current God Service).
Manifest: 

project_manifest.md
Task List: 
task.md
Your Mission (Phase 2): Decompose the EncryptedStorageService "God Class" into specialized DataSources (CycleDataSource, SymptomDataSource, TagDataSource) under lib/data/storage/data_sources/. Update the repositories to depend on these granular sources instead of the global service. Maintain the 100% test pass rate throughout the transition.

Read principal-engineer/SKILL.md.
Review the 
Implementation Plan
 for Phase 2.
Start execution.
