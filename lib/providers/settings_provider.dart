import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// وضعیت تنظیمات کلی برنامه (فقط موسیقی - طبق مشخصات فعلی)
class SettingsProvider extends ChangeNotifier {
  static const String _musicKey = 'komandoel_music_enabled';

  bool _isMusicOn = true;
  bool get isMusicOn => _isMusicOn;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isMusicOn = prefs.getBool(_musicKey) ?? true;
    notifyListeners();
  }

  Future<void> toggleMusic() async {
    _isMusicOn = !_isMusicOn;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicKey, _isMusicOn);
  }
}
