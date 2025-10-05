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
    this.heroTag,
  });

  final bool? initialOpen;
  final double distance;
  final List<ActionButtonModel> children;
  final String? heroTag;

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
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
          if (_open) _buildTapToCloseFab(),
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
      themeController.isDarkMode;

      return AnimatedOpacity(
        opacity: _open ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: FloatingActionButton(
          heroTag: widget.heroTag,
          backgroundColor: surfaceColor,
          foregroundColor: primaryColor,
          onPressed: _toggle,
          child: const Icon(Icons.close),
        ),
      );
    });
  }

List<Widget> _buildExpandingActionButtons() {
  final children = <Widget>[];
  for (var i = 0; i < widget.children.length; i++) {
    children.add(
      _ExpandingActionButton(
        index: i, // <-- Passando o índice do botão
        itemCount: widget.children.length, // <-- Passando o total de itens
        progress: _expandAnimation,
        onTap: () {
          _toggle();
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
      themeController.isDarkMode;

      return IgnorePointer(
        ignoring: _open,
        child: AnimatedContainer(
          transformAlignment: Alignment.center,
          transform: Matrix4.diagonal3Values(
            _open ? 0.7 : 1.0,
            _open ? 0.7 : 1.0,
            1.0,
          ),
          duration: const Duration(milliseconds: 250),
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
          child: AnimatedOpacity(
            opacity: _open ? 0.0 : 1.0,
            curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
            duration: const Duration(milliseconds: 250),
            child: FloatingActionButton(
              heroTag: widget.heroTag,
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
// Substitua toda a classe _ExpandingActionButton

@immutable
class _ExpandingActionButton extends StatelessWidget {
  const _ExpandingActionButton({
    required this.index,
    required this.itemCount,
    required this.progress,
    required this.child,
    required this.onTap,
  });

  final int index;
  final int itemCount;
  final Animation<double> progress;
  final ActionButtonModel child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        // Distância vertical entre o centro de cada botão
        const double buttonSpacing = 68.0; 
        // Distância inicial do primeiro botão em relação ao FAB principal
        const double initialOffset = 65.0; 

        // Calcula a posição vertical para este botão específico
        // Multiplicamos o espaçamento pelo índice e adicionamos o offset inicial
        final bottomPosition = initialOffset + (buttonSpacing * index);
        
        // Aplica a animação à posição calculada
        final animatedBottom = progress.value * bottomPosition;

        return Positioned(
          bottom: animatedBottom,
          right: 0, // Um pequeno ajuste para centralizar com o FAB
          child: Opacity(
            opacity: progress.value,
            child: Transform.scale(
              scale: progress.value,
              alignment: Alignment.center,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (child.label != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 12.0),
                          margin: const EdgeInsets.only(right: 16.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(8.0),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 4.0,
                                color: Colors.black.withOpacity(0.15),
                                offset: const Offset(0, 1),
                              )
                            ],
                          ),
                          child: Text(
                            child.label!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      FloatingActionButton(
                        heroTag: null,
                        backgroundColor: child.backgroundColor,
                        onPressed: onTap,
                        child: child.icon,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}