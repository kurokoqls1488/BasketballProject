import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'locale_service.dart';
import 'auth_service.dart';

class SettingsService {
  static const String _soundKey = 'sound_enabled';
  static const String _vibrationKey = 'vibration_enabled';

  static bool _soundEnabled = true;
  static bool _vibrationEnabled = true;

  static bool get soundEnabled => _soundEnabled;
  static bool get vibrationEnabled => _vibrationEnabled;
  static String get currentLanguage => LocaleService.currentLanguage;
  static bool get isEnglish => LocaleService.isEnglish;

  static Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool(_soundKey) ?? true;
    _vibrationEnabled = prefs.getBool(_vibrationKey) ?? true;
    debugPrint(
      'Settings loaded - sound: $_soundEnabled, vibration: $_vibrationEnabled',
    );

    await LocaleService.loadLanguage();
  }

  static Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, value);
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

  static Future<void> playClickSound() async {
    if (!_soundEnabled) return;

    try {
      await HapticFeedback.selectionClick();
    } catch (e) {
      debugPrint('Click sound error: $e');
    }
  }

  static Future<void> playTimerCompleteSound() async {
    if (!_soundEnabled) return;

    try {
      if (_vibrationEnabled) {
        await Vibration.vibrate(duration: 500);
      }
      await HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('Timer complete sound error: $e');
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