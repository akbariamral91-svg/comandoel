import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/gold_button.dart';
import 'setup_screen.dart';

/// نتیجه نهایی بازی.
///
/// این صفحه عمداً هیچ جدول یا جایگاه رتبه‌بندی را داخل تصویر پس‌زمینه نمی‌گذارد.
/// فقط خود جنگل از assets/images/bg_result_forest.png خوانده می‌شود و تمام UI با
/// Flutter ساخته می‌شود تا روی اندازه‌های مختلف گوشی responsive بماند.
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    // نتیجه نهایی مثل بقیه صفحات غیر از صفحه سوالات، عمودی است.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // موسیقی پس‌زمینه دیگر اینجا پخش نمی‌شود؛ فقط در Home و Setup پخش می‌شود.

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _startNewGame(BuildContext context) {
    final game = context.read<GameProvider>();
    game.resetGame();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SetupScreen()),
      (route) => false,
    );
  }

  void _exitToSetup(BuildContext context) {
    final game = context.read<GameProvider>();
    game.resetGame();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SetupScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final results = List<PlayerResult>.from(game.results);

    // نتیجه‌ها از قبل توسط GameProvider مرتب شده‌اند؛ برای اطمینان، دوباره بر اساس
    // امتیاز کل و سپس تعداد اشتباه مرتب می‌کنیم تا UI مستقل از ترتیب لیست باشد.
    results.sort((a, b) {
      if (game.goldenWinnerId != null) {
        if (a.player.id == game.goldenWinnerId) return -1;
        if (b.player.id == game.goldenWinnerId) return 1;
      }
      if (b.player.score != a.player.score) {
        return b.player.score.compareTo(a.player.score);
      }
      return a.player.totalWrongAnswers.compareTo(b.player.totalWrongAnswers);
    });

    final winner = results.isEmpty ? null : results.first;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final shortest = min(w, h);
            final horizontal = (w * 0.055).clamp(14.0, 28.0);
            final titleSize = (shortest * 0.075).clamp(26.0, 38.0);
            final rowHeight = (h * 0.065).clamp(48.0, 68.0);
            const buttonHeight = AppTheme.primaryButtonHeight;

            return Stack(
              fit: StackFit.expand,
              children: [
                // کاربر می‌تواند همین فایل را با پس‌زمینه جدید خودش جایگزین کند.
                // BoxFit.cover نسبت تصویر را حفظ می‌کند و تصویر را نمی‌کِشد.
                Image.asset(
                  'assets/images/bg_result_forest.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
                Container(color: Colors.black.withValues(alpha: 0.18)),

                // دکمه خروج: گوشه بالا چپ.
                Positioned(
                  top: 8,
                  left: 8,
                  child: GoldIconButton(
                    icon: Icons.close_rounded,
                    size: AppTheme.minTouchTarget,
                    onPressed: () => _showExitDialog(context),
                  ),
                ),

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
                    colors: const [
                      AppColors.gold,
                      AppColors.brightGold,
                      Colors.white,
                    ],
                  ),
                ),

                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontal,
                    (h * 0.025).clamp(14.0, 24.0),
                    horizontal,
                    (h * 0.035).clamp(20.0, 32.0),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: h - 30),
                    child: Column(
                      children: [
                        SizedBox(height: (h * 0.035).clamp(20.0, 34.0)),
                        Text(
                          'پایان بازی',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontWeight: FontWeight.w900,
                            fontSize: titleSize,
                            color: Colors.white,
                            shadows: const [
                              Shadow(color: Colors.black87, blurRadius: 8),
                            ],
                          ),
                        ),
                        SizedBox(height: (h * 0.014).clamp(8.0, 14.0)),

                        if (winner != null)
                          _WinnerCard(
                            result: winner,
                            width: double.infinity,
                            shortest: shortest,
                          ),

                        SizedBox(height: (h * 0.018).clamp(10.0, 18.0)),

                        // جدول واقعی Flutter؛ تعداد بازیکن می‌تواند از ۲ تا ۱۰ باشد.
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4E4BD).withValues(alpha: 0.97),
                            borderRadius: BorderRadius.circular(
                              (shortest * 0.045).clamp(12.0, 18.0),
                            ),
                            border: Border.all(
                              color: const Color(0xFFC18A27),
                              width: (shortest * 0.008).clamp(1.5, 2.5),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 14,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(
                            (shortest * 0.026).clamp(9.0, 16.0),
                          ),
                          child: Column(
                            children: [
                              _ResultHeader(shortest: shortest),
                              SizedBox(height: (h * 0.008).clamp(4.0, 8.0)),
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: const Color(0xFF6C4A20)
                                    .withValues(alpha: 0.35),
                              ),
                              SizedBox(height: (h * 0.005).clamp(3.0, 6.0)),
                              ...List.generate(results.length, (index) {
                                return _ResultRow(
                                  result: results[index],
                                  rank: index + 1,
                                  height: rowHeight,
                                  shortest: shortest,
                                );
                              }),
                            ],
                          ),
                        ),

                        SizedBox(height: (h * 0.022).clamp(12.0, 20.0)),

                        // بازی دوباره: دکمه اصلی پایین صفحه.
                        SizedBox(
                          width: (w * 0.78).clamp(220.0, 360.0),
                          height: buttonHeight,
                          child: GoldButton(
                            text: 'بازی دوباره',
                            icon: Icons.replay_rounded,
                            height: buttonHeight,
                            fontSize: (shortest * 0.043).clamp(15.0, 19.0),
                            onPressed: () => _startNewGame(context),
                          ),
                        ),

                      ],
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

  Future<void> _showExitDialog(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF4E4BD),
          title: const Text(
            'خروج از بازی؟',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'نتیجه این بازی از بین می‌رود.',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Vazirmatn'),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(80, AppTheme.minTouchTarget)),
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'لغو',
                style: TextStyle(fontFamily: 'Vazirmatn'),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(80, AppTheme.minTouchTarget)),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'خروج',
                style: TextStyle(fontFamily: 'Vazirmatn'),
              ),
            ),
          ],
        );
      },
    );

    if (shouldExit == true && context.mounted) {
      _exitToSetup(context);
    }
  }
}

