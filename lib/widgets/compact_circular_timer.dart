import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// نسخه‌ی دایره‌ای و جمع‌وجور تایمر - برای جا شدن داخل گودی کاراکتر علامت‌سوال
class CompactCircularTimer extends StatelessWidget {
  final int secondsRemaining;
  final double progress;
  final double size;

  const CompactCircularTimer({
    super.key,
    required this.secondsRemaining,
    required this.progress,
    this.size = 72,
  });

  Color get _color {
    if (progress > 0.5) return AppColors.brightGold;
    if (progress > 0.25) return const Color(0xFFFFA500);
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: 6,
              backgroundColor: AppColors.charcoal.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation<Color>(_color),
            ),
          ),
          Container(
            width: (size - 20).clamp(0.0, size),
            height: (size - 20).clamp(0.0, size),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.black.withValues(alpha: 0.55),
            ),
            alignment: Alignment.center,
            child: Text(
              '$secondsRemaining',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontWeight: FontWeight.w900,
                fontSize: size * 0.32,
                color: _color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
