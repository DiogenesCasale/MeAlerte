import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/controllers/theme_controller.dart';
import 'package:app_remedio/controllers/schedules_controller.dart';
import 'package:intl/intl.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class DateSelectorWidget extends StatefulWidget {
  const DateSelectorWidget({super.key});

  @override
  State<DateSelectorWidget> createState() => _DateSelectorWidgetState();
}

class _DateSelectorWidgetState extends State<DateSelectorWidget> {
  // ALTERADO: Controllers para o novo pacote
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  late List<DateTime> dates;
  late DateTime today;
  static const int initialDaysToShow = 365;

  @override
  void initState() {
    super.initState();
    // Para garantir que a hora não interfira na comparação de datas
    final now = DateTime.now();
    today = DateTime(now.year, now.month, now.day);
    
    _initializeDates();

    // Aguarda o widget ser construído para rolar até hoje
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday(animated: false); // Scroll inicial sem animação
    });
  }

  void _initializeDates() {
    final startDate = today.subtract(const Duration(days: initialDaysToShow));
    // Gera 2 anos de datas (1 para trás, 1 para frente)
    dates = List.generate(
      initialDaysToShow * 2 + 1,
      (index) => startDate.add(Duration(days: index)),
    );
  }

  // ALTERADO: Função de rolagem muito mais simples e precisa
  void _scrollToToday({bool animated = true}) {
    // Não precisa mais de cálculos complexos de largura
    final todayIndex = dates.indexOf(today);
    
    if (todayIndex != -1) {
      if (animated) {
        _itemScrollController.scrollTo(
          index: todayIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.5, // 0.5 para centralizar o item na tela
        );
      } else {
        // jumpTo é instantâneo, ideal para o carregamento inicial
        _itemScrollController.jumpTo(
          index: todayIndex,
          alignment: 0.5,
        );
      }
    }
  }

  // As funções de carregar mais datas (onScroll, loadMore) foram removidas
  // para simplificar. A lista com 2 anos de datas geralmente é suficiente.
  // Se precisar de um "scroll infinito", a lógica pode ser readicionada.

  @override
  void dispose() {
    // Não há controller para dar dispose aqui
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final schedulesController = Get.find<SchedulesController>();

    return Obx(() {
      themeController.isDarkMode;
      final selectedDate = schedulesController.selectedDate.value;
      
      return Container(
        color: surfaceColor,
        child: Column(
          children: [
            Container(
              height: 100,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            schedulesController.selectDate(today);
                            _scrollToToday();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.today, size: 16, color: primaryColor),
                                const SizedBox(width: 4),
                                Text(
                                  'Hoje',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          _getMonthYear(selectedDate),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ALTERADO: ListView.builder para ScrollablePositionedList.builder
                  Expanded(
                    child: ScrollablePositionedList.builder(
                      itemScrollController: _itemScrollController,
                      itemPositionsListener: _itemPositionsListener,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: dates.length,
                      itemBuilder: (context, index) {
                        final date = dates[index];
                        final isToday = date == today;
                        final isSelected = date.year == selectedDate.year &&
                                           date.month == selectedDate.month &&
                                           date.day == selectedDate.day;
                        
                        bool showMonthSeparator = false;
                        if (index > 0) {
                          final previousDate = dates[index - 1];
                          showMonthSeparator = date.month != previousDate.month;
                        }
                        
                        return Row(
                          children: [
                            if (showMonthSeparator) ...[
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.grey.withOpacity(0.3),
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getMonthAbbreviation(date),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            GestureDetector(
                              onTap: () {
                                schedulesController.selectDate(date);
                              },
                              child: Container(
                                width: 60,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? primaryColor
                                      : isToday
                                          ? primaryColor.withOpacity(0.2)
                                          : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: !isSelected
                                      ? Border.all(
                                          color: isToday
                                              ? primaryColor
                                              : primaryColor.withOpacity(0.3),
                                          width: isToday ? 2 : 1,
                                        )
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
                                        color: isSelected
                                            ? Colors.white
                                            : isToday
                                                ? primaryColor
                                                : textColor.withOpacity(0.8),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('d').format(date),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : isToday
                                                ? primaryColor
                                                : textColor,
                                      ),
                                    ),
                                    if (isToday && !isSelected) ...[
                                      const SizedBox(height: 2),
                                      Container(
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: primaryColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              color: Colors.grey.withOpacity(0.2),
              margin: const EdgeInsets.only(top: 8),
            ),
          ],
        ),
      );
    });
  }

  String _getDayAbbreviation(DateTime date) {
    const days = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SAB', 'DOM'];
    return days[date.weekday - 1];
  }

  String _getMonthYear(DateTime date) {
    return DateFormat.yMMMM('pt_BR').format(date);
  }

  String _getMonthAbbreviation(DateTime date) {
    return DateFormat.MMM('pt_BR').format(date).toUpperCase();
  }
}