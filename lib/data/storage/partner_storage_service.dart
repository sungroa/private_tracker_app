import '../../domain/models/shared_phase_data.dart';
import 'local_database_manager.dart';

class PartnerStorageService {
  final LocalDatabaseManager _dbManager;
  
  PartnerStorageService(this._dbManager);

  static const String partnerBoxName = LocalDatabaseManager.partnerDataBox;
  static const String dataKey = 'shared_phase_data';
  static const String encryptionKeyKey = 'partner_encryption_key';

  Future<void> savePartnerData(SharedPhaseData data, String? encryptionKey) async {
    final box = _dbManager.getBox(partnerBoxName);
    await box.put(dataKey, data.toJson());
    if (encryptionKey != null) {
      await box.put(encryptionKeyKey, encryptionKey);
    }
  }

  SharedPhaseData? getPartnerData() {
    final box = _dbManager.getBox(partnerBoxName);
    final json = box.get(dataKey);
    if (json == null) return null;
    return SharedPhaseData.fromJson(json as String);
  }

  String? getEncryptionKey() {
    final box = _dbManager.getBox(partnerBoxName);
    return box.get(encryptionKeyKey);
  }

  Future<void> clearPartnerData() async {
    final box = _dbManager.getBox(partnerBoxName);
    await box.clear();
  }

  bool hasPartnerData() {
    final box = _dbManager.getBox(partnerBoxName);
    return box.containsKey(dataKey);
  }
}
