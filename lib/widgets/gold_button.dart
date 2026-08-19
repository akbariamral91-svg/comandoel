import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// دکمه طلایی لاکچری با افکت درخشش و فشرده‌شدن هنگام کلیک
class GoldButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final double? width;
  final double height;
  final double fontSize;
  final bool outlined;

  const GoldButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.width,
    this.height = 56,
    this.fontSize = 18,
    this.outlined = false,
  });

  @override
  State<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<GoldButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.width,
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            gradient: widget.outlined ? null : AppColors.goldGradient,
            color: widget.outlined ? Colors.transparent : null,
            border: widget.outlined
                ? Border.all(color: AppColors.gold, width: 1.5)
                : null,
            borderRadius: BorderRadius.circular(widget.height / 2),
            boxShadow: widget.outlined
                ? []
                : [
                    BoxShadow(
                      color: AppColors.brightGold.withOpacity(0.45),
                      blurRadius: _pressed ? 8 : 18,
                      spreadRadius: _pressed ? 0 : 1,
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon,
                    color: widget.outlined ? AppColors.gold : AppColors.black,
                    size: widget.fontSize + 2),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontWeight: FontWeight.w700,
                    fontSize: widget.fontSize,
                    color: widget.outlined ? AppColors.gold : AppColors.black,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// دکمه دایره‌ای کوچک طلایی (برای تنظیمات، پشتیبانی، شاپ)
class GoldIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;

  const GoldIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.charcoal,
          border: Border.all(color: AppColors.gold, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withOpacity(0.3),
              blurRadius: 10,
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.gold, size: size * 0.5),
      ),
    );
  }
}
