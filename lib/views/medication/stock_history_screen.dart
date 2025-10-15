// arquivo: views/medication/stock_history_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:app_remedio/controllers/medication_controller.dart';
import 'package:app_remedio/models/stock_history_model.dart';
import 'package:app_remedio/utils/constants.dart';

// NOVO: Enum para os filtros de data predefinidos
enum DateFilterPreset {
  currentDay,
  currentMonth,
  last3Months,
  last6Months,
  currentYear,
}

class StockHistoryScreen extends StatefulWidget {
  const StockHistoryScreen({super.key});

  @override
  State<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends State<StockHistoryScreen> {
  final MedicationController _medicationController = Get.find();
  int? _selectedMedicationId;
  DateTime? _startDate;
  DateTime? _endDate;
  late Future<List<StockHistory>> _historyFuture;

  // NOVO: Estado para controlar o filtro rápido selecionado
  DateFilterPreset? _selectedPreset;

  @override
  void initState() {
    super.initState();
    // NOVO: Define o período inicial como o mês atual
    _applyDateFilterPreset(DateFilterPreset.currentMonth);
  }

  void _fetchHistory() {
    setState(() {
      _historyFuture = _medicationController.getStockHistory(
        medicationId: _selectedMedicationId,
        startDate: _startDate,
        endDate: _endDate,
      );
    });
  }

  // NOVO: Lógica para aplicar os filtros rápidos
  void _applyDateFilterPreset(DateFilterPreset preset) {
    final now = DateTime.now();
    DateTime newStartDate;
    DateTime newEndDate = now;

    switch (preset) {
      case DateFilterPreset.currentDay:
        newStartDate = DateTime(now.year, now.month, now.day);
        break;
      case DateFilterPreset.currentMonth:
        newStartDate = DateTime(now.year, now.month, 1);
        break;
      case DateFilterPreset.last3Months:
        newStartDate = DateTime(now.year, now.month - 3, now.day);
        break;
      case DateFilterPreset.last6Months:
        newStartDate = DateTime(now.year, now.month - 6, now.day);
        break;
      case DateFilterPreset.currentYear:
        newStartDate = DateTime(now.year, 1, 1);
        break;
    }

    setState(() {
      _startDate = newStartDate;
      _endDate = newEndDate;
      _selectedPreset = preset;
    });
    _fetchHistory();
  }

  Future<void> _pickDate({required bool isStartDate}) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 5, now.month, now.day);
    final lastDate = now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _startDate : _endDate) ?? lastDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('pt', 'BR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: surfaceColor,
              onSurface: textColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: primaryColor),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        // NOVO: Desmarca o preset ao escolher data manual
        _selectedPreset = null;

        if (isStartDate) {
          _startDate = pickedDate;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            23,
            59,
            59,
          );
          if (_startDate != null && _startDate!.isAfter(_endDate!)) {
            _startDate = pickedDate;
          }
        }
      });
      _fetchHistory();
    }
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return 'Hoje';
    } else if (date == yesterday) {
      return 'Ontem';
    } else {
      return DateFormat('d \'de\' MMMM \'de\' y', 'pt_BR').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Histórico de Estoque', style: heading2Style),
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterDropdown(),
          // NOVO: Adiciona os botões de filtro rápido
          _buildPresetFilters(),
          _buildDateFilterSelectors(),
          Expanded(
            child: FutureBuilder<List<StockHistory>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erro ao carregar histórico: ${snapshot.error}',
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final historyList = snapshot.data!;
                final Map<DateTime, List<StockHistory>> groupedHistory = {};
                for (var item in historyList) {
                  final dateKey = DateTime(
                    item.creationDate.year,
                    item.creationDate.month,
                    item.creationDate.day,
                  );
                  if (groupedHistory[dateKey] == null) {
                    groupedHistory[dateKey] = [];
                  }
                  groupedHistory[dateKey]!.add(item);
                }

                final sortedKeys = groupedHistory.keys.toList()
                  ..sort((a, b) => b.compareTo(a));

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    16,
                  ), // Ajuste de padding
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, index) {
                    final date = sortedKeys[index];
                    final itemsForDate = groupedHistory[date]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 16.0,
                            bottom: 8.0,
                            left: 4.0,
                          ),
                          child: Text(
                            _formatDateHeader(date),
                            style: heading2Style.copyWith(
                              fontSize: 16,
                              color: textColor.withOpacity(0.8),
                            ),
                          ),
                        ),
                        ...itemsForDate.map(
                          (item) => _buildHistoryItemCard(item),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Obx(() {
          final items = _medicationController.allMedications.map((med) {
            return DropdownMenuItem<int>(
              value: med.id,
              child: Text(med.nome, overflow: TextOverflow.ellipsis),
            );
          }).toList();

          items.insert(
            0,
            DropdownMenuItem<int>(
              value: null,
              child: Text(
                'Todos os Medicamentos',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          );

          return DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedMedicationId,
              isExpanded: true,
              dropdownColor: surfaceColor,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: textColor.withOpacity(0.7),
              ),
              style: bodyTextStyle,
              items: items,
              onChanged: (value) {
                setState(() {
                  _selectedMedicationId = value;
                  _fetchHistory();
                });
              },
            ),
          );
        }),
      ),
    );
  }

  // NOVO: Widget que constrói os filtros rápidos (ChoiceChip)
  Widget _buildPresetFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildPresetChip('Hoje', DateFilterPreset.currentDay),
            _buildPresetChip('Mês Atual', DateFilterPreset.currentMonth),
            _buildPresetChip('Últimos 3 Meses', DateFilterPreset.last3Months),
            _buildPresetChip('Últimos 6 Meses', DateFilterPreset.last6Months),
            _buildPresetChip('Ano Atual', DateFilterPreset.currentYear),
          ],
        ),
      ),
    );
  }

  // NOVO: Widget auxiliar para criar cada ChoiceChip
  Widget _buildPresetChip(String label, DateFilterPreset preset) {
    final isSelected = _selectedPreset == preset;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            _applyDateFilterPreset(preset);
          }
        },
        selectedColor: primaryColor.withOpacity(0.9),
        backgroundColor: surfaceColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : textColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(
            color: isSelected ? primaryColor : textColor.withOpacity(0.2),
          ),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildDateFilterSelectors() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _buildDateButton(
              label: 'De:',
              date: _startDate,
              onPressed: () => _pickDate(isStartDate: true),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildDateButton(
              label: 'Até:',
              date: _endDate,
              onPressed: () => _pickDate(isStartDate: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onPressed,
  }) {
    final displayDate = date != null
        ? DateFormat('dd/MM/yy').format(date)
        : 'Selecione';
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        Icons.calendar_today_outlined,
        size: 18,
        color: textColor.withOpacity(0.7),
      ),
      label: Text(
        '$label $displayDate',
        style: bodyTextStyle.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: surfaceColor,
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(
          color: _selectedPreset == null ? primaryColor : Colors.transparent,
          width: _selectedPreset == null ? 1.5 : 0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_outlined,
            size: 80,
            color: textColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text("Nenhuma movimentação", style: heading2Style),
          const SizedBox(height: 8),
          Text(
            "As reposições e usos de medicamentos\n neste período aparecerão aqui.",
            textAlign: TextAlign.center,
            style: bodyTextStyle.copyWith(color: textColor.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItemCard(StockHistory item) {
    final isEntry = item.type == StockMovementType.entrada;
    final color = isEntry ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final icon = isEntry
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;
    // Formata a quantidade para remover o ".0" se for um número inteiro
    final formattedQuantity = item.quantity == item.quantity.truncate()
        ? item.quantity.truncate().toString()
        : item.quantity.toString();
    final prefix = isEntry ? '+' : ''; // O sinal de menos já vem com o número

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          item.medicationName ?? 'Medicamento Desconhecido',
          style: bodyTextStyle.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Horário (como já estava)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                DateFormat('HH:mm').format(item.creationDate),
                style: bodyTextStyle.copyWith(
                  color: textColor.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
            ),
            // 2. Observação (só aparece se existir)
            if (item.observacao != null && item.observacao!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.comment_outlined,
                      size: 14,
                      color: textColor.withOpacity(0.5),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.observacao!,
                        style: bodyTextStyle.copyWith(
                          color: textColor.withOpacity(0.5),
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        trailing: Text(
          '$prefix$formattedQuantity',
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}
