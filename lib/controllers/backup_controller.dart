import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:app_remedio/controllers/database_controller.dart';
import 'package:app_remedio/utils/toast_service.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:app_remedio/controllers/profile_controller.dart';
import 'package:app_remedio/controllers/medication_controller.dart';
import 'package:app_remedio/controllers/schedules_controller.dart';
import 'package:app_remedio/controllers/health_data_controller.dart';
import 'package:app_remedio/controllers/notification_controller.dart';
import 'package:app_remedio/controllers/settings_controller.dart';
import 'package:app_remedio/utils/notification_service.dart';
import 'package:app_remedio/main.dart' show SplashScreen;
import 'package:sqflite/sqflite.dart'; // Para openDatabase
import 'package:path/path.dart'; // Para join

class BackupController extends GetxController {
  final DatabaseController _dbController = DatabaseController.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final RxBool isLoading = false.obs;

  /// Reinicia o app completamente, seguindo a ordem correta do main.dart
  Future<void> _restartApp() async {
    try {
      print('Iniciando reinicialização do app...');
      
      // 1. Fecha o banco de dados primeiro
      try {
        await _dbController.close();
        print('Banco de dados fechado.');
      } catch (e) {
        print('Erro ao fechar banco: $e');
      }
      
      // 2. Deleta todos os controllers na ordem inversa
      Get.delete<HealthDataController>(force: true);
      Get.delete<SchedulesController>(force: true);
      Get.delete<MedicationController>(force: true);
      Get.delete<SettingsController>(force: true);
      Get.delete<NotificationController>(force: true);
      Get.delete<ProfileController>(force: true);
      Get.delete<BackupController>(force: true); // Deleta ele mesmo
      // ThemeController e GlobalStateController não devem ser deletados
      
      print('Controllers deletados.');
      
      // 3. Aguarda um pouco para garantir que tudo foi limpo
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 4. Recria os controllers na ORDEM CORRETA (mesma do main.dart) COM permanent: true
      // GlobalStateController e ThemeController já existem, não recriar
      Get.put(ProfileController(), permanent: true);
      Get.put(NotificationController(), permanent: true);
      Get.put(SettingsController(), permanent: true);
      
      await NotificationService().init();
      
      Get.put(MedicationController(), permanent: true);
      Get.put(SchedulesController(), permanent: true);
      Get.put(HealthDataController(), permanent: true);
      
      print('Controllers recriados na ordem correta com permanent: true.');
      
      // 5. Aguarda mais um pouco para os controllers inicializarem
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 6. AGORA navega para a SplashScreen usando offAllNamed para limpar a pilha
      // mas os controllers permanent não serão deletados
      Get.offAll(() => const SplashScreen(), 
        transition: Transition.fadeIn,
        predicate: (route) => false, // Remove todas as rotas
      );
      
      print('App reiniciado com sucesso!');
    } catch (e) {
      print('Erro ao reiniciar app: $e');
    }
  }

