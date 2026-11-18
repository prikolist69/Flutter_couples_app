import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _keyPairId = 'pair_id';
  static const _keyUserName = 'user_name';
  static const _keyPartnerName = 'partner_name';
  static const _keyIsPartner1 = 'is_partner1';

  static Future<void> savePairData({
    required String pairId,
    required String userName,
    String? partnerName,
    bool? isPartner1,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPairId, pairId);
    await prefs.setString(_keyUserName, userName);
    if (partnerName != null) {
      await prefs.setString(_keyPartnerName, partnerName);
    }
    if (isPartner1 != null) {
      await prefs.setBool(_keyIsPartner1, isPartner1);
    }
  }

  static Future<String?> getPairId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPairId);
  }

  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName) ?? 'Я';
  }

  static Future<String> getPartnerName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPartnerName) ?? 'Половинка';
  }

  static Future<bool> isPartner1() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsPartner1) ?? true;
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Закрывает ошибку в settings_screen.dart
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
