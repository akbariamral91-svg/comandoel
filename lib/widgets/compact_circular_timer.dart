import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// تایمر دایره‌ای شمارش معکوس: عددِ وسط دایره خودِ تایمر است و نوار طلایی
/// دور آن هرچه زمان می‌گذرد کوتاه‌تر می‌شود (شروع از بالا، چرخش ساعت‌گرد).
class CompactCircularTimer extends StatelessWidget {
  final int secondsRemaining;
  final double progress; // 1.0 -> کامل، 0.0 -> تمام‌شده
  final double size;

  const CompactCircularTimer({
    super.key,
    required this.secondsRemaining,
    required this.progress,
    this.size = 72,
  });

  Color get _color {
    if (progress > 0.5) return AppColors.brightGold;
    if (progress > 0.25) return const Color(0xFFFFA726);
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final strokeW = (size * 0.10).clamp(5.5, 9.0);
    final badgeSize = size * 0.32;

    return SizedBox(
      width: size,
      height: size + badgeSize * 0.55,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // مدار پس‌زمینه‌ی کم‌رنگ
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: strokeW,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.10)),
            ),
          ),
          // کمان طلایی که با گذشت زمان کوتاه می‌شود
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _TimerArcPainter(
                progress: progress.clamp(0.0, 1.0),
                color: _color,
                strokeWidth: strokeW,
              ),
            ),
          ),
          // دایره‌ی داخلی تیره + عدد شمارش معکوس
          Container(
            width: size - strokeW * 2.4,
            height: size - strokeW * 2.4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [AppColors.charcoal, AppColors.black],
                radius: 0.9,
              ),
              border: Border.all(color: _color.withValues(alpha: 0.55), width: 1.4),
              boxShadow: [
                BoxShadow(color: _color.withValues(alpha: 0.38), blurRadius: 12, spreadRadius: 1),
                const BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 3)),
              ],
            ),
            alignment: Alignment.center,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontWeight: FontWeight.w900,
                fontSize: size * 0.38,
                color: _color,
                shadows: [Shadow(color: _color.withValues(alpha: 0.5), blurRadius: 10)],
              ),
              child: Text('$secondsRemaining'),
            ),
          ),
          // نشان زنگ ساعت، کمی روی لبه‌ی بالایی دایره سوار می‌شود
          Positioned(
            top: -badgeSize * 0.42,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.charcoal,
                border: Border.all(color: AppColors.gold, width: 1.3),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: Icon(Icons.alarm_rounded, color: AppColors.brightGold, size: badgeSize * 0.62),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _TimerArcPainter({required this.progress, required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi * progress,
        colors: [AppColors.brightGold, color],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, paint);
  }

  @override
  bool shouldRepaint(covariant _TimerArcPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
