import 'package:flutter/material.dart';

class ActionButtonModel {
  const ActionButtonModel({
    required this.onPressed,
    required this.icon,
    this.label,
    this.backgroundColor,
  });

  final VoidCallback onPressed;
  final Widget icon;
  final String? label;
  final Color? backgroundColor;
}
