import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// سرویس مدیریت موسیقی پس‌زمینه
/// موسیقی بین صفحات حفظ می‌شود و ادامه می‌یابد
class AudioService extends ChangeNotifier {
  static final AudioService _instance = AudioService._internal();

  factory AudioService() {
    return _instance;
  }

  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isMusicEnabled = true;
  StreamSubscription<void>? _completeSub;

  bool get isPlaying => _isPlaying;
  bool get isMusicEnabled => _isMusicEnabled;

  /// تنظیم فعال/غیرفعال کردن موسیقی از SettingsProvider
  /// نکته: این متد از هر صفحه (Home، Setup، Settings) صدا زده می‌شود، پس اگر
  /// موسیقی از قبل در حال پخش بود دوباره play() نمی‌کنیم (وگرنه با هر بار
  /// ورود به یک صفحه، یک نسخه‌ی جدید و هم‌زمان از آهنگ روی نسخه‌ی قبلی
  /// می‌نشیند و صدا کم‌کم روی هم تکرار و خراب می‌شود).
  void setMusicEnabled(bool enabled) {
    _isMusicEnabled = enabled;
    if (enabled) {
      if (!_isPlaying) _playMusic();
    } else {
      _pauseMusic();
    }
    notifyListeners();
  }

  /// پخش موسیقی (اگر قبلاً متوقف نشده باشد، ادامه می‌یابد)
  Future<void> playMusic() async {
    if (_isMusicEnabled && !_isPlaying) {
      await _playMusic();
    }
  }

  /// متوقف کردن موسیقی
  Future<void> pauseMusic() async {
    await _pauseMusic();
  }

  /// بازگشت موسیقی از اول
  Future<void> stopMusic() async {
    await _audioPlayer.stop();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> _playMusic() async {
    try {
      await _audioPlayer.play(AssetSource('audio/background_music.mp3'));
      // قبل از ثبت شنونده‌ی جدید، شنونده‌ی قبلی را لغو می‌کنیم؛ در غیر این
      // صورت هر بار که این متد صدا زده می‌شد (که در این سرویس مکرراً از
      // صفحات مختلف اتفاق می‌افتد) یک شنونده‌ی جدید روی قبلی‌ها اضافه می‌شد
      // و بعد از چند بار تکرار آهنگ، چندین نسخه هم‌زمان روی هم پخش می‌شدند.
      await _completeSub?.cancel();
      _completeSub = _audioPlayer.onPlayerComplete.listen((event) {
        // تکرار موسیقی
        _playMusic();
      });
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('خطا در پخش موسیقی: $e');
      }
    }
  }

  Future<void> _pauseMusic() async {
    try {
      await _audioPlayer.pause();
      _isPlaying = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('خطا در متوقف کردن موسیقی: $e');
      }
    }
  }

  /// تنظیم سطح صدا (0.0 - 1.0)
  /// 0.5 = نیمی از صدای پیش‌فرض
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume);
  }

  void dispose() {
    _completeSub?.cancel();
    _audioPlayer.dispose();
  }
}