  /// Exporta todos os dados do banco para um arquivo JSON
  Future<bool> exportBackup() async {
    // ... (Seu código original, sem mudanças)
    try {
      isLoading.value = true;
      final db = await _dbController.database;

      final packageInfo = await PackageInfo.fromPlatform();
      final version = packageInfo.version;

      // Coleta todos os dados de todas as tabelas
      final backupData = <String, dynamic>{
        'version': version,
        'exportDate': DateTime.now().toIso8601String(),
        'tables': {},
      };

      // Lista de todas as tabelas do banco
      final tables = [
        'tblPerfil',
        'tblMedicamentos',
        'tblMedicamentosAgendados',
        'tblDadosSaude',
        'tblDosesTomadas',
        'tblEstoqueMedicamento',
        'tblNotificacoes',
        'tblAnotacoes',
      ];

      // Exporta dados de cada tabela (apenas não deletados)
      for (final table in tables) {
        try {
          final result = await db.query(
            table,
            where: 'deletado = ?',
            whereArgs: [0],
          );
          backupData['tables']![table] = result;
        } catch (e) {
          print('Erro ao exportar tabela $table: $e');
          // Continua mesmo se uma tabela falhar
        }
      }

      // Converte para JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      // Salva o arquivo no diretório de downloads
      Directory downloadsDir;
      if (Platform.isAndroid) {
        // No Android, tenta usar o diretório de downloads público
        // Caminho típico: /storage/emulated/0/Download
        final androidDownloadDir = Directory('/storage/emulated/0/Download');
        if (await androidDownloadDir.exists()) {
          downloadsDir = androidDownloadDir;
        } else {
          // Fallback: usa o diretório externo do app
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            downloadsDir = Directory('${externalDir.path}/Download');
          } else {
            final appDir = await getApplicationDocumentsDirectory();
            downloadsDir = Directory('${appDir.path}/Download');
          }
        }
      } else {
        // iOS ou outras plataformas
        final directory =
            await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory();
        downloadsDir = Directory('${directory.path}/Downloads');
      }

      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'me_alerte_backup_$timestamp.json';
      final filePath = '${downloadsDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(jsonString);

      final context = Get.overlayContext;
      if (context != null) {
        ToastService.showSuccess(context, 'Backup salvo na pasta Downloads!');
      }

      return true;
    } catch (e) {
      print('Erro ao exportar backup: $e');
      final context = Get.overlayContext;
      if (context != null) {
        ToastService.showError(context, 'Erro ao criar backup: $e');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Importa dados de um arquivo JSON de backup
  Future<bool> importBackup() async {
    // ... (Seu código original, sem mudanças)
    try {
      // Seleciona arquivo
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return false;
      }

      final filePath = result.files.single.path!;
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Confirma antes de importar
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Confirmar Restauração'),
          content: const Text(
            'Esta ação irá substituir todos os dados atuais pelos dados do backup.\n\n'
            'Tem certeza que deseja continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Restaurar'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        return false;
      }

      isLoading.value = true;
      final db = await _dbController.database;

      // Inicia transação
      await db.transaction((txn) async {
        // NÃO LIMPAR AS TABELAS, APENAS RESTAURAR OS DADOS, POIS O RESTAURAR SÓ APARECE NO INICIO DO APP
        // Limpa todas as tabelas (soft delete)
        // final tables = [
        //   'tblPerfil',
        //   'tblMedicamentos',
        //   'tblMedicamentosAgendados',
        //   'tblDadosSaude',
        //   'tblDosesTomadas',
        //   'tblEstoqueMedicamento',
        //   'tblNotificacoes',
        //   'tblAnotacoes',
        // ];

        // Marca todos como deletados
        // for (final table in tables) {
        //   try {
        //     await txn.update(table, {'deletado': 1});
        //   } catch (e) {
        //     print('Erro ao limpar tabela $table: $e');
        //   }
        // }

        // Restaura dados do backup
        final tablesData = backupData['tables'] as Map<String, dynamic>?;
        if (tablesData != null) {
          for (final entry in tablesData.entries) {
            final tableName = entry.key;
            final rows = entry.value as List<dynamic>;

            for (final row in rows) {
              try {
                final rowMap = Map<String, dynamic>.from(
                  row as Map<String, dynamic>,
                );
                // Remove o campo id temporariamente para evitar conflitos
                rowMap.remove('id');

                // Insere o registro (deixa o banco gerenciar os IDs)
                await txn.insert(tableName, rowMap);
              } catch (e) {
                print('Erro ao restaurar registro na tabela $tableName: $e');
              }
            }
          }
        }
      });

      // Nota: Os controllers serão recarregados automaticamente quando necessário

      final context = Get.overlayContext;
      if (context != null) {
        ToastService.showSuccess(context, 'Backup restaurado com sucesso! Reiniciando app...');
      }

      // Aguarda um pouco para o toast ser exibido
      await Future.delayed(const Duration(milliseconds: 1500));

      // Reinicia o app
      await _restartApp();

      return true;
    } catch (e) {
      print('Erro ao importar backup: $e');
      final context = Get.overlayContext;
      if (context != null) {
        ToastService.showError(context, 'Erro ao restaurar backup: $e');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Limpa todos os dados do banco (truncate) com autenticação
  Future<bool> clearAllData() async {
    try {
      isLoading.value = true;

      // 1. CONFIRMAÇÃO INICIAL (DIALOG)
      // ... (código de confirmação mantido, sem mudanças)
      final confirmDialog = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Confirmar Limpeza'),
          content: const Text(
            'Tem certeza que deseja apagar TODOS os dados?\n\n'
            'Esta ação é IRREVERSÍVEL!',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );

      if (confirmDialog != true) {
        isLoading.value = false;
        return false;
      }

      // 2. LÓGICA DE AUTENTICAÇÃO
      // ... (código de autenticação mantido, sem mudanças)
      bool authenticated = false;
      try {
        final isAvailable = await _localAuth.canCheckBiometrics;
        final isDeviceSupported = await _localAuth.isDeviceSupported();
        final availableBiometrics = await _localAuth.getAvailableBiometrics();

        if (isAvailable && isDeviceSupported && availableBiometrics.isNotEmpty) {
          final biometricResult = await _authenticateWithBiometrics();
          if (biometricResult) {
            authenticated = true;
          } else {
            authenticated = await _showAuthFailedDialog();
          }
        } else {
          authenticated = await _authenticateWithManualConfirmation();
        }
      } catch (e) {
        print('Erro na verificação de biometria: $e');
        authenticated = await _authenticateWithManualConfirmation();
      }

      if (!authenticated) {
        print('Autenticação não confirmada');
        final context = Get.overlayContext;
        if (context != null) {
          ToastService.showError(context, 'Autenticação cancelada');
        }
        isLoading.value = false;
        return false;
      }

      print('Autenticação confirmada, iniciando limpeza...');

      // --- INÍCIO DA CORREÇÃO (CONEXÃO PRIVADA) ---
      print('Iniciando limpeza (método de conexão privada)...');

      // 1. Descobrir o caminho do banco (sem usar o controller)
      //    (O nome 'app_remedio_v4.db' foi pego do seu DatabaseController)
      final dbDirectoryPath = await getDatabasesPath();
      final dbPath = join(dbDirectoryPath, 'app_remedio_v4.db');
      print('Abrindo conexão privada com: $dbPath');

      // 2. Abrir uma NOVA conexão com o banco
      Database privateDb;
      try {
        privateDb = await openDatabase(dbPath);
        print('Conexão privada aberta com sucesso.');
      } catch (e) {
        print('Falha ao abrir conexão privada: $e');
        isLoading.value = false;
        // (Mostra o toast de erro no 'finally' externo)
        rethrow;
      }
      
      // 3. Executar os deletes nesta conexão PRIVADA
      try {
        await privateDb.execute('PRAGMA foreign_keys = OFF');
        print('Foreign keys desabilitadas (conexão privada).');

        final tables = [
          'tblAnotacoes',
          'tblNotificacoes',
          'tblEstoqueMedicamento',
          'tblDosesTomadas',
          'tblDadosSaude',
          'tblMedicamentosAgendados',
          'tblMedicamentos',
          'tblPerfil',
        ];

        for (final table in tables) {
          print('[Privado] Limpando tabela: $table...');
          final rowsDeleted = await privateDb.delete(table);
          print('[Privado] Tabela $table limpa ($rowsDeleted linhas afetadas).');
        }
        
        print('[Privado] Todas as tabelas foram limpas.');

      } catch (e) {
        print('Erro ao limpar tabelas na conexão privada: $e');
        // O finally abaixo VAI rodar de qualquer jeito
      } finally {
        // 4. Fechar a conexão privada, não importa o que aconteça
        await privateDb.execute('PRAGMA foreign_keys = ON');
        await privateDb.close();
        print('Conexão privada fechada.');
      }
      // --- FIM DA CORREÇÃO ---

      print('Limpeza concluída com sucesso.');

      final context = Get.overlayContext;
      if (context != null) {
        ToastService.showSuccess(
          context,
          'Todos os dados foram apagados! Reiniciando app...',
        );
      }

      // Aguarda um pouco para o toast ser exibido
      await Future.delayed(const Duration(milliseconds: 1500));

      // Reinicia o app
      await _restartApp();

      return true;
    } catch (e) {
      print('Erro fatal ao limpar dados: $e');
      final context = Get.overlayContext;
      if (context != null) {
        ToastService.showError(context, 'Erro ao apagar dados: $e');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // --- MUDANÇA ---
  // NOVA FUNÇÃO (COPIADA DO PROFILECONTROLLER)
  /// Autenticação com biometria
  Future<bool> _authenticateWithBiometrics() async {
    try {
      await HapticFeedback.mediumImpact();

      final didAuthenticate = await _localAuth.authenticate(
        // Texto específico para esta ação
        localizedReason: 'Confirme sua identidade para apagar todos os dados',
        options: const AuthenticationOptions(
          biometricOnly: false, // Permite PIN/senha como fallback
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        await HapticFeedback.lightImpact();
        return true;
      } else {
        await HapticFeedback.heavyImpact();
        print('Autenticação biométrica cancelada pelo usuário');
        return false;
      }
    } catch (e) {
      print('Erro na autenticação biométrica: $e');
      await HapticFeedback.heavyImpact();
      return false;
    }
  }

  // --- MUDANÇA ---
  // NOVA FUNÇÃO (COPIADA DO PROFILECONTROLLER)
  /// Mostra diálogo quando a autenticação biométrica falha
  Future<bool> _showAuthFailedDialog() async {
    try {
      final result = await Get.dialog<String>(
        AlertDialog(
          title: const Text('Autenticação Falhada'),
          content: const Text(
            'A autenticação biométrica não foi concluída.\n\n'
            'Você pode tentar novamente ou usar a confirmação manual.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: 'cancel'),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Get.back(result: 'retry'),
              child: const Text('Tentar Novamente'),
            ),
            TextButton(
              onPressed: () => Get.back(result: 'manual'),
              child: const Text('Confirmação Manual'),
            ),
          ],
        ),
      );

      switch (result) {
        case 'retry':
          // Chama a função de biometria deste controller
          return await _authenticateWithBiometrics();
        case 'manual':
          // Chama a função de confirmação manual deste controller
          return await _authenticateWithManualConfirmation();
        default:
          return false;
      }
    } catch (e) {
      print('Erro no diálogo de falha de autenticação: $e');
      return false;
    }
  }

  /// Autenticação manual com confirmação de texto
  Future<bool> _authenticateWithManualConfirmation() async {
    // ... (Seu código original, sem mudanças)
    // Esta função já estava correta, verificando "APAGAR TUDO"
    try {
      final confirmController = TextEditingController();
      bool isValid = false;

      final authDialog = await Get.dialog<bool>(
        StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Confirme sua Identidade'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Para apagar todos os dados, digite "APAGAR TUDO" no campo abaixo para confirmar.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmController,
                    decoration: InputDecoration(
                      hintText: 'Digite APAGAR TUDO',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.security),
                      suffixIcon: isValid
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        isValid = value.toUpperCase() == 'APAGAR TUDO';
                      });
                    },
                    textCapitalization: TextCapitalization.characters,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(result: false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: isValid ? () => Get.back(result: true) : null,
                  style: TextButton.styleFrom(
                    foregroundColor: isValid ? Colors.red : Colors.grey,
                  ),
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        ),
        barrierDismissible: false,
      );

      confirmController.dispose();
      final result = authDialog == true;
      print('Resultado da autenticação manual: $result');
      return result;
    } catch (e) {
      print('Erro na autenticação manual: $e');
      return false;
    }
  }
}
