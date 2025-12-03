import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/views/profile/add_profile_screen.dart';
import 'package:app_remedio/controllers/backup_controller.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final BackupController _backupController = Get.put(BackupController());

  // Função para restaurar backup e navegar
  Future<void> _handleRestoreBackup() async {
    // O BackupController já cuida de reiniciar o app após restaurar
    await _backupController.importBackup();
  }

  // Lista de slides da apresentação
  final List<Widget> _onboardingPages = [
    const OnboardingPage(
      imagePath: 'assets/images/onboarding_schedules.png', // Crie essa imagem
      title: 'Agendamentos Diários',
      description:
          'Veja todos os seus medicamentos organizados por horário. Marque-os como tomados com apenas um toque e nunca mais perca uma dose.',
    ),
    const OnboardingPage(
      imagePath: 'assets/images/onboarding_medications.png', // Crie essa imagem
      title: 'Gerencie Seus Medicamentos',
      description:
          'Cadastre todos os seus remédios, adicione fotos, controle o estoque e veja tudo organizado em uma lista de A a Z para fácil acesso.',
    ),
    const OnboardingPage(
      imagePath: 'assets/images/onboarding_profiles.png', // Crie essa imagem
      title: 'Perfis para Toda a Família',
      description:
          'Crie perfis separados para cada membro da família. Alterne facilmente entre eles para gerenciar os medicamentos de todos em um só lugar.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: _onboardingPages,
              ),
            ),
            // Indicadores de página (bolinhas)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _onboardingPages.length,
                (index) => buildDot(index: index),
              ),
            ),
            // Botões de ação
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Botão de Restaurar Backup (apenas na última página)
                  if (_currentPage == _onboardingPages.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Obx(
                        () => OutlinedButton.icon(
                          onPressed: _backupController.isLoading.value
                              ? null
                              : _handleRestoreBackup,
                          icon: _backupController.isLoading.value
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: primaryColor,
                                  ),
                                )
                              : Icon(Icons.restore, color: primaryColor),
                          label: Text(
                            'Restaurar Backup',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: primaryColor, width: 2),
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Botão principal (Próximo ou Vamos Começar)
                  ElevatedButton(
                    onPressed: () {
                      // Se não for a última página, avança
                      if (_currentPage < _onboardingPages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      } else {
                        // Se for a última página, vai para a criação de perfil
                        Get.off(() => const AddProfileScreen());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // O texto do botão muda na última página
                    child: Text(
                      _currentPage == _onboardingPages.length - 1
                          ? 'Vamos Começar'
                          : 'Próximo',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para construir os indicadores de página
  AnimatedContainer buildDot({required int index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 5),
      height: 6,
      width: _currentPage == index ? 20 : 6,
      decoration: BoxDecoration(
        color: _currentPage == index ? primaryColor : Colors.grey.shade400,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

// Widget reutilizável para cada página do Onboarding
class OnboardingPage extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;

  const OnboardingPage({
    super.key,
    required this.imagePath,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Use um Flexible para a imagem se adaptar a diferentes tamanhos de tela
          Flexible(
            flex: 3,
            child: Image.asset(
              imagePath,
              // Adicione uma altura máxima para a imagem não ficar muito grande
              height: MediaQuery.of(context).size.height * 0.4,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: textColor.withOpacity(0.7),
              height: 1.5,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
