import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/controllers/theme_controller.dart';
import 'package:app_remedio/utils/toast_service.dart';
import 'package:intl/intl.dart';

class DateSelectorWidget extends StatelessWidget {
  const DateSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime.now();
    final List<DateTime> dates = List.generate(
      7,
      (index) => today.add(Duration(days: index - 3)),
    );
    final themeController = Get.find<ThemeController>();

    return Obx(() {
      // Força rebuild quando o tema muda
      themeController.isDarkMode.value;
      
      return Container(
        color: surfaceColor,
        child: Column(
          children: [
            // Logo e título
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // Logo
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Título
                  Text(
                    'MeAlerte',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  // Ícone de notificação (futuro)
                  IconButton(
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: textColor.withValues(alpha: 0.6),
                    ),
                    onPressed: () {
                      // TODO: Implementar notificações
                      final context = Get.overlayContext;
                      if (context != null) {
                        ToastService.showInfo(context, 'Notificações serão implementadas');
                      }
                    },
                  ),
                ],
              ),
            ),
            
            // Seletor de dias
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: dates.length,
                itemBuilder: (context, index) {
                  final date = dates[index];
                  final isToday = DateFormat('yyyy-MM-dd').format(date) == 
                                 DateFormat('yyyy-MM-dd').format(today);
                  final isEnabled = index == 3; // Só hoje está habilitado por enquanto
                  
                  return GestureDetector(
                    onTap: isEnabled ? () {
                      // TODO: Implementar seleção de data
                    } : null,
                    child: Container(
                      width: 48,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isToday ? primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: !isToday && isEnabled 
                            ? Border.all(color: primaryColor.withValues(alpha: 0.3))
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _getDayAbbreviation(date),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isToday 
                                  ? Colors.white 
                                  : isEnabled 
                                      ? textColor.withValues(alpha: 0.8)
                                      : textColor.withValues(alpha: 0.3),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('d').format(date),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isToday 
                                  ? Colors.white 
                                  : isEnabled 
                                      ? textColor
                                      : textColor.withValues(alpha: 0.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Divisor
            Container(
              height: 1,
              color: Colors.grey.withValues(alpha: 0.2),
              margin: const EdgeInsets.only(top: 8),
            ),
          ],
        ),
      );
    });
  }

  String _getDayAbbreviation(DateTime date) {
    const days = ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SAB'];
    return days[date.weekday % 7];
  }
} 