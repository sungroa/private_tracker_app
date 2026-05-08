/// Centralized registry for all Hive-related constants.
/// 
/// This ensures "Zero Technical Debt" by eliminating magic numbers (adapter IDs) 
/// and hardcoded box names scattered across the data layer.
class HiveRegistry {
  // --- Adapter Type IDs ---
  // Note: These must not change once records are persisted locally.
  static const int cycleLogTypeId = 10;
  static const int symptomLogTypeId = 11;
  static const int customTagTypeId = 12;

  // --- Box Names ---
  static const String cycleLogBox = 'cycle_logs';
  static const String symptomLogBox = 'symptom_logs';
  static const String customTagBox = 'custom_tags';
  static const String metaBox = 'meta';
  static const String partnerDataBox = 'partner_data';

  // --- Meta Keys ---
  static const String lastLocalModifiedKey = 'last_local_modified';
  static const String lastSyncChecksumKey = 'last_sync_checksum';
  static const String recoverySaltKey = 'recovery_salt';
}
