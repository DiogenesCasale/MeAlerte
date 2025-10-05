// arquivo: views/medication/stock_history_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:app_remedio/controllers/medication_controller.dart';
import 'package:app_remedio/models/stock_history_model.dart';
import 'package:app_remedio/utils/constants.dart';

class StockHistoryScreen extends StatefulWidget {
  const StockHistoryScreen({super.key});

  @override
  State<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends State<StockHistoryScreen> {
  final MedicationController _medicationController = Get.find();
  int? _selectedMedicationId;
  late Future<List<StockHistory>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  void _fetchHistory() {
    setState(() {
      _historyFuture = _medicationController.getStockHistory(
        medicationId: _selectedMedicationId,
      );
    });
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
          Expanded(
            child: FutureBuilder<List<StockHistory>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: primaryColor));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erro ao carregar histórico: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final historyList = snapshot.data!;
                
                // --- MUDANÇA AQUI: LÓGICA DE AGRUPAMENTO MANUAL ---
                final Map<DateTime, List<StockHistory>> groupedHistory = {};
                for (var item in historyList) {
                  // Cria uma chave de data sem a informação de hora/minuto
                  final dateKey = DateTime(item.creationDate.year, item.creationDate.month, item.creationDate.day);
                  
                  // Se a chave ainda não existe no mapa, cria uma lista vazia para ela
                  if (groupedHistory[dateKey] == null) {
                    groupedHistory[dateKey] = [];
                  }
                  
                  // Adiciona o item à lista correspondente à sua data
                  groupedHistory[dateKey]!.add(item);
                }
                // --- FIM DA LÓGICA MANUAL ---

                final sortedKeys = groupedHistory.keys.toList()..sort((a, b) => b.compareTo(a));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, index) {
                    final date = sortedKeys[index];
                    final itemsForDate = groupedHistory[date]!;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 24.0, bottom: 8.0, left: 4.0),
                          child: Text(
                            _formatDateHeader(date),
                            style: heading2Style.copyWith(fontSize: 16, color: textColor.withOpacity(0.8)),
                          ),
                        ),
                        ...itemsForDate.map((item) => _buildHistoryItemCard(item)),
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
                style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
              ),
            ),
          );

          return DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedMedicationId,
              isExpanded: true,
              dropdownColor: surfaceColor,
              icon: Icon(Icons.keyboard_arrow_down, color: textColor.withOpacity(0.7)),
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
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_outlined, size: 80, color: textColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text("Nenhuma movimentação", style: heading2Style),
          const SizedBox(height: 8),
          Text(
            "As reposições e usos de medicamentos\n aparecerão aqui.",
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
    final icon = isEntry ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
    final prefix = isEntry ? '+' : '-';

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
          style: bodyTextStyle.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            DateFormat('HH:mm').format(item.creationDate),
            style: bodyTextStyle.copyWith(color: textColor.withOpacity(0.6), fontSize: 13),
          ),
        ),
        trailing: Text(
          '$prefix${item.quantity}',
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