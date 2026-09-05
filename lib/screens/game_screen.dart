import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gold_button.dart';
import '../widgets/player_name_pill.dart';
import '../widgets/compact_circular_timer.dart';
import 'result_screen.dart';
import 'score_screen.dart';
import 'golden_intro_screen.dart';

/// صفحه‌ی بازی (نمایش سوالات) - این تنها صفحه‌ی افقی (Landscape) کل برنامه است.
/// چیدمان دقیقاً روی عکس پس‌زمینه‌ی کاراکتر علامت‌سوال سوار می‌شود:
/// - گودی کاراکتر: دکمه‌ی شروع دست / تایمر
/// - حباب سفید بزرگ: متن سوال
/// - ابر کوچک: جواب سوال
/// - ۱۰ جایگاه ثابت دور صفحه (۴ بالا / ۴ پایین / ۱ چپ / ۱ راست): مستطیل‌های نام بازیکنان
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

/// نگاشت‌گر مختصات روی عکس پس‌زمینه وقتی با BoxFit.cover کشیده می‌شود.
/// چون گوشی‌های مختلف نسبت تصویر متفاوتی نسبت به عکس اصلی (1822×863) دارند،
/// BoxFit.cover همیشه بخشی از عکس را کراپ می‌کند؛ اگر مختصات فقط با ضرب در
/// عرض/ارتفاع صفحه محاسبه شوند (بدون احتساب این کراپ)، عناصر روی گودی/حباب/ابر
/// از جای درستشان روی عکس جابه‌جا می‌شوند. این کلاس همان نگاشت واقعی cover را
/// پیاده می‌کند تا این عناصر همیشه دقیقاً روی نقطه‌ی درست از عکس بنشینند.
class _BgCoverMap {
  static const double imgW = 1822;
  static const double imgH = 863;
  final double scale;
  final double dispW;
  final double dispH;
  final double offsetX;
  final double offsetY;

  factory _BgCoverMap(double w, double h) {
    final scaleW = w / imgW;
    final scaleH = h / imgH;
    final scale = scaleW > scaleH ? scaleW : scaleH; // BoxFit.cover: بزرگ‌ترین مقیاس
    final dispW = imgW * scale;
    final dispH = imgH * scale;
    return _BgCoverMap._(
      scale: scale,
      dispW: dispW,
      dispH: dispH,
      offsetX: (w - dispW) / 2, // معمولاً منفی یا صفر (بخش کراپ‌شده از هر طرف)
      offsetY: (h - dispH) / 2,
    );
  }

  _BgCoverMap._({
    required this.scale,
    required this.dispW,
    required this.dispH,
    required this.offsetX,
    required this.offsetY,
  });

  /// نقطه‌ای با مختصات نسبی روی عکس اصلی (۰ تا ۱) را به مختصات واقعی صفحه تبدیل می‌کند.
  Offset point(double fx, double fy) => Offset(offsetX + fx * dispW, offsetY + fy * dispH);

  /// طول افقی نسبی (نسبت به عرض عکس اصلی) را به پیکسل واقعی صفحه تبدیل می‌کند.
  double lenW(double f) => f * dispW;

  /// طول عمودی نسبی (نسبت به ارتفاع عکس اصلی) را به پیکسل واقعی صفحه تبدیل می‌کند.
  double lenH(double f) => f * dispH;
}

class _GameScreenState extends State<GameScreen> {
  @override
  void initState() {
    super.initState();
    // این تنها صفحه‌ی افقی برنامه است؛ در ورود، گوشی را افقی می‌کنیم.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // موسیقی پس‌زمینه را متوقف کن (بازی آهنگ خودش دارد)
    AudioService().stopMusic();
  }

