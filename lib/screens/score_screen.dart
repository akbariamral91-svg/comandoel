import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/player.dart';
import '../theme/app_theme.dart';
import 'game_screen.dart';
import 'result_screen.dart';
import 'golden_intro_screen.dart';

/// صفحه مستقل امتیاز بعد از هر دست.
/// جدول همیشه امتیاز تجمعی کل بازی را از بیشترین به کمترین نشان می‌دهد.
/// این صفحه عمودی است و برای اندازه‌های مختلف گوشی به‌صورت responsive چیده شده است.
class ScoreScreen extends StatefulWidget {
  const ScoreScreen({super.key});

  @override
  State<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends State<ScoreScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // موسیقی پس‌زمینه دیگر اینجا پخش نمی‌شود؛ فقط در Home و Setup پخش می‌شود.
  }

  // توجه: عمداً در dispose جهت صفحه را دوباره عمودی نمی‌کنیم.
  // چون هنگام رفتن به دست بعدی از pushReplacement به GameScreen استفاده می‌شود،
  // و در آن حالت initState صفحه‌ی جدید (GameScreen) قبل از dispose شدن این
  // صفحه اجرا می‌شود. اگر اینجا دوباره جهت را عمودی می‌کردیم، این تنظیم
  // درست بعد از افقی‌شدن GameScreen اجرا می‌شد و صفحه‌ی سوالات را اشتباهاً
  // عمودی نگه می‌داشت. بقیه صفحاتی که از اینجا مقصد می‌شوند
  // (GoldenIntroScreen و ResultScreen) خودشان در initState جهت عمودی را
  // تنظیم می‌کنند، پس نیازی به تنظیم آن اینجا نیست.

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final ranked = game.players
        .where((p) => p.id != game.narratorId)
        .toList()
      ..sort((a, b) {
        if (b.score != a.score) return b.score.compareTo(a.score);
        return a.totalWrongAnswers.compareTo(b.totalWrongAnswers);
      });

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final shortest = w < h ? w : h;
            final horizontalPadding = (w * 0.055).clamp(14.0, 28.0);
            final titleSize = (shortest * 0.075).clamp(25.0, 34.0);
            final subtitleSize = (shortest * 0.036).clamp(12.0, 16.0);
            final rowHeight = (h * 0.072).clamp(50.0, 68.0);
            final tableRadius = (w * 0.045).clamp(14.0, 22.0);
            const buttonHeight = AppTheme.primaryButtonHeight;

            return Stack(
              fit: StackFit.expand,
              children: [
                // پس‌زمینه اختصاصی صفحه امتیاز؛ تصویر عمودی و مناسب گوشی است.
                Image.asset(
                  'assets/images/bg_score_forest.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
                // لایه‌ی خیلی ملایم برای خوانایی جدول بدون از بین بردن تصویر.
                Container(color: Colors.black.withValues(alpha: 0.14)),

                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    (h * 0.025).clamp(12.0, 24.0),
                    horizontalPadding,
                    (h * 0.025).clamp(12.0, 24.0),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: h - ((h * 0.05).clamp(24.0, 48.0)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'امتیاز',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontWeight: FontWeight.w900,
                            fontSize: titleSize,
                            color: Colors.white,
                            shadows: const [
                              Shadow(color: Colors.black87, blurRadius: 7),
                            ],
                          ),
                        ),
                        SizedBox(height: (h * 0.006).clamp(3.0, 8.0)),
                        Text(
                          'دست ${game.currentRoundNumber} از ${game.totalRounds}',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontWeight: FontWeight.w700,
                            fontSize: subtitleSize,
                            color: Colors.white,
                            shadows: const [
                              Shadow(color: Colors.black87, blurRadius: 4),
                            ],
                          ),
                        ),
                        SizedBox(height: (h * 0.025).clamp(12.0, 24.0)),

                        // جدول واقعی Flutter؛ هیچ بخش آن داخل تصویر پس‌زمینه نیست.
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4E4BD).withValues(alpha: 0.97),
                            borderRadius: BorderRadius.circular(tableRadius),
                            border: Border.all(
                              color: const Color(0xFFC18A27),
                              width: (w * 0.005).clamp(1.5, 2.5),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 14,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.fromLTRB(
                            (w * 0.025).clamp(9.0, 18.0),
                            (h * 0.014).clamp(8.0, 14.0),
                            (w * 0.025).clamp(9.0, 18.0),
                            (h * 0.014).clamp(8.0, 14.0),
                          ),
                          child: Column(
                            children: [
                              _TableHeader(shortest: shortest),
                              SizedBox(height: (h * 0.008).clamp(4.0, 8.0)),
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: const Color(0xFF6C4A20).withValues(alpha: 0.35),
                              ),
                              SizedBox(height: (h * 0.006).clamp(3.0, 7.0)),
                              ...List.generate(ranked.length, (index) {
                                return _ScoreRow(
                                  player: ranked[index],
                                  rank: index + 1,
                                  shortest: shortest,
                                  height: rowHeight,
                                );
                              }),
                            ],
                          ),
                        ),

                        SizedBox(height: (h * 0.024).clamp(12.0, 22.0)),
                        SizedBox(
                          width: (w * 0.72).clamp(210.0, 330.0),
                          height: buttonHeight,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: AppColors.black,
                              elevation: 6,
                              padding: EdgeInsets.symmetric(
                                horizontal: (w * 0.04).clamp(12.0, 22.0),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  (w * 0.04).clamp(12.0, 17.0),
                                ),
                              ),
                            ),
                            onPressed: () {
                              if (game.isLastRound) {
                                game.finishFromScoreScreen();
                                // بررسی کنید که آیا دور طلایی شروع شود یا نتیجه نهایی نمایش داده شود
                                if (game.phase == GamePhase.goldenIntro) {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => const GoldenIntroScreen(),
                                    ),
                                  );
                                } else if (game.phase == GamePhase.finished) {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => const ResultScreen(),
                                    ),
                                  );
                                }
                              } else {
                                game.startNextRound();
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => const GameScreen(),
                                  ),
                                );
                              }
                            },
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                game.isLastRound
                                    ? 'نتیجه نهایی'
                                    : 'شروع دست بعدی',
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontWeight: FontWeight.w900,
                                  fontSize: (shortest * 0.045).clamp(15.0, 19.0),
                                ),
                              ),
                            ),
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
}

