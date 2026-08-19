import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/gold_button.dart';
import 'setup_screen.dart';

/// صفحه‌ی پایان بازی - افقی (هم‌راستا با صفحه‌ی بازی)، سوار بر عکس پس‌زمینه‌ی
/// «پایان بازی». مختصات هر بخش با تحلیل پیکسلی دقیق از روی خود عکس استخراج شده:
/// - تابلوی چوبی خالی بالا: اسم برنده
/// - حلقه‌ی طلایی: آواتار برنده
/// - روبان طلایی خالی: امتیاز برنده
/// - کادر کرمی سمت راست: نفر دوم، سوم (احتمالاً مشترک) و بقیه‌ی بازیکنان
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    // هم‌راستا با صفحه‌ی بازی، این صفحه هم افقی است (عکس پس‌زمینه‌اش افقی طراحی شده)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _confettiController.play();
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final results = game.results;

    final first = results.where((r) => r.rank == 1).toList();
    final second = results.where((r) => r.rank == 2).toList();
    final third = results.where((r) => r.rank == 3).toList();
    final rest = results.where((r) => r.rank > 3).toList();

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            return Stack(
              fit: StackFit.expand,
              children: [
                Image.asset('assets/images/bg_result_forest.png', fit: BoxFit.fill),

                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirection: pi / 2,
                    emissionFrequency: 0.06,
                    numberOfParticles: 14,
                    maxBlastForce: 18,
                    minBlastForce: 8,
                    gravity: 0.25,
                    colors: const [AppColors.gold, AppColors.brightGold, Colors.white],
                  ),
                ),

                // تابلوی خالی بالا: اسم برنده
                if (first.isNotEmpty)
                  Positioned(
                    left: 0.166 * w,
                    top: 0.079 * h,
                    width: 0.275 * w,
                    height: 0.139 * h,
                    child: Center(
                      child: Text(
                        first.first.player.name,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontWeight: FontWeight.w900,
                          fontSize: 0.022 * w,
                          color: const Color(0xFFFFF3D0),
                          shadows: const [Shadow(color: Colors.black54, blurRadius: 3)],
                        ),
                      ),
                    ),
                  ),

                // حلقه‌ی طلایی: آواتار برنده
                if (first.isNotEmpty)
                  Positioned(
                    left: 0.208 * w,
                    top: 0.349 * h,
                    width: 0.161 * w,
                    height: 0.244 * h,
                    child: Center(
                      child: Container(
                        width: 0.12 * w,
                        height: 0.12 * w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: first.first.player.avatarColor,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          first.first.player.name.isNotEmpty ? first.first.player.name[0] : '',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontWeight: FontWeight.w900,
                            fontSize: 0.05 * w,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ),
                  ),

                // روبان طلایی خالی: امتیاز برنده
                if (first.isNotEmpty)
                  Positioned(
                    left: 0.170 * w,
                    top: 0.595 * h,
                    width: 0.233 * w,
                    height: 0.112 * h,
                    child: Center(
                      child: Text(
                        '${first.first.player.score}',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontWeight: FontWeight.w900,
                          fontSize: 0.032 * w,
                          color: const Color(0xFF5C3A00),
                        ),
                      ),
                    ),
                  ),

                // پیام «برنده به دلیل کمترین اشتباه» - زیر روبان/شیلد، در فضای باقی‌مانده
                if (first.isNotEmpty && first.first.wonByFewerMistakes)
                  Positioned(
                    left: 0.166 * w,
                    top: 0.875 * h,
                    width: 0.275 * w,
                    child: Text(
                      'برنده به دلیل کمترین اشتباه',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontWeight: FontWeight.w700,
                        fontSize: 0.014 * w,
                        color: AppColors.brightGold,
                        shadows: const [Shadow(color: Colors.black87, blurRadius: 4)],
                      ),
                    ),
                  ),

                // کادر کرمی سمت راست: نفر دوم، سوم، و بقیه
                Positioned(
                  left: 0.510 * w,
                  top: 0.235 * h,
                  width: 0.374 * w,
                  height: 0.60 * h,
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: 0.02 * w),
                    children: [
                      if (second.isNotEmpty)
                        _RankRow(result: second.first, label: 'نفر دوم', w: w),
                      if (third.isNotEmpty) ...[
                        SizedBox(height: 0.012 * h),
                        _RankRow(
                          result: third.first,
                          label: third.length > 1 ? 'نفر سوم (مشترک)' : 'نفر سوم',
                          w: w,
                        ),
                        if (third.length > 1)
                          ...third.skip(1).map((r) => Padding(
                                padding: EdgeInsets.only(top: 0.006 * h),
                                child: _RankRow(result: r, label: 'نفر سوم (مشترک)', w: w, compact: true),
                              )),
                      ],
                      if (rest.isNotEmpty) ...[
                        SizedBox(height: 0.014 * h),
                        Divider(color: Colors.brown.withOpacity(0.3)),
                        ...rest.map((r) => Padding(
                              padding: EdgeInsets.symmetric(vertical: 0.004 * h),
                              child: _RankRow(result: r, label: null, w: w, compact: true),
                            )),
                      ],
                    ],
                  ),
                ),

                // دکمه بازگشت - پایین صفحه، وسط
                Positioned(
                  bottom: 0.02 * h,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GoldButton(
                      text: 'بازگشت به ساخت محیط بازی',
                      height: 0.08 * h,
                      fontSize: 0.016 * w,
                      onPressed: () {
                        game.resetGame();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const SetupScreen()),
                          (route) => route.isFirst,
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final PlayerResult result;
  final String? label;
  final double w;
  final bool compact;

  const _RankRow({required this.result, required this.label, required this.w, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 0.012 * w, vertical: compact ? 0.006 * w : 0.01 * w),
      decoration: BoxDecoration(
        color: compact ? Colors.transparent : Colors.brown.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: compact ? 8 : 11, backgroundColor: result.player.avatarColor),
          SizedBox(width: 0.01 * w),
          Expanded(
            child: Text(
              result.player.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontWeight: compact ? FontWeight.w500 : FontWeight.w700,
                fontSize: compact ? 0.013 * w : 0.015 * w,
                color: const Color(0xFF4A3418),
              ),
            ),
          ),
          if (label != null)
            Padding(
              padding: EdgeInsets.only(left: 0.01 * w),
              child: Text(
                label!,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 0.011 * w,
                  color: const Color(0xFF7A5A2E),
                ),
              ),
            ),
          Text(
            '${result.player.score}',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontWeight: FontWeight.w900,
              fontSize: compact ? 0.013 * w : 0.016 * w,
              color: const Color(0xFFB8860B),
            ),
          ),
        ],
      ),
    );
  }
}
