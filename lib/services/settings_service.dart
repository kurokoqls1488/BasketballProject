import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'locale_service.dart';
import 'auth_service.dart';

class SettingsService {
  static const String _vibrationKey = 'vibration_enabled';
  static const String _backgroundKey = 'background_enabled';

  static bool _vibrationEnabled = true;
  static bool _backgroundEnabled = true;

  static bool get vibrationEnabled => _vibrationEnabled;
  static bool get backgroundEnabled => _backgroundEnabled;
  static String get currentLanguage => LocaleService.currentLanguage;
  static bool get isEnglish => LocaleService.isEnglish;

  static Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _vibrationEnabled = prefs.getBool(_vibrationKey) ?? true;
    _backgroundEnabled = prefs.getBool(_backgroundKey) ?? false;
    debugPrint(
      'Settings loaded - vibration: $_vibrationEnabled, background: $_backgroundEnabled',
    );

    await LocaleService.loadLanguage();
  }

  static Future<void> setVibrationEnabled(bool value) async {
    _vibrationEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationKey, value);
    try {
      if (value) {
        await _vibrate();
      }
    } catch (e) {
      // Игнорируем ошибки
    }
  }

  static Future<void> setBackgroundEnabled(bool value) async {
    _backgroundEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_backgroundKey, value);
  }

  static Future<void> _vibrate() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        Vibration.vibrate(duration: 50);
      }
    } catch (e) {
      debugPrint('Vibration error: $e');
    }
  }


  static Future<void> vibrate() async {
    if (_vibrationEnabled) {
      await _vibrate();
    }
  }

  static Future<void> setLanguage(String language) async {
    await LocaleService.setLanguage(language);
  }

  static Future<void> clearCache() async {
    try {
      AuthService.clearCaches();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_workouts');
      await prefs.remove('cached_exercises');
      await prefs.remove('cached_complexes');
      await prefs.remove('cached_favorites');
      debugPrint('Cache cleared successfully');
    } catch (e) {
      debugPrint('Cache clear error: $e');
    }
  }
}