class _TableHeader extends StatelessWidget {
  final double shortest;

  const _TableHeader({required this.shortest});

  @override
  Widget build(BuildContext context) {
    final fontSize = (shortest * 0.036).clamp(12.0, 16.0);
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        SizedBox(
          width: (shortest * 0.14).clamp(40.0, 54.0),
          child: Text(
            'رتبه',
            textAlign: TextAlign.center,
            style: _headerStyle(fontSize),
          ),
        ),
        Expanded(
          child: Text(
            'بازیکن',
            textAlign: TextAlign.right,
            style: _headerStyle(fontSize),
          ),
        ),
        SizedBox(
          width: (shortest * 0.20).clamp(62.0, 82.0),
          child: Text(
            'امتیاز کل',
            textAlign: TextAlign.center,
            style: _headerStyle(fontSize),
          ),
        ),
      ],
    );
  }

  TextStyle _headerStyle(double size) => TextStyle(
        fontFamily: 'Vazirmatn',
        fontWeight: FontWeight.w900,
        fontSize: size,
        color: const Color(0xFF573A16),
      );
}

class _ScoreRow extends StatelessWidget {
  final Player player;
  final int rank;
  final double shortest;
  final double height;

  const _ScoreRow({
    required this.player,
    required this.rank,
    required this.shortest,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isTop = rank <= 3;
    final fontSize = (shortest * 0.041).clamp(13.0, 18.0);
    final avatarSize = (shortest * 0.075).clamp(28.0, 36.0);
    final rankWidth = (shortest * 0.14).clamp(40.0, 54.0);
    final scoreWidth = (shortest * 0.20).clamp(62.0, 82.0);

    final medal = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '$rank',
    };

    return Container(
      height: height,
      margin: EdgeInsets.symmetric(
        vertical: (shortest * 0.008).clamp(2.0, 4.0),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: (shortest * 0.018).clamp(6.0, 10.0),
      ),
      decoration: BoxDecoration(
        color: isTop
            ? const Color(0x2AB8860B)
            : const Color(0x12000000),
        borderRadius: BorderRadius.circular(
          (shortest * 0.025).clamp(8.0, 12.0),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          SizedBox(
            width: rankWidth,
            child: Text(
              medal,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontWeight: FontWeight.w900,
                fontSize: isTop ? fontSize + 2 : fontSize,
                color: const Color(0xFF573A16),
              ),
            ),
          ),
          SizedBox(width: (shortest * 0.02).clamp(6.0, 10.0)),
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: player.avatarColor,
              border: Border.all(
                color: const Color(0xFF5C431C),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              player.name.isEmpty ? '' : player.name.characters.first,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontWeight: FontWeight.w900,
                fontSize: (fontSize * 0.82).clamp(11.0, 15.0),
                color: AppColors.black,
              ),
            ),
          ),
          SizedBox(width: (shortest * 0.018).clamp(5.0, 9.0)),
          Expanded(
            child: Text(
              player.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontWeight: isTop ? FontWeight.w900 : FontWeight.w700,
                fontSize: fontSize,
                color: const Color(0xFF3E2A12),
              ),
            ),
          ),
          SizedBox(
            width: scoreWidth,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${player.score}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontWeight: FontWeight.w900,
                  fontSize: fontSize,
                  color: const Color(0xFF8A5A00),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
