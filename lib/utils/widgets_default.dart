import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_remedio/utils/constants.dart';

class WidgetsDefault {
  // Widget para seleção de data
  static Widget buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required bool isRequired,
    String? Function(DateTime?)? validator,
    bool isEnabled = true,
  }) {
    final Color contentColor = isEnabled ? primaryColor : Colors.grey.shade500;
    final Color textColorValue = isEnabled ? textColor : Colors.grey.shade500;
    final Color labelColor = isEnabled ? textColor : Colors.grey.shade400;
    final Color backgroundColorValue = isEnabled
        ? backgroundColor
        : Colors.grey.shade100;

    return FormField<DateTime>(
      initialValue: value,
      validator: validator,
      builder: (FormFieldState<DateTime> state) {
        final Color borderColor = state.hasError
            ? secondaryColor
            : (isEnabled ? textColor.withOpacity(0.3) : Colors.grey.shade300);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label${isRequired ? ' *' : ''}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: isEnabled ? onTap : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: backgroundColorValue,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: borderColor,
                    width: state.hasError ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: contentColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        value != null
                            ? DateFormat('dd/MM/yyyy').format(value)
                            : 'Selecionar data',
                        style: TextStyle(
                          color: value != null
                              ? textColorValue
                              : textColorValue.withValues(alpha: 0.7),
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (value != null)
                      Icon(Icons.check_circle, color: contentColor, size: 20),
                  ],
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 16),
                child: Text(
                  state.errorText!,
                  style: TextStyle(color: secondaryColor, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }

  // Widget para campo de texto
  static Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: heading2Style),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
            filled: true,
            fillColor: backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: textColor.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: secondaryColor, width: 2),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
