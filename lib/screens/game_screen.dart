import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/gold_button.dart';
import '../widgets/player_name_pill.dart';
import '../widgets/compact_circular_timer.dart';
import 'result_screen.dart';

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

class _GameScreenState extends State<GameScreen> {
  @override
  void initState() {
    super.initState();
    // این تنها صفحه‌ی افقی برنامه است؛ در ورود، گوشی را افقی می‌کنیم.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
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
        if (game.phase == GamePhase.finished) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const ResultScreen()),
            );
          });
        }

        final leaderId = game.players.isEmpty
            ? null
            : (game.players.reduce((a, b) => a.score >= b.score ? a : b)).id;

        return Scaffold(
          backgroundColor: AppColors.black,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;

                // جایگاه‌های ثابت ۱۰گانه‌ی بازیکنان
                // نکته‌ی مهم: جایگاه‌های نیمه‌ی راست از لبه‌ی راست (right:) موقعیت‌دهی می‌شوند
                // (نه با فاصله‌ی ثابت از چپ) تا روی گوشی‌های با عرض افقی کمتر از صفحه بیرون نزنند.
                final leftSlots = <String, Offset>{
                  'top1': Offset(0.08 * w, 0.03 * h),
                  'top2': Offset(0.30 * w, 0.03 * h),
                  'bottom1': Offset(0.08 * w, 0.88 * h),
                  'bottom2': Offset(0.30 * w, 0.92 * h),
                  'left': Offset(0.015 * w, 0.46 * h),
                };
                final rightSlots = <String, Offset>{
                  'top3': Offset(0.30 * w, 0.03 * h),
                  'top4': Offset(0.08 * w, 0.06 * h),
                  'bottom3': Offset(0.30 * w, 0.92 * h),
                  'bottom4': Offset(0.08 * w, 0.88 * h),
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

                final activeSlots = _slotFillOrder.take(game.players.length).toList();

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // پس‌زمینه
                    Image.asset(
                      'assets/images/bg_game_forest_landscape.png',
                      fit: BoxFit.fill,
                    ),

                    // گودی کاراکتر: دکمه شروع دست / تایمر
                    // مختصات دقیق‌سنجی‌شده با تحلیل پیکسلی از عکس اصلی: مرکز گودی در (0.296, 0.382)
                    // اندازه‌ی واقعی گودی حدود ۶٪ عرض عکس است؛ حداقل ۴۴ پیکسل هم برای لمس‌پذیری تضمین می‌شود.
                    Positioned(
                      left: 0.296 * w - (0.06 * w).clamp(44.0, 110.0) / 2,
                      top: 0.382 * h - (0.06 * w).clamp(44.0, 110.0) / 2,
                      child: Builder(builder: (context) {
                        final size = (0.06 * w).clamp(44.0, 110.0);
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
                      left: 0.435 * w,
                      top: 0.270 * h,
                      width: 0.356 * w,
                      height: 0.297 * h,
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: Text(
                            game.currentQuestion?.question ?? '',
                            key: ValueKey('q-${game.currentQuestion?.id}'),
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
                    if (game.phase != GamePhase.waitingToShowQuestion && game.currentQuestion != null)
                      Positioned(
                        left: 0.663 * w,
                        top: 0.679 * h,
                        width: 0.202 * w,
                        height: 0.173 * h,
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

                    // دکمه استپ - دقیقاً کنار کادر سوال (بالای گوشه‌ی راست حباب)
                    Positioned(
                      left: 0.70 * w,
                      top: 0.19 * h,
                      child: GestureDetector(
                        onTap: () => game.togglePause(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.charcoal,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.gold, width: 1.4),
                            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6)],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                game.phase == GamePhase.paused ? Icons.play_arrow : Icons.pause,
                                color: AppColors.gold,
                                size: 15,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                game.phase == GamePhase.paused ? 'ادامه' : 'استپ',
                                style: const TextStyle(
                                    fontFamily: 'Vazirmatn', color: AppColors.gold, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // شماره‌ی دست/سوال - بالا وسط، کوچک و بی‌مزاحمت
                    Positioned(
                      top: 0.015 * h,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          'دست ${game.currentRoundNumber} از ${game.totalRounds}  •  سوال ${game.currentQuestionNumber} از ${game.totalQuestions}',
                          style: const TextStyle(
                            fontFamily: 'Vazirmatn',
                            color: Colors.white70,
                            fontSize: 10,
                            shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                          ),
                        ),
                      ),
                    ),

                    // ۱۰ جایگاه ثابت بازیکنان
                    for (int i = 0; i < activeSlots.length; i++)
                      Builder(builder: (context) {
                        final slotKey = activeSlots[i];
                        final dir = directions[slotKey]!;
                        final p = game.players[i];
                        final isRightSide = rightSlots.containsKey(slotKey);
                        final pos = isRightSide ? rightSlots[slotKey]! : leftSlots[slotKey]!;
                        return Positioned(
                          left: isRightSide ? null : pos.dx,
                          right: isRightSide ? pos.dx : null,
                          top: pos.dy,
                          child: PlayerNamePill(
                            player: p,
                            actionDirection: dir,
                            isSelected: game.selectedPlayerId == p.id,
                            isLeader: p.id == leaderId && p.score > 0,
                            isNarrator: p.id == game.narratorId,
                            scoreEvent: game.lastScoreEvent?.playerId == p.id ? game.lastScoreEvent : null,
                            onTap: () => game.selectPlayer(p.id),
                            onMarkCorrect: () => game.markCorrect(),
                            onMarkWrong: () => game.markWrong(),
                            onCancel: () => game.cancelSelection(),
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
                        height: 40,
                        fontSize: 13,
                        onPressed: () => Provider.of<GameProvider>(context, listen: false).togglePause(),
                      ),
                      const SizedBox(width: 10),
                      GoldButton(
                        text: 'خروج از بازی',
                        outlined: true,
                        height: 40,
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
