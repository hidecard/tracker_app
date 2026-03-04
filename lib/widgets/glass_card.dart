import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? width;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.borderRadius = 16,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: backgroundColor ?? Colors.white,
          border: Border.all(
            color: borderColor ?? Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: padding != null
              ? Padding(padding: padding!, child: child)
              : child,
        ),
      ),
    );
  }
}

class GradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;
  final List<Color> gradientColors;
  final List<BoxShadow>? boxShadow;

  const GradientCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16,
    this.gradientColors = const [Color(0xFF0077B6), Color(0xFF87CEEB)],
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: gradientColors.first.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}

class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: backgroundColor ?? Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: padding != null
              ? Padding(padding: padding!, child: child)
              : child,
        ),
      ),
    );
  }
}

