import 'package:flutter/material.dart';
import 'package:app_remedio/utils/constants.dart';

enum ToastType { success, error, warning, info }

class ToastService {
  static OverlayEntry? _currentToast;

  static void showToast({
    required BuildContext context,
    required String message,
    required ToastType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Remove toast anterior se existir
    _removeCurrentToast();

    // Cores e ícones baseados no tipo
    Color backgroundColor;
    IconData icon;
    
    switch (type) {
      case ToastType.success:
        backgroundColor = toastSuccessColor;
        icon = Icons.check_circle;
        break;
      case ToastType.error:
        backgroundColor = toastErrorColor;
        icon = Icons.error;
        break;
      case ToastType.warning:
        backgroundColor = toastWarningColor;
        icon = Icons.warning;
        break;
      case ToastType.info:
        backgroundColor = toastInfoColor;
        icon = Icons.info;
        break;
    }

    final overlay = Overlay.of(context);
    
    _currentToast = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_currentToast!);

    // Remove automaticamente após a duração
    Future.delayed(duration, () {
      _removeCurrentToast();
    });
  }

  static void _removeCurrentToast() {
    _currentToast?.remove();
    _currentToast = null;
  }

  // Métodos de conveniência
  static void showSuccess(BuildContext context, String message) {
    showToast(context: context, message: message, type: ToastType.success);
  }

  static void showError(BuildContext context, String message) {
    showToast(context: context, message: message, type: ToastType.error);
  }

  static void showWarning(BuildContext context, String message) {
    showToast(context: context, message: message, type: ToastType.warning);
  }

  static void showInfo(BuildContext context, String message) {
    showToast(context: context, message: message, type: ToastType.info);
  }
} 