import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Standart uygulama kartı — koyu arka plan, ince kenarlık, subtle glow
class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final double borderRadius;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.borderRadius = 16,
    this.onTap,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final hasTap = widget.onTap != null;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      transform: Matrix4.identity()
        ..scale(_pressed && hasTap ? 0.975 : 1.0),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: _pressed && hasTap
              ? (widget.borderColor ?? AppColors.borderSubtle)
                  .withAlpha(160)
              : widget.borderColor ?? AppColors.borderSubtle,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: widget.padding ?? const EdgeInsets.all(20),
      child: widget.child,
    );

    if (hasTap) {
      return GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: card,
      );
    }
    return card;
  }
}
