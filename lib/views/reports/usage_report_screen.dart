import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:app_remedio/controllers/medication_controller.dart';
import 'package:app_remedio/models/stock_history_model.dart';
import 'package:app_remedio/utils/constants.dart';

class UsageReportScreen extends StatelessWidget {
  const UsageReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final medicationController = Get.find<MedicationController>();

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      body: Obx(() {
        if (medicationController.isLoading.value) {
          return Center(child: CircularProgressIndicator(color: primaryColor));
        }

        if (medicationController.allMedications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.medication_outlined,
                  size: 64,
                  color: textColor.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhum medicamento cadastrado',
                  style: bodyTextStyle.copyWith(
                    color: textColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: medicationController.allMedications.length,
          itemBuilder: (context, index) {
            final medication = medicationController.allMedications[index];
            return FutureBuilder<double>(
              future: medicationController.getDaysRemaining(medication.id!),
              builder: (context, snapshot) {
                final daysRemaining = snapshot.data ?? double.infinity;
                return _buildUsageCard(medication, daysRemaining);
              },
            );
          },
        );
      }),
    );
  }

  Widget _buildUsageCard(dynamic medication, double daysRemaining) {
    final isLow = daysRemaining < 7;
    final daysText = daysRemaining == double.infinity
        ? 'Uso não contínuo'
        : daysRemaining < 1
        ? 'Menos de 1 dia'
        : '${daysRemaining.toStringAsFixed(1)} dias';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: textColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Imagem do medicamento (se houver)
                if (medication.caminhoImagem != null &&
                    medication.caminhoImagem!.isNotEmpty)
                  Container(
                    width: 48,
                    height: 48,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: backgroundColor,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(medication.caminhoImagem!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.medication,
                          color: textColor.withOpacity(0.3),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 48,
                    height: 48,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: backgroundColor,
                    ),
                    child: Icon(
                      Icons.medication,
                      color: textColor.withOpacity(0.3),
                    ),
                  ),

                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.nome,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Estoque atual: ${medication.estoque.toStringAsFixed(0)}',
                        style: subtitleTextStyle,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isLow
                        ? Colors.red.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timelapse,
                        size: 14,
                        color: isLow ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        daysText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isLow ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Divider(height: 1, color: textColor.withOpacity(0.1)),
          // Botão para ver histórico
          InkWell(
            onTap: () {
              _showHistoryModal(medication.id!);
            },
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ver Histórico de Movimentações',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: primaryColor, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHistoryModal(int medicationId) {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.7,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Histórico de Estoque',
                    style: heading2Style.copyWith(fontSize: 18),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(Icons.close, color: textColor),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: textColor.withOpacity(0.1)),
            Expanded(
              child: FutureBuilder<List<StockHistory>>(
                future: Get.find<MedicationController>().getStockHistory(
                  medicationId: medicationId,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        'Nenhum histórico encontrado',
                        style: subtitleTextStyle,
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final history = snapshot.data![index];
                      final isEntry = history.type == StockMovementType.entrada;

                      final formattedQuantity =
                          history.quantity == history.quantity.truncate()
                          ? history.quantity.truncate().toString()
                          : history.quantity.toString().replaceAll('.', ',');
                      final prefix = isEntry
                          ? '+'
                          : history.quantity < 0
                          ? ''
                          : '-';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isEntry
                                ? Colors.green.withOpacity(0.3)
                                : Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isEntry
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isEntry
                                    ? Icons.add_circle_outline
                                    : Icons.remove_circle_outline,
                                color: isEntry ? Colors.green : Colors.red,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEntry ? 'Entrada de Estoque' : 'Consumo',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat(
                                      'dd/MM/yyyy HH:mm',
                                    ).format(history.creationDate),
                                    style: subtitleTextStyle.copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${prefix}${formattedQuantity}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isEntry ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
