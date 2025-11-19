import 'package:app_remedio/models/profile_model.dart';
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
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:app_remedio/controllers/profile_controller.dart';
import 'package:app_remedio/controllers/schedules_controller.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  late final NotificationController _notificationController;

  static const String _channelName = 'Lembretes de Medicamentos';
  static const String _channelDescription =
      'Canal para notificações de medicamentos';

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
        final settings = Get.find<SettingsController>();
        await _createNotificationChannel(
          soundUri: settings.notificationSoundUri.value,
        );
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
        final _profileController = Get.find<ProfileController>();
        final Profile? profile = await _profileController.getProfileById(data['idPerfil']);

        // 1. Salva a notificação no banco e pega o ID recém-criado.
        final int? newNotificationId = await _notificationController
            .saveNotificationToDatabase(
              idAgendamento: data['idAgendamento'],
              horarioAgendado: data['horarioAgendado'],
              titulo: data['titulo'],
              mensagem: data['mensagem'],
              idPerfil: data['idPerfil'],
            );

        // 2. Se o salvamento foi bem-sucedido, imediatamente marca como lida.
        if (newNotificationId != null) {
          print(
            '✅ Notificação salva com ID $newNotificationId. Marcando como lida...',
          );
          await _notificationController.markAsRead(newNotificationId);
          await _profileController.setCurrentProfile(profile!);

        } else {
          print(
            '⚠️ Falha ao salvar a notificação, não foi possível marcar como lida.',
          );
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

      // 3. Permissão para LER o som do dispositivo (O PONTO CHAVE!)
      if (Platform.isAndroid) {
        final deviceInfo = await DeviceInfoPlugin().androidInfo;
        Permission storagePermission;

        // A partir do Android 13 (SDK 33), a permissão mudou
        if (deviceInfo.version.sdkInt >= 33) {
          storagePermission =
              Permission.audio; // Permissão específica para áudio
        } else {
          storagePermission =
              Permission.storage; // Permissão genérica para armazenamento
        }

        final status = await storagePermission.status;
        if (status.isDenied) {
          print('🔔 Solicitando permissão de acesso ao áudio/armazenamento...');
          await storagePermission.request();
        }
      }
    } catch (e) {
      print('❌ Erro ao solicitar permissões: $e');
    }
  }

  String _getChannelIdForSound(String? soundUri) {
    if (soundUri == null || soundUri.isEmpty || soundUri == 'silent') {
      // ID padrão para som padrão ou silencioso
      return 'medication_channel_default';
    } else {
      // Gera um ID único e consistente para cada som customizado
      return 'medication_channel_${soundUri.hashCode}';
    }
  }

  Future<void> recreateNotificationChannel({
    required String? oldSoundUri, // Precisamos saber o antigo para deletar
    required String? newSoundUri, // E o novo para criar
  }) async {
    final oldChannelId = _getChannelIdForSound(oldSoundUri);
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.deleteNotificationChannel(oldChannelId);

    await _createNotificationChannel(soundUri: newSoundUri);
    final schedulesController = Get.find<SchedulesController>();
    await schedulesController.rescheduleAllNotifications();
    print(
      '✅ Canal de notificação recriado com novo som e todas as notificações reagendadas',
    );
  }

  // <--- MÉTODO PRIVADO MODIFICADO --->
  /// Cria o canal de notificação com um som específico.
  Future<void> _createNotificationChannel({String? soundUri}) async {
    final channelId = _getChannelIdForSound(soundUri);
    AndroidNotificationSound? sound;
    if (soundUri != null && soundUri.isNotEmpty && soundUri != 'silent') {
      sound = UriAndroidNotificationSound(soundUri);
    }

    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
      playSound: true,
      sound: sound, // <-- O som é definido AQUI, na criação!
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
      final profileController = Get.find<ProfileController>();
      final profile = await profileController.getProfileById(dose.idPerfil);

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
                'Olá, ${profile?.nome ?? 'Usuário'}! Está na hora de tomar seu medicamento! Tomar ${dose.medicationName} (${dose.dose}) às ${DateFormat('HH:mm').format(dose.scheduledTime)}.',
            scheduledDate: tz.TZDateTime.from(scheduledTimeBefore, tz.local),
            idAgendamento: dose.scheduledMedicationId,
            idPerfil: dose.idPerfil,
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
                'Olá, ${profile?.nome ?? 'Usuário'}! Você já tomou seu ${dose.medicationName} das ${DateFormat('HH:mm').format(dose.scheduledTime)}?',
            scheduledDate: tz.TZDateTime.from(scheduledTimeAfter, tz.local),
            idAgendamento: dose.scheduledMedicationId,
            idPerfil: dose.idPerfil,
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
    int? idPerfil,
  }) async {
    try {
      final settings = Get.find<SettingsController>();

      AndroidNotificationSound? sound;
      //String? iosSound;

      // Verifica se um som customizado foi selecionado
      if (settings.notificationSoundUri.value != null &&
          settings.notificationSoundUri.value!.isNotEmpty) {
        // AQUI É A MUDANÇA
        if (settings.notificationSoundUri.value == 'silent') {
          // Se for 'silent', não definimos nenhum som
          sound = null;
          //iosSound = null; // Para iOS, `null` desativa o som
        } else {
          // Lógica para Android que já tínhamos, está correta.
          sound = UriAndroidNotificationSound(
            settings.notificationSoundUri.value!,
          );
          //iosSound = 'default'; // iOS continua usando o padrão mesmo com URI do Android
        }
      } else {
        // Se 'Padrão' estiver selecionado
        sound = null;
        //iosSound = 'default';
      }

      final channelId = _getChannelIdForSound(
        settings.notificationSoundUri.value,
      );

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            channelId,
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
        'idPerfil': idPerfil,
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

      final settings = Get.find<SettingsController>();

      // Lógica de som e vibração (igual à do agendamento real)
      AndroidNotificationSound? sound;
      String? iosSound;
      bool presentIosSound = true;

      if (settings.notificationSoundUri.value != null &&
          settings.notificationSoundUri.value!.isNotEmpty) {
        if (settings.notificationSoundUri.value == 'silent') {
          sound = null;
          iosSound = null;
          presentIosSound = false;
        } else {
          sound = UriAndroidNotificationSound(
            settings.notificationSoundUri.value!,
          );
          iosSound = 'default.wav';
        }
      } else {
        sound = null;
        iosSound = 'default.wav';
      }

      final channelId = _getChannelIdForSound(
        settings.notificationSoundUri.value,
      );
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            channelId,
            'Lembretes de Medicamentos',
            channelDescription: 'Canal para notificações de medicamentos',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon',
            sound: sound, // <--- USA O SOM DAS CONFIGURAÇÕES
            enableVibration: settings
                .vibrateEnabled
                .value, // <--- USA A VIBRAÇÃO DAS CONFIGURAÇÕES
          );

      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentSound: presentIosSound,
        sound: iosSound,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Cria um payload para que o toque na notificação de teste também seja testado
      final payloadMap = {
        'idAgendamento': 9999, // ID Fixo para testes
        'horarioAgendado': DateFormat('HH:mm').format(DateTime.now()),
        'titulo': 'Teste de Notificação',
        'mensagem':
            'Se você está vendo isso, as notificações estão funcionando!',
      };
      final String payloadString = jsonEncode(payloadMap);

      await _notificationsPlugin.show(
        999, // ID da notificação em si
        'Teste de Notificação',
        'Se você está vendo isso, as notificações estão funcionando!',
        notificationDetails,
        payload: payloadString, // <--- USA O PAYLOAD
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
