import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends GetxController {
  late SharedPreferences _prefs;

  // Chaves para SharedPreferences
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyVibrateEnabled = 'vibrate_enabled';
  static const String keySound = 'notification_sound';
  static const String keyTimeBefore = 'notification_time_before';
  static const String keyTimeAfter = 'notification_time_after';
  static const String keyReminderText = 'notification_reminder_text';

  // Observables para a UI
  final notificationsEnabled = true.obs;
  final vibrateEnabled = true.obs;
  final sound = 'default'.obs; // 'default' ou 'none'
  final timeBefore = 15.obs; // Em minutos
  final timeAfter = 30.obs; // Em minutos
  final reminderText = 'Está na hora de tomar seu medicamento!'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();

    notificationsEnabled.value = _prefs.getBool(keyNotificationsEnabled) ?? true;
    vibrateEnabled.value = _prefs.getBool(keyVibrateEnabled) ?? true;
    sound.value = _prefs.getString(keySound) ?? 'default';
    timeBefore.value = _prefs.getInt(keyTimeBefore) ?? 15;
    timeAfter.value = _prefs.getInt(keyTimeAfter) ?? 30;
    reminderText.value = _prefs.getString(keyReminderText) ?? 'Está na hora de tomar seu medicamento!';
  }

  // Métodos para salvar cada configuração individualmente
  void setNotificationsEnabled(bool value) {
    notificationsEnabled.value = value;
    _prefs.setBool(keyNotificationsEnabled, value);
  }

  void setVibrate(bool value) {
    vibrateEnabled.value = value;
    _prefs.setBool(keyVibrateEnabled, value);
  }
  
  void setSound(String value) {
    sound.value = value;
    _prefs.setString(keySound, value);
  }

  void setTimeBefore(int minutes) {
    timeBefore.value = minutes;
    _prefs.setInt(keyTimeBefore, minutes);
  }
  
  void setTimeAfter(int minutes) {
    timeAfter.value = minutes;
    _prefs.setInt(keyTimeAfter, minutes);
  }

  void setReminderText(String text) {
    reminderText.value = text;
    _prefs.setString(keyReminderText, text);
  }
}