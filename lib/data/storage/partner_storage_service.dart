import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/shared_phase_data.dart';

class PartnerStorageService {
  static const String partnerBoxName = 'partner_data';
  static const String dataKey = 'shared_phase_data';
  static const String encryptionKeyKey = 'partner_encryption_key';

  static Future<void> initialize() async {
    await Hive.openBox(partnerBoxName);
  }

  static Future<void> savePartnerData(SharedPhaseData data, String? encryptionKey) async {
    final box = Hive.box(partnerBoxName);
    await box.put(dataKey, data.toJson());
    if (encryptionKey != null) {
      await box.put(encryptionKeyKey, encryptionKey);
    }
  }

  static SharedPhaseData? getPartnerData() {
    final box = Hive.box(partnerBoxName);
    final json = box.get(dataKey);
    if (json == null) return null;
    return SharedPhaseData.fromJson(json);
  }

  static String? getEncryptionKey() {
    final box = Hive.box(partnerBoxName);
    return box.get(encryptionKeyKey);
  }

  static Future<void> clearPartnerData() async {
    final box = Hive.box(partnerBoxName);
    await box.clear();
  }

  static bool hasPartnerData() {
    final box = Hive.box(partnerBoxName);
    return box.containsKey(dataKey);
  }
}
