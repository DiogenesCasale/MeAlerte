import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_remedio/utils/notification_service.dart';

class SettingsController extends GetxController {
  late SharedPreferences _prefs;

  // Chaves para SharedPreferences
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyVibrateEnabled = 'vibrate_enabled';
  static const String keyTimeBefore = 'notification_time_before';
  static const String keyTimeAfter = 'notification_time_after';
  static const String keyReminderText = 'notification_reminder_text';
  static const String keyNotificationSoundUri = 'notification_sound_uri';
  static const String keyNotificationSoundTitle = 'notification_sound_title';

  // Observables para a UI
  final notificationsEnabled = true.obs;
  final vibrateEnabled = true.obs;
  final timeBefore = 15.obs; // Em minutos
  final timeAfter = 30.obs; // Em minutos
  final reminderText = 'Está na hora de tomar seu medicamento!'.obs;
  final notificationSoundUri =
      RxnString(); // URI do som, pode ser nulo (padrão)
  final notificationSoundTitle = 'Padrão'.obs; // Nome do som para exibir na UI

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();

    notificationsEnabled.value =
        _prefs.getBool(keyNotificationsEnabled) ?? true;
    vibrateEnabled.value = _prefs.getBool(keyVibrateEnabled) ?? true;
    timeBefore.value = _prefs.getInt(keyTimeBefore) ?? 15;
    timeAfter.value = _prefs.getInt(keyTimeAfter) ?? 30;
    notificationSoundUri.value = _prefs.getString(keyNotificationSoundUri);
    notificationSoundTitle.value =
        _prefs.getString(keyNotificationSoundTitle) ?? 'Padrão';
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

  Future<void> setNotificationSound(String? uri, String? title) async {
    final oldSoundUri = notificationSoundUri.value;
    String? sanitizedUri = uri;

    if (uri != null && uri.contains('?')) {
      sanitizedUri = uri.split('?').first;
    }

    notificationSoundUri.value = sanitizedUri;
    notificationSoundTitle.value = title ?? 'Padrão';

    // Salva nas SharedPreferences como antes
    if (sanitizedUri != null) {
      _prefs.setString(keyNotificationSoundUri, sanitizedUri);
    } else {
      _prefs.remove(keyNotificationSoundUri);
    }
    _prefs.setString(keyNotificationSoundTitle, title ?? 'Padrão');

    // <--- A PEÇA FINAL: Comanda a recriação do canal --->
    print('⚙️ Comandando a recriação do canal de notificação...');
    final notificationService = NotificationService();
    await notificationService.recreateNotificationChannel(
      oldSoundUri: oldSoundUri,
      newSoundUri: sanitizedUri,
    );
  }
}
