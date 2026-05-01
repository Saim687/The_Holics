import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _panelKey = 'selected_panel';
  static const String _googlePhonePendingKey = 'google_phone_pending';
  static const String panelAdmin = 'admin';
  static const String panelMember = 'member';

  Future<void> setSelectedPanel(String panel) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_panelKey, panel);
  }

  Future<String?> getSelectedPanel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_panelKey);
  }

  Future<void> clearSelectedPanel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_panelKey);
  }

  Future<void> setGooglePhonePending(bool isPending) async {
    final prefs = await SharedPreferences.getInstance();
    if (isPending) {
      await prefs.setBool(_googlePhonePendingKey, true);
    } else {
      await prefs.remove(_googlePhonePendingKey);
    }
  }

  Future<bool> isGooglePhonePending() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_googlePhonePendingKey) ?? false;
  }
}
