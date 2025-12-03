import 'package:app_remedio/utils/toast_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Usado para navegação e cores
import 'package:jbh_ringtone/jbh_ringtone.dart';
import 'package:app_remedio/utils/constants.dart'; // Importe suas constantes de cores

class SoundSelectionScreen extends StatefulWidget {
  final String? currentSoundUri;

  const SoundSelectionScreen({super.key, this.currentSoundUri});

  @override
  State<SoundSelectionScreen> createState() => _SoundSelectionScreenState();
}

class _SoundSelectionScreenState extends State<SoundSelectionScreen> {
  // Lista para armazenar os sons de notificação
  List<JbhRingtoneModel> notificationSounds = [];
  bool isLoading = true;

  // Instância do plugin
  final JbhRingtone _jbhRingtone = JbhRingtone();

  // Acompanha qual som está tocando no momento
  String? _currentlyPlayingUri;

  @override
  void initState() {
    super.initState();
    _fetchNotificationSounds();
  }

  // Busca os sons do tipo 'notificação'
  Future<void> _fetchNotificationSounds() async {
    try {
      final sounds = await _jbhRingtone.getNotificationRingtones();
      if (mounted) {
        setState(() {
          notificationSounds = sounds;
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Erro ao buscar sons: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ToastService.showError(
          context,
          'Não foi possível carregar os sons de notificação.',
        );
      }
    }
  }

  // Toca ou para um som
  void _togglePlay(JbhRingtoneModel sound) {
    if (_currentlyPlayingUri == sound.uri) {
      // Se o som clicado já está tocando, para
      _jbhRingtone.stopRingtone();
      setState(() {
        _currentlyPlayingUri = null;
      });
    } else {
      // Se outro som (ou nenhum) está tocando, toca o novo
      _jbhRingtone.playRingtone(sound.uri);
      setState(() {
        _currentlyPlayingUri = sound.uri;
      });
    }
  }

  // Para qualquer som que esteja tocando ao sair da tela
  @override
  void dispose() {
    _jbhRingtone.stopRingtone();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Selecionar Som',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Get.back(), // Volta sem selecionar nada
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : ListView.builder(
              itemCount: notificationSounds.length,
              itemBuilder: (context, index) {
                final sound = notificationSounds[index];
                final bool isSelected = widget.currentSoundUri == sound.uri;
                final bool isPlaying = _currentlyPlayingUri == sound.uri;

                return ListTile(
                  title: Text(sound.title, style: TextStyle(color: textColor)),
                  leading: Icon(
                    isSelected ? Icons.check_circle : Icons.music_note,
                    color: isSelected
                        ? primaryColor
                        : textColor.withOpacity(0.7),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      isPlaying
                          ? Icons.stop_circle_outlined
                          : Icons.play_circle_outline,
                      color: primaryColor,
                      size: 30,
                    ),
                    onPressed: () => _togglePlay(sound),
                  ),
                  // Ao tocar na linha, seleciona o som e volta para a tela anterior
                  onTap: () {
                    Get.back(result: sound);
                  },
                );
              },
            ),
    );
  }
}
