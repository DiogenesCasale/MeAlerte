import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:app_remedio/models/scheduled_medication_model.dart';
import 'package:app_remedio/controllers/settings_controller.dart';
import 'package:app_remedio/controllers/notification_controller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  late final NotificationController _notificationController;

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> init() async {
    try {
      _notificationController = Get.find<NotificationController>();
      // Solicita permissões de notificação
      await _requestNotificationPermissions();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      final InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      final bool? initialized = await _notificationsPlugin.initialize(
        initializationSettings,
        // <<< MUDANÇA PRINCIPAL AQUI >>>
        // Esta função é chamada QUANDO a notificação é exibida.
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized == true) {
        print('✅ Serviço de notificações inicializado com sucesso');

        // Cria o canal de notificação para Android
        await _createNotificationChannel();
      } else {
        print('❌ Falha ao inicializar serviço de notificações');
      }

      tz.initializeTimeZones();
    } catch (e) {
      print('❌ Erro ao inicializar notificações: $e');
    }
  }

  // <<< REFAZENDO ESTE MÉTODO COMPLETAMENTE >>>
  /// Orquestra as ações quando o usuário toca na notificação.
  Future<void> _onNotificationTapped(NotificationResponse response) async {
    print('🔔 Notificação TOCADA pelo usuário. Payload: ${response.payload}');
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        final Map<String, dynamic> data = jsonDecode(response.payload!);
        
        // 1. Salva a notificação no banco e pega o ID recém-criado.
        final int? newNotificationId = await _notificationController.saveNotificationToDatabase(
          idAgendamento: data['idAgendamento'],
          horarioAgendado: data['horarioAgendado'],
          titulo: data['titulo'],
          mensagem: data['mensagem'],
        );

        // 2. Se o salvamento foi bem-sucedido, imediatamente marca como lida.
        if (newNotificationId != null) {
          print('✅ Notificação salva com ID $newNotificationId. Marcando como lida...');
          await _notificationController.markAsRead(newNotificationId);
        } else {
          print('⚠️ Falha ao salvar a notificação, não foi possível marcar como lida.');
        }

      } catch (e) {
        print('❌ Erro ao processar payload da notificação: $e');
      }
    }
  }

  Future<void> _requestNotificationPermissions() async {
    try {
      // Para Android 13+ (API 33+)
      if (await Permission.notification.isDenied) {
        final status = await Permission.notification.request();
        if (status.isGranted) {
          print('✅ Permissão de notificação concedida');
        } else {
          print('❌ Permissão de notificação negada');
        }
      }

      // Para alarmes exatos (Android 12+)
      if (await Permission.scheduleExactAlarm.isDenied) {
        final status = await Permission.scheduleExactAlarm.request();
        if (status.isGranted) {
          print('✅ Permissão de alarme exato concedida');
        } else {
          print('❌ Permissão de alarme exato negada');
        }
      }
    } catch (e) {
      print('❌ Erro ao solicitar permissões: $e');
    }
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'medication_channel_id',
      'Lembretes de Medicamentos',
      description: 'Canal para notificações de medicamentos',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  int _generateNotificationId(
    int scheduledId,
    DateTime time,
    bool isReminderBefore,
  ) {
    final timeId = time.millisecondsSinceEpoch ~/ 60000;
    final typePrefix = isReminderBefore ? 1 : 2;
    return int.parse('$typePrefix${scheduledId % 1000}$timeId') % 2147483647;
  }

  Future<void> scheduleMedicationNotifications(TodayDose dose) async {
    try {
      final settings = Get.find<SettingsController>();
      if (!settings.notificationsEnabled.value) {
        print('🔕 Notificações desabilitadas nas configurações');
        return;
      }

      // Verifica se as permissões estão concedidas
      if (!await Permission.notification.isGranted) {
        print('❌ Permissão de notificação não concedida');
        return;
      }

      print(
        '📅 Agendando notificações para: ${dose.medicationName} às ${DateFormat('HH:mm').format(dose.scheduledTime)}',
      );

      if (settings.timeBefore.value > 0) {
        final scheduledTimeBefore = dose.scheduledTime.subtract(
          Duration(minutes: settings.timeBefore.value),
        );
        if (scheduledTimeBefore.isAfter(DateTime.now())) {
          await _scheduleSingleNotification(
            id: _generateNotificationId(
              dose.scheduledMedicationId,
              dose.scheduledTime,
              true,
            ),
            title: 'Lembrete de Medicamento',
            body:
                '${settings.reminderText.value} ${dose.medicationName} às ${DateFormat('HH:mm').format(dose.scheduledTime)}.',
            scheduledDate: tz.TZDateTime.from(scheduledTimeBefore, tz.local),
            idAgendamento: dose.scheduledMedicationId,
          );
          print(
            '⏰ Notificação de lembrete agendada para: ${DateFormat('dd/MM/yyyy HH:mm').format(scheduledTimeBefore)}',
          );
        }
      }

      if (settings.timeAfter.value > 0) {
        final scheduledTimeAfter = dose.scheduledTime.add(
          Duration(minutes: settings.timeAfter.value),
        );
        if (scheduledTimeAfter.isAfter(DateTime.now())) {
          await _scheduleSingleNotification(
            id: _generateNotificationId(
              dose.scheduledMedicationId,
              dose.scheduledTime,
              false,
            ),
            title: 'Medicamento Atrasado',
            body:
                'Você já tomou seu ${dose.medicationName} das ${DateFormat('HH:mm').format(dose.scheduledTime)}?',
            scheduledDate: tz.TZDateTime.from(scheduledTimeAfter, tz.local),
            idAgendamento: dose.scheduledMedicationId,
          );
          print(
            '⏰ Notificação de atraso agendada para: ${DateFormat('dd/MM/yyyy HH:mm').format(scheduledTimeAfter)}',
          );
        }
      }
    } catch (e) {
      print('❌ Erro ao agendar notificações: $e');
    }
  }

  Future<void> _scheduleSingleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    int? idAgendamento,
  }) async {
    try {
      final settings = Get.find<SettingsController>();

      final sound = settings.sound.value == 'default'
          ? null
          : RawResourceAndroidNotificationSound(settings.sound.value);

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'medication_channel_id',
            'Lembretes de Medicamentos',
            channelDescription: 'Canal para notificações de medicamentos',
            importance: Importance.max,
            priority: Priority.high,
            sound: sound,
            enableVibration: settings.vibrateEnabled.value,
            showWhen: true,
            when: scheduledDate.millisecondsSinceEpoch,
            icon: '@mipmap/launcher_icon',
            largeIcon: const DrawableResourceAndroidBitmap(
              '@mipmap/launcher_icon',
            ),
            autoCancel: false,
            ongoing: false,
            silent: false,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentSound: true,
        presentAlert: true,
        presentBadge: true,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Criamos um mapa com os dados que queremos salvar no banco DEPOIS.
      final payloadMap = {
        'idAgendamento': idAgendamento,
        'horarioAgendado': DateFormat('HH:mm').format(scheduledDate),
        'titulo': title,
        'mensagem': body,
      };
      // Convertemos o mapa para uma string JSON.
      final String payloadString = jsonEncode(payloadMap);

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        payload: payloadString, // <--- USAMOS O PAYLOAD AQUI
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      // Não vamos mais salvar no banco de dados neste momento.
      // await _notificationController.saveNotificationToDatabase(
      //   idAgendamento: idAgendamento,
      //   horarioAgendado: DateFormat('HH:mm').format(scheduledDate),
      //   titulo: title,
      //   mensagem: body,
      // );

      print('✅ Notificação agendada com sucesso - ID: $id');
    } catch (e) {
      print('❌ Erro ao agendar notificação individual: $e');
    }
  }

  Future<void> cancelMedicationNotifications(TodayDose dose) async {
    try {
      await _notificationsPlugin.cancel(
        _generateNotificationId(
          dose.scheduledMedicationId,
          dose.scheduledTime,
          true,
        ),
      );
      await _notificationsPlugin.cancel(
        _generateNotificationId(
          dose.scheduledMedicationId,
          dose.scheduledTime,
          false,
        ),
      );
      print('✅ Notificações canceladas para: ${dose.medicationName}');
    } catch (e) {
      print('❌ Erro ao cancelar notificações: $e');
    }
  }

  /// Método para testar notificações (útil para debug)
  Future<void> testNotification() async {
    try {
      if (!await Permission.notification.isGranted) {
        print('❌ Permissão de notificação não concedida para teste');
        return;
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'medication_channel_id',
            'Lembretes de Medicamentos',
            channelDescription: 'Canal para notificações de medicamentos',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon',
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        999,
        'Teste de Notificação',
        'Se você está vendo isso, as notificações estão funcionando!',
        notificationDetails,
      );

      await _notificationController.saveNotificationToDatabase(
        idAgendamento: 1,
        horarioAgendado: DateFormat('HH:mm').format(DateTime.now()),
        titulo: 'Teste de Notificação',
        mensagem: 'Se você está vendo isso, as notificações estão funcionando!',
      );

      print('✅ Notificação de teste enviada');
    } catch (e) {
      print('❌ Erro ao enviar notificação de teste: $e');
    }
  }

  /// Verifica se as notificações estão habilitadas
  Future<bool> areNotificationsEnabled() async {
    try {
      return await Permission.notification.isGranted;
    } catch (e) {
      print('❌ Erro ao verificar permissões: $e');
      return false;
    }
  }

  /// Cancela todas as notificações agendadas
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      print('✅ Todas as notificações foram canceladas');
    } catch (e) {
      print('❌ Erro ao cancelar todas as notificações: $e');
    }
  }
}
