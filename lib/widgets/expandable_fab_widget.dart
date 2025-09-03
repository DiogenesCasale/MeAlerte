import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:app_remedio/models/action_button_model.dart';
import 'package:app_remedio/utils/constants.dart';
import 'package:app_remedio/controllers/theme_controller.dart';

@immutable
class ExpandableFab extends StatefulWidget {
  const ExpandableFab({
    super.key,
    this.initialOpen,
    required this.distance,
    required this.children,
  });

  final bool? initialOpen;
  final double distance;
  final List<ActionButtonModel> children;

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _open = widget.initialOpen ?? false;
    _controller = AnimationController(
      value: _open ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          _buildTapToCloseFab(),
          ..._buildExpandingActionButtons(),
          _buildTapToOpenFab(),
        ],
      ),
    );
  }

  Widget _buildTapToCloseFab() {
    final themeController = Get.find<ThemeController>();
    return Obx(() {
      // Forçar rebuild quando tema muda
      themeController.isDarkMode.value;
      
      return SizedBox(
        width: 56.0,
        height: 56.0,
        child: Center(
          child: Material(
            color: surfaceColor,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            elevation: 4.0,
            child: InkWell(
              onTap: _toggle,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.close, color: primaryColor),
              ),
            ),
          ),
        ),
      );
    });
  }

  List<Widget> _buildExpandingActionButtons() {
    final children = <Widget>[];
    final count = widget.children.length;
    final step = 90.0 / (count > 1 ? count - 1 : 1);
    for (var i = 0, angleInDegrees = 90.0; i < count; i++, angleInDegrees += step) {
      children.add(
        _ExpandingActionButton(
          directionInDegrees: angleInDegrees,
          maxDistance: widget.distance,
          progress: _expandAnimation,
          onTap: () {
            // Fecha o menu ao clicar em uma opção
            _toggle();
            // Executa a ação do botão
            widget.children[i].onPressed();
          },
          child: widget.children[i],
        ),
      );
    }
    return children;
  }

  Widget _buildTapToOpenFab() {
    final themeController = Get.find<ThemeController>();
    return Obx(() {
      // Forçar rebuild quando tema muda
      themeController.isDarkMode.value;
      
      return IgnorePointer(
        ignoring: _open,
        child: AnimatedContainer(
          transformAlignment: Alignment.center,
          transform: Matrix4.diagonal3Values(_open ? 0.7 : 1.0, _open ? 0.7 : 1.0, 1.0),
          duration: const Duration(milliseconds: 250),
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
          child: AnimatedOpacity(
            opacity: _open ? 0.0 : 1.0,
            curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
            duration: const Duration(milliseconds: 250),
            child: FloatingActionButton(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              onPressed: _toggle,
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );
    });
  }
}

@immutable
class _ExpandingActionButton extends StatelessWidget {
  const _ExpandingActionButton({
    required this.directionInDegrees,
    required this.maxDistance,
    required this.progress,
    required this.child,
    required this.onTap,
  });

  final double directionInDegrees;
  final double maxDistance;
  final Animation<double> progress;
  final ActionButtonModel child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final pos = Offset.fromDirection(
          directionInDegrees * (math.pi / 180.0),
          progress.value * maxDistance,
        );
        return Positioned(
          right: 4.0 + pos.dx,
          bottom: 4.0 + pos.dy,
          child: Opacity(
            opacity: progress.value,
            child: InkWell(
              onTap: onTap,
              child: Row(
                children: [
                  if (child.label != null)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                      margin: const EdgeInsets.only(right: 8.0),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(4.0),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 4.0,
                            color: Colors.black.withValues(alpha: 0.25),
                          )
                        ],
                      ),
                      child: Text(
                        child.label!,
                        style: TextStyle(color: textColor),
                      ),
                    ),
                  FloatingActionButton.small(
                    heroTag: null,
                    backgroundColor: child.backgroundColor,
                    onPressed: null, // A ação é tratada pelo InkWell
                    child: child.icon,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
