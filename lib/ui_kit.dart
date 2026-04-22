/// ui_kit.dart — shared, reusable primitives used across every IMAS screen.
/// Import this instead of copy-pasting the same widgets everywhere.
library imas_ui_kit;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart';

// ── Design System ──────────────────────────────────────────────────────────────
class ImasColors {
  static const Color cyan = Color(0xFF00E5FF);
  static const Color cyanDark = Color(0xFF00B8D4);
  static const Color purple = Color(0xFF7C4DFF);
  static const Color purpleDark = Color(0xFF651FFF);
  static const Color orange = Color(0xFFFF9F43);
  static const Color orangeDark = Color(0xFFFF6348);
  static const Color green = Color(0xFF00E676);
  static const Color greenDark = Color(0xFF00C853);
  static const Color red = Color(0xFFFF3D5A);
  
  static const Color darkBg = Color(0xFF050A12);
  static const Color darkSurface = Color(0xFF0C1420);
  static const Color darkBorder = Color(0xFF1A2535);

  static const List<Color> brandGradient = [cyan, Color(0xFF007685)];
  static const List<Color> purpleGradient = [purple, Color(0xFF6200EA)];
}

class ImasSpacing {
  static const EdgeInsets screenPadding = EdgeInsets.all(24.0);
}

// ── Section title ──────────────────────────────────────────────────────────────
class ImasSectionTitle extends StatelessWidget {
  final String text;
  final Color color;
  final Widget? trailing;

  const ImasSectionTitle(this.text, {super.key, required this.color, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 3,
        height: 14,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            color: color.withAlpha(200),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
      if (trailing != null) trailing!,
    ]);
  }
}

// ── Gradient button ────────────────────────────────────────────────────────────
class ImasGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final List<Color> colors;
  final Color shadowColor;
  final bool loading;
  final IconData? icon;
  final double height;

  const ImasGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.colors = ImasColors.brandGradient,
    Color? shadowColor,
    this.loading = false,
    this.icon,
    this.height = 58,
  }) : shadowColor = shadowColor ?? colors[0];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(colors: colors),
          boxShadow: onPressed == null
              ? []
              : [
                  BoxShadow(
                    color: shadowColor.withAlpha(50),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: Colors.white38,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        fontSize: 14,
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: 10),
                      Icon(icon, size: 18),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Outlined glass button ──────────────────────────────────────────────────────
class ImasOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color accentColor;
  final double height;

  const ImasOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.accentColor,
    this.height = 58,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white.withAlpha(8),
              foregroundColor: accentColor,
              side: BorderSide(color: accentColor.withAlpha(60)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Status badge ───────────────────────────────────────────────────────────────
class ImasStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool pulsing;
  final AnimationController? pulseCtrl;

  const ImasStatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.pulsing = false,
    this.pulseCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );

    if (!pulsing || pulseCtrl == null) return badge;

    return AnimatedBuilder(
      animation: pulseCtrl!,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withAlpha(10 + (pulseCtrl!.value * 12).toInt()),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error banner ───────────────────────────────────────────────────────────────
class ImasErrorBanner extends StatelessWidget {
  final String message;

  const ImasErrorBanner(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ImasColors.red.withAlpha(10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ImasColors.red.withAlpha(30)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: ImasColors.red.withAlpha(15),
            ),
            child: const Icon(Icons.error_outline_rounded,
                color: ImasColors.red, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: ImasColors.red,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Glow orb ───────────────────────────────────────────────────────────────────
class ImasGlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const ImasGlowOrb(this.size, this.color, this.opacity, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withAlpha((opacity * 255).toInt()),
            color.withAlpha((opacity * 80).toInt()),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

// ── Fade + slide animation wrapper ────────────────────────────────────────────
class FadeSlide extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  final double offsetY;

  const FadeSlide({
    super.key,
    required this.animation,
    required this.child,
    this.offsetY = 18,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) => Opacity(
        opacity: animation.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, offsetY * (1 - animation.value)),
          child: child,
        ),
      ),
    );
  }
}

// ── Icon button (back / settings) ─────────────────────────────────────────────
class ImasIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;
  final Color bgColor;

  const ImasIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: bgColor,
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
    );
  }
}

// ── Labelled form field ───────────────────────────────────────────────────────
class ImasFormField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final Color panelColor;
  final Color borderColor;
  final Color accentColor;
  final Color textColor;
  final Color labelColor;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool readOnly;
  final FocusNode? focusNode;

  const ImasFormField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    required this.panelColor,
    required this.borderColor,
    required this.accentColor,
    required this.textColor,
    required this.labelColor,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.validator,
    this.readOnly = false,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          readOnly: readOnly,
          style: TextStyle(
            color: readOnly ? labelColor : textColor,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: labelColor.withAlpha(80)),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Icon(icon, color: labelColor.withAlpha(150), size: 20),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: suffix != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 12), child: suffix)
                : readOnly
                    ? Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(Icons.lock_rounded,
                            color: labelColor.withAlpha(80), size: 14),
                      )
                    : null,
            filled: true,
            fillColor: panelColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: accentColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: ImasColors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: ImasColors.red, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
        ),
      ],
    );
  }
}

// ── Page route helper ──────────────────────────────────────────────────────────
Route<T> imasRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: const Duration(milliseconds: 450),
    reverseTransitionDuration: const Duration(milliseconds: 350),
    transitionsBuilder: (_, anim, __, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );
    },
  );
}

// ── Mini stat card ─────────────────────────────────────────────────────────────
class ImasStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color panelColor;
  final Color borderColor;
  final Color textColor;
  final Color subtextColor;
  final bool isDark;

  const ImasStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.panelColor,
    required this.borderColor,
    required this.textColor,
    required this.subtextColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 10 : 4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: color.withAlpha(15),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subtextColor,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}