  @override
  void dispose() {
    // با خروج از این صفحه، برنامه به حالت عمودی پیش‌فرض برمی‌گردد.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  // ترتیب پرشدن ۱۰ جایگاه بازیکن: ابتدا جایگاه‌های نزدیک به مرکز بالا/پایین (که
  // بصری‌تر و متعادل‌تر دیده می‌شوند)، سپس لبه‌ها، و در آخر چپ/راست.
  // (چون طرح گرافیکی جای مشخصی برای اینکه با ۲ تا ۹ بازیکن کدام جایگاه‌ها استفاده شوند
  // تعیین نکرده بود، این ترتیب انتخاب خودم برای بهترین توازن بصریه.)
  static const List<String> _slotFillOrder = [
    'top2', 'top3', 'bottom2', 'bottom3',
    'top1', 'top4', 'bottom1', 'bottom4',
    'left', 'right',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, _) {
        if (game.phase == GamePhase.roundScore) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (game.isLastRound) {
              // آخرین دست: ابتدا تساوی کامل بررسی می‌شود؛ در صورت تساوی،
              // صفحه معرفی دور طلایی نمایش داده می‌شود.
              game.finishFromScoreScreen();
              if (game.phase == GamePhase.goldenIntro) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const GoldenIntroScreen()),
                );
              } else if (game.phase == GamePhase.finished) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const ResultScreen()),
                );
              }
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ScoreScreen()),
              );
            }
          });
        }

        if (game.phase == GamePhase.finished) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const ResultScreen()),
            );
          });
        }

        final isGolden = game.phase == GamePhase.goldenQuestionActive ||
            game.phase == GamePhase.goldenBetweenQuestions;
        final displayPlayers = isGolden ? game.goldenPlayers : game.players;
        final leaderId = isGolden || game.players.isEmpty
            ? null
            : (game.players.reduce((a, b) => a.score >= b.score ? a : b)).id;

        return Scaffold(
          backgroundColor: AppColors.black,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                // نگاشت مختصات عناصر چسبیده به عکس (گودی/حباب/ابر/دکمه‌ی استپ)
                // با احتساب کراپ واقعی BoxFit.cover روی این گوشی، تا مستقل از
                // نسبت تصویر صفحه، همیشه دقیقاً روی همان نقطه از عکس بنشینند.
                final bg = _BgCoverMap(w, h);

                // جایگاه‌های ثابت ۱۰گانه‌ی بازیکنان
                // نکته‌ی مهم: جایگاه‌های نیمه‌ی راست از لبه‌ی راست (right:) موقعیت‌دهی می‌شوند
                // (نه با فاصله‌ی ثابت از چپ) تا روی گوشی‌های با عرض افقی کمتر از صفحه بیرون نزنند.
                //
                // نکته‌ی دوم و مهم‌تر (باگ اصلیِ «دکمه‌ها جای درست خودشون نیستن»):
                // مستطیل نام بازیکن (pill) یک ارتفاع واقعی (pillH) دارد که به عرض صفحه
                // بستگی دارد؛ قبلاً ردیف پایین با یک درصد ثابتِ ارتفاع صفحه (مثلاً 0.92*h)
                // جای‌گذاری می‌شد بدون کم‌کردن ارتفاعِ خودِ pill، پس روی گوشی‌هایی که این
                // درصد کوچک‌تر از ارتفاع pill بود، مستطیل از پایین صفحه بیرون می‌زد و برش
                // می‌خورد (دقیقاً چیزی که در عکس دیده می‌شود). این‌جا موقعیت ردیف پایین را
                // از «کف صفحه منهای ارتفاع pill» حساب می‌کنیم تا همیشه کامل داخل صفحه بماند.
                final pillW = (0.155 * w).clamp(120.0, 210.0);
                final pillH = (pillW * 0.40).clamp(AppTheme.playerPillHeight, 64.0);
                final edgeMargin = 0.02 * h; // فاصله‌ی امن از لبه‌ی بالا/پایین صفحه
                final bottomOuterTop = h - pillH - edgeMargin; // بیرونی‌ها (نزدیک گوشه) درست کنار لبه
                final bottomInnerTop = bottomOuterTop - 0.035 * h; // درونی‌ها کمی بالاتر (حالت زیگزاگ)
                final topOuterTop = edgeMargin;
                final topInnerTop = edgeMargin + 0.025 * h;

                final leftSlots = <String, Offset>{
                  'top1': Offset(0.08 * w, topOuterTop),
                  'top2': Offset(0.30 * w, topInnerTop),
                  'bottom1': Offset(0.08 * w, bottomOuterTop),
                  'bottom2': Offset(0.30 * w, bottomInnerTop),
                  'left': Offset(0.015 * w, 0.46 * h),
                };
                final rightSlots = <String, Offset>{
                  'top3': Offset(0.30 * w, topInnerTop),
                  'top4': Offset(0.08 * w, topOuterTop),
                  'bottom3': Offset(0.30 * w, bottomInnerTop),
                  'bottom4': Offset(0.08 * w, bottomOuterTop),
                  'right': Offset(0.02 * w, 0.46 * h),
                };
                final directions = <String, PillActionDirection>{
                  'top1': PillActionDirection.below,
                  'top2': PillActionDirection.below,
                  'top3': PillActionDirection.below,
                  'top4': PillActionDirection.below,
                  'bottom1': PillActionDirection.above,
                  'bottom2': PillActionDirection.above,
                  'bottom3': PillActionDirection.above,
                  'bottom4': PillActionDirection.above,
                  'left': PillActionDirection.right,
                  'right': PillActionDirection.left,
                };

                final activeSlots = _slotFillOrder.take(displayPlayers.length).toList();

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // پس‌زمینه
                    Image.asset(
                      'assets/images/bg_game_forest_landscape.png',
                      fit: BoxFit.cover,
                    ),

                    // گودی کاراکتر: دکمه شروع دست / تایمر
                    // مختصات دقیق‌سنجی‌شده با تحلیل پیکسلی از عکس اصلی: مرکز گودی در (0.296, 0.382)
                    // اندازه‌ی واقعی گودی حدود ۶٪ عرض عکس است؛ حداقل ۴۴ پیکسل هم برای لمس‌پذیری تضمین می‌شود.
                    Positioned(
                      left: bg.point(0.296, 0.382).dx - bg.lenW(0.06).clamp(44.0, 110.0) / 2,
                      top: bg.point(0.296, 0.382).dy - bg.lenW(0.06).clamp(44.0, 110.0) / 2,
                      child: Builder(builder: (context) {
                        final size = bg.lenW(0.06).clamp(48.0, 110.0);
                        return game.phase == GamePhase.waitingToShowQuestion
                            ? GestureDetector(
                                onTap: () => game.revealFirstQuestion(),
                                child: Container(
                                  width: size,
                                  height: size,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppColors.goldGradient,
                                  ),
                                  child: Icon(Icons.play_arrow, color: AppColors.black, size: size * 0.5),
                                ),
                              )
                            : (game.phase == GamePhase.questionActive || game.selectedPlayerId != null)
                                ? CompactCircularTimer(
                                    secondsRemaining: game.secondsRemaining,
                                    progress: game.timerProgress,
                                    size: size,
                                  )
                                : SizedBox(width: size, height: size);
                      }),
                    ),

                    // حباب سفید: متن سوال (مختصات دقیق‌سنجی‌شده)
                    Positioned(
                      left: bg.point(0.435, 0.270).dx,
                      top: bg.point(0.435, 0.270).dy,
                      width: bg.lenW(0.356),
                      height: bg.lenH(0.297),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: Text(
                            (isGolden ? game.goldenQuestion?.question : game.currentQuestion?.question) ?? '',
                            key: ValueKey('q-${isGolden ? game.goldenQuestion?.id : game.currentQuestion?.id}'),
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                              color: Color(0xFF3B3B2E),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ابر کوچک: جواب (مختصات دقیق‌سنجی‌شده)
                    if (!isGolden && game.phase != GamePhase.waitingToShowQuestion && game.currentQuestion != null)
                      Positioned(
                        left: bg.point(0.663, 0.679).dx,
                        top: bg.point(0.663, 0.679).dy,
                        width: bg.lenW(0.202),
                        height: bg.lenH(0.173),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: Text(
                              game.currentQuestion!.answer,
                              key: ValueKey('a-${game.currentQuestion?.id}'),
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Color(0xFF3B3B2E),
                              ),
                            ),
                          ),
                        ),
                      ),

                    if (isGolden && game.phase == GamePhase.goldenBetweenQuestions)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.28),
                          alignment: Alignment.center,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                            decoration: BoxDecoration(
                              color: AppColors.charcoal.withValues(alpha: 0.96),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.gold, width: 2),
                            ),
                            child: const Text(
                              'سؤال بعدی در راه است...',
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontFamily: 'Vazirmatn', color: AppColors.gold, fontWeight: FontWeight.w900, fontSize: 20),
                            ),
                          ),
                        ),
                      ),

                    // دکمه استپ - دقیقاً کنار کادر سوال (بالای گوشه‌ی راست حباب)
                    if (!isGolden)
                    Positioned(
                      left: bg.point(0.70, 0.19).dx,
                      top: bg.point(0.70, 0.19).dy,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => game.togglePause(),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 0.018 * w, vertical: 0.012 * w),
                          decoration: BoxDecoration(
                            color: AppColors.charcoal,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.gold, width: 1.6),
                            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6)],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                game.phase == GamePhase.paused ? Icons.play_arrow : Icons.pause,
                                color: AppColors.gold,
                                size: (0.022 * w).clamp(16.0, 26.0),
                              ),
                              SizedBox(width: 0.006 * w),
                              Text(
                                game.phase == GamePhase.paused ? 'ادامه' : 'استپ',
                                style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    color: AppColors.gold,
                                    fontSize: (0.018 * w).clamp(13.0, 20.0)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // شماره‌ی دست/سوال - بالا وسط
                    Positioned(
                      top: 0.015 * h,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          isGolden
                              ? 'دور طلایی  •  اولین پاسخ درست = برنده'
                              : 'دست ${game.currentRoundNumber} از ${game.totalRounds}  •  سوال ${game.currentQuestionNumber} از ${game.totalQuestions}',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            color: Colors.white70,
                            fontSize: (0.014 * w).clamp(12.0, 17.0),
                            shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
                          ),
                        ),
                      ),
                    ),

                    // ۱۰ جایگاه ثابت بازیکنان
                    // اندازه‌ی مستطیل نام بازیکن نسبت به عرض واقعی صفحه محاسبه می‌شود
                    // (نه عدد ثابت) تا روی گوشی واقعی به‌جای کوچک به‌نظر رسیدن، اندازه‌ی مناسب داشته باشد.
                    for (int i = 0; i < activeSlots.length; i++)
                      Builder(builder: (context) {
                        final slotKey = activeSlots[i];
                        final dir = directions[slotKey]!;
                        final p = displayPlayers[i];
                        final isRightSide = rightSlots.containsKey(slotKey);
                        final pos = isRightSide ? rightSlots[slotKey]! : leftSlots[slotKey]!;
                        return Positioned(
                          left: isRightSide ? null : pos.dx,
                          right: isRightSide ? pos.dx : null,
                          top: pos.dy,
                          child: PlayerNamePill(
                            player: p,
                            actionDirection: dir,
                            width: pillW,
                            height: pillH,
                            isSelected: game.selectedPlayerId == p.id,
                            isLeader: p.id == leaderId && p.score > 0,
                            isNarrator: !isGolden && p.id == game.narratorId,
                            scoreEvent: game.lastScoreEvent?.playerId == p.id ? game.lastScoreEvent : null,
                            onTap: () => isGolden ? game.selectGoldenPlayer(p.id) : game.selectPlayer(p.id),
                            onMarkCorrect: () => isGolden ? game.markGoldenCorrect() : game.markCorrect(),
                            onMarkWrong: () => isGolden ? game.markGoldenWrong() : game.markWrong(),
                            onCancel: () => isGolden ? game.cancelGoldenSelection() : game.cancelSelection(),
                          ),
                        );
                      }),
                  ],
                );
              },
            ),
          ),
          bottomSheet: game.phase == GamePhase.paused
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: AppColors.charcoal,
                    border: Border(top: BorderSide(color: AppColors.gold)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.pause_circle_outline, color: AppColors.gold, size: 26),
                      const SizedBox(width: 10),
                      const Text('بازی متوقف شده',
                          style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white, fontSize: 13)),
                      const SizedBox(width: 20),
                      GoldButton(
                        text: 'ادامه بازی',
                        height: AppTheme.secondaryButtonHeight,
                        fontSize: 13,
                        onPressed: () => Provider.of<GameProvider>(context, listen: false).togglePause(),
                      ),
                      const SizedBox(width: 10),
                      GoldButton(
                        text: 'خروج از بازی',
                        outlined: true,
                        height: AppTheme.secondaryButtonHeight,
                        fontSize: 13,
                        onPressed: () => _confirmExitGame(context),
                      ),
                    ],
                  ),
                )
              : null,
        );
      },
    );
  }

  void _confirmExitGame(BuildContext context) {
    final game = Provider.of<GameProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.gold),
        ),
        title: const Text(
          'خروج از بازی',
          textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'Vazirmatn', color: AppColors.gold, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'با خروج، پیشرفت این بازی از بین می‌رود. مطمئن هستید؟',
          textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white70, height: 1.7),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              game.resetGame();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('خروج', style: TextStyle(fontFamily: 'Vazirmatn', color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