class _WinnerCard extends StatelessWidget {
  final PlayerResult result;
  final double width;
  final double shortest;

  const _WinnerCard({
    required this.result,
    required this.width,
    required this.shortest,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = (shortest * 0.16).clamp(54.0, 78.0);
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(
        horizontal: (shortest * 0.04).clamp(12.0, 22.0),
        vertical: (shortest * 0.035).clamp(10.0, 18.0),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF5C3A00).withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(
          (shortest * 0.045).clamp(12.0, 18.0),
        ),
        border: Border.all(
          color: AppColors.brightGold,
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 5)),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: result.player.avatarColor,
              border: Border.all(color: AppColors.brightGold, width: 3),
            ),
            alignment: Alignment.center,
            child: Text(
              result.player.name.isEmpty ? '' : result.player.name[0],
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontWeight: FontWeight.w900,
                fontSize: avatarSize * 0.42,
                color: AppColors.black,
              ),
            ),
          ),
          SizedBox(width: (shortest * 0.035).clamp(10.0, 18.0)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🏆 برنده',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontWeight: FontWeight.w700,
                    fontSize: (shortest * 0.032).clamp(12.0, 16.0),
                    color: AppColors.brightGold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  result.player.name,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontWeight: FontWeight.w900,
                    fontSize: (shortest * 0.055).clamp(18.0, 26.0),
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${result.player.score} امتیاز',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontWeight: FontWeight.w800,
                    fontSize: (shortest * 0.035).clamp(13.0, 17.0),
                    color: Colors.white,
                  ),
                ),
                if (result.wonByFewerMistakes)
                  Text(
                    'برنده با تعداد اشتباه کمتر',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: (shortest * 0.028).clamp(11.0, 14.0),
                      color: Colors.white70,
                    ),
                  ),
                if (context.read<GameProvider>().goldenWinnerId == result.player.id)
                  Text(
                    'برنده دور طلایی',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: (shortest * 0.030).clamp(11.0, 15.0),
                      color: AppColors.brightGold,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultHeader extends StatelessWidget {
  final double shortest;

  const _ResultHeader({required this.shortest});

  @override
  Widget build(BuildContext context) {
    final fontSize = (shortest * 0.034).clamp(12.0, 16.0);
    final style = TextStyle(
      fontFamily: 'Vazirmatn',
      fontWeight: FontWeight.w900,
      fontSize: fontSize,
      color: const Color(0xFF4A3418),
    );

    return Row(
      textDirection: TextDirection.rtl,
      children: [
        SizedBox(
          width: (shortest * 0.15).clamp(44.0, 58.0),
          child: Text('رتبه', textAlign: TextAlign.center, style: style),
        ),
        Expanded(
          child: Text('بازیکن', textAlign: TextAlign.right, style: style),
        ),
        SizedBox(
          width: (shortest * 0.23).clamp(66.0, 88.0),
          child: Text('امتیاز کل', textAlign: TextAlign.center, style: style),
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  final PlayerResult result;
  final int rank;
  final double height;
  final double shortest;

  const _ResultRow({
    required this.result,
    required this.rank,
    required this.height,
    required this.shortest,
  });

  String _rankLabel() {
    if (rank == 1) return '🥇';
    if (rank == 2) return '🥈';
    if (rank == 3) return '🥉';
    return '$rank';
  }

  @override
  Widget build(BuildContext context) {
    final highlighted = rank <= 3;
    return Container(
      height: height,
      margin: EdgeInsets.symmetric(vertical: (height * 0.035).clamp(1.5, 3.0)),
      padding: EdgeInsets.symmetric(
        horizontal: (shortest * 0.018).clamp(6.0, 10.0),
      ),
      decoration: BoxDecoration(
        color: highlighted
            ? const Color(0xFFFFE6A3).withValues(alpha: 0.78)
            : const Color(0xFF8B6A3A).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          SizedBox(
            width: (shortest * 0.15).clamp(44.0, 58.0),
            child: Center(
              child: Text(
                _rankLabel(),
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontWeight: FontWeight.w900,
                  fontSize: highlighted
                      ? (shortest * 0.044).clamp(16.0, 21.0)
                      : (shortest * 0.033).clamp(12.0, 16.0),
                  color: const Color(0xFF4A3418),
                ),
              ),
            ),
          ),
          Container(
            width: (shortest * 0.065).clamp(24.0, 32.0),
            height: (shortest * 0.065).clamp(24.0, 32.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: result.player.avatarColor,
            ),
          ),
          SizedBox(width: (shortest * 0.018).clamp(5.0, 8.0)),
          Expanded(
            child: Text(
              result.player.name,
              textDirection: TextDirection.rtl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontWeight: highlighted ? FontWeight.w800 : FontWeight.w600,
                fontSize: (shortest * 0.037).clamp(13.0, 17.0),
                color: const Color(0xFF4A3418),
              ),
            ),
          ),
          SizedBox(
            width: (shortest * 0.23).clamp(66.0, 88.0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${result.player.score}',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontWeight: FontWeight.w900,
                  fontSize: (shortest * 0.039).clamp(14.0, 18.0),
                  color: const Color(0xFF9A6900),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
