import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/player.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gold_button.dart';
import '../widgets/player_name_pill.dart';
import '../widgets/compact_circular_timer.dart';
import 'result_screen.dart';
import 'score_screen.dart';
import 'golden_intro_screen.dart';

/// صفحه‌ی بازی (نمایش سوالات) - این تنها صفحه‌ی افقی (Landscape) کل برنامه است.
///
/// چیدمان جدید: به‌جای سوار کردن عناصر روی نقاط دقیقِ یک عکس کاراکتر، صفحه
/// از یک ساختار HUD مستقل از عکس پس‌زمینه استفاده می‌کند: دو ستون بازیکنان
/// (چپ/راست) که به‌طور خودکار متناسب با تعداد بازیکنان (۲ تا ۱۰ نفر) پخش
/// می‌شوند، و یک کارت سؤال واقعی در مرکز صفحه. این یعنی روی هر پس‌زمینه‌ای
/// (از جمله عکس ساده‌ی جنگل بدون کاراکتر) درست و مرتب دیده می‌شود.
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

    // موسیقی پس‌زمینه را متوقف کن (بازی آهنگ خودش دارد)
    AudioService().stopMusic();
  }

  @override
  void dispose() {
    // با خروج از این صفحه، برنامه به حالت عمودی پیش‌فرض برمی‌گردد.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

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

        // بازیکنان بین دو ستون چپ و راست تقسیم می‌شوند؛ اگر فقط ۲ بازیکن
        // باشند، دقیقاً ۲ کارت (یکی هر طرف) دیده می‌شود - نه بیشتر.
        final leftCount = (displayPlayers.length / 2).ceil();
        final leftPlayers = displayPlayers.take(leftCount).toList();
        final rightPlayers = displayPlayers.skip(leftCount).toList();

        return Scaffold(
          backgroundColor: AppColors.black,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;

                final sideColW = (0.185 * w).clamp(128.0, 188.0);
                final pillW = sideColW - 14;
                final pillH = (0.115 * h).clamp(46.0, AppTheme.playerPillHeight + 6);
                final timerSize = (0.145 * w).clamp(62.0, 92.0);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // پس‌زمینه‌ی جنگل
                    Image.asset(
                      'assets/images/bg_game_forest_landscape.png',
                      fit: BoxFit.cover,
                    ),

                    // سایه‌ی ملایم بالا/پایین تا HUD و متن‌ها روی هر عکسی خوانا بمانند
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x99000000),
                              Color(0x00000000),
                              Color(0x00000000),
                              Color(0x66000000),
                            ],
                            stops: [0.0, 0.22, 0.78, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // چیدمان اصلی: ستون بازیکنان چپ | محتوای مرکزی | ستون بازیکنان راست
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: (0.012 * w).clamp(8.0, 16.0),
                          vertical: (0.02 * h).clamp(8.0, 16.0),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: sideColW,
                              child: _PlayerColumn(
                                players: leftPlayers,
                                pillW: pillW,
                                pillH: pillH,
                                actionDirection: PillActionDirection.right,
                                game: game,
                                isGolden: isGolden,
                                leaderId: leaderId,
                              ),
                            ),
                            Expanded(
                              child: _CenterArea(
                                game: game,
                                isGolden: isGolden,
                                timerSize: timerSize,
                              ),
                            ),
                            SizedBox(
                              width: sideColW,
                              child: _PlayerColumn(
                                players: rightPlayers,
                                pillW: pillW,
                                pillH: pillH,
                                actionDirection: PillActionDirection.left,
                                game: game,
                                isGolden: isGolden,
                                leaderId: leaderId,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // پیام میان‌سؤالیِ دور طلایی
                    if (isGolden && game.phase == GamePhase.goldenBetweenQuestions)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.35),
                          alignment: Alignment.center,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
                            decoration: BoxDecoration(
                              color: AppColors.charcoal.withValues(alpha: 0.96),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.gold, width: 2),
                              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 6))],
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

                    // کنترل توقف؛ دکمه‌ی جمع‌وجور با آیکن و برچسب
                    if (!isGolden)
                      Positioned(
                        top: (0.04 * h).clamp(14.0, 26.0),
                        right: (0.02 * w).clamp(14.0, 26.0),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () => game.togglePause(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                              decoration: BoxDecoration(
                                color: AppColors.charcoal.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: AppColors.gold.withValues(alpha: 0.65), width: 1.2),
                                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3))],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    game.phase == GamePhase.paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                                    color: AppColors.brightGold,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    game.phase == GamePhase.paused ? 'ادامه' : 'مکث',
                                    textDirection: TextDirection.rtl,
                                    style: const TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
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

/// یک ستون از کارت‌های بازیکن که همیشه، مستقل از تعداد بازیکنان (۱ تا ۵ نفر
/// در هر طرف)، به‌شکل متعادل و بدون جای خالی در طول صفحه پخش می‌شود.
class _PlayerColumn extends StatelessWidget {
  final List<Player> players;
  final double pillW;
  final double pillH;
  final PillActionDirection actionDirection;
  final GameProvider game;
  final bool isGolden;
  final String? leaderId;

  const _PlayerColumn({
    required this.players,
    required this.pillW,
    required this.pillH,
    required this.actionDirection,
    required this.game,
    required this.isGolden,
    required this.leaderId,
  });

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final p in players)
          PlayerNamePill(
            key: ValueKey(p.id),
            player: p,
            actionDirection: actionDirection,
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
      ],
    );
  }
}

/// محتوای مرکزی صفحه: نوار وضعیت (شماره‌ی سؤال + تایمر) و کارت سؤال/پاسخ.
class _CenterArea extends StatelessWidget {
  final GameProvider game;
  final bool isGolden;
  final double timerSize;

  const _CenterArea({required this.game, required this.isGolden, required this.timerSize});

  @override
  Widget build(BuildContext context) {
    final showTimer = game.phase == GamePhase.questionActive || game.selectedPlayerId != null;
    final showAnswer = !isGolden && game.phase != GamePhase.waitingToShowQuestion && game.currentQuestion != null;

    // شماره‌ی سؤال داخل دستِ جاری (نه شماره‌ی کلی بازی) - دقیقاً مثل طرح مرجع.
    const int roundSize = 5;
    final int roundStart = (game.currentRoundNumber - 1) * roundSize;
    final int remainingInRound = game.totalQuestions - roundStart;
    final int questionsInThisRound =
        remainingInRound < 0 ? 0 : (remainingInRound > roundSize ? roundSize : remainingInRound);
    final int qInRoundRaw = game.currentQuestionNumber - roundStart;
    final int qInRound = qInRoundRaw < 1 ? 1 : (qInRoundRaw > roundSize ? roundSize : qInRoundRaw);

    return LayoutBuilder(builder: (context, c) {
      final maxCardWidth = c.maxWidth;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            const SizedBox(height: 6),
            _TopHud(
              isGolden: isGolden,
              qInRound: qInRound,
              questionsInThisRound: questionsInThisRound,
              showTimer: showTimer,
              timerSize: timerSize,
              game: game,
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Center(
                child: game.phase == GamePhase.waitingToShowQuestion
                    ? _StartQuestionButton(onTap: game.revealFirstQuestion)
                    : _QuestionCard(
                        text: (isGolden ? game.goldenQuestion?.question : game.currentQuestion?.question) ?? '',
                        keyId: 'q-${isGolden ? game.goldenQuestion?.id : game.currentQuestion?.id}',
                        maxWidth: maxCardWidth,
                      ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: showAnswer
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _AnswerChip(
                        text: game.currentQuestion!.answer,
                        keyId: 'a-${game.currentQuestion?.id}',
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      );
    });
  }
}

/// نوار وضعیت بالای صفحه: کپسول «سؤال X از ۵» با نقطه‌های پیشرفت، و تایمر دایره‌ای.
class _TopHud extends StatelessWidget {
  final bool isGolden;
  final int qInRound;
  final int questionsInThisRound;
  final bool showTimer;
  final double timerSize;
  final GameProvider game;

  const _TopHud({
    required this.isGolden,
    required this.qInRound,
    required this.questionsInThisRound,
    required this.showTimer,
    required this.timerSize,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.charcoal.withValues(alpha: 0.80),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.55)),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isGolden
                    ? 'دور طلایی  •  اولین پاسخ درست = برنده'
                    : 'سؤال $qInRound از $questionsInThisRound',
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              if (!isGolden && questionsInThisRound > 0) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 1; i <= questionsInThisRound; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.5),
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i <= qInRound ? AppColors.brightGold : Colors.white.withValues(alpha: 0.28),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 14),
        SizedBox(
          width: timerSize,
          height: timerSize * 1.2,
          child: showTimer
              ? CompactCircularTimer(
                  secondsRemaining: game.secondsRemaining,
                  progress: game.timerProgress,
                  size: timerSize,
                )
              : null,
        ),
      ],
    );
  }
}

/// کارت واقعیِ سؤال - جایگزین متنِ شناور روی عکس با یک کارت پارچمنت‌مانند
/// با سایه، حاشیه‌ی طلایی و سلسله‌مراتب تایپوگرافی روشن.
class _QuestionCard extends StatelessWidget {
  final String text;
  final String keyId;
  final double maxWidth;

  const _QuestionCard({required this.text, required this.keyId, required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    final cardWidth = maxWidth.clamp(260.0, 620.0);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: cardWidth),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.gold, Color(0xFFB8933F)],
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 18, offset: Offset(0, 8)),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFBF3DC), Color(0xFFEFE2BE)],
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(anim), child: child),
            ),
            child: Text(
              text,
              key: ValueKey(keyId),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Vazirmatn',
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: Color(0xFF31301F),
                height: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// کپسول نمایش پاسخ زیر کارت سؤال.
class _AnswerChip extends StatelessWidget {
  final String text;
  final String keyId;

  const _AnswerChip({required this.text, required this.keyId});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(keyId),
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.charcoal.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.rtl,
          children: [
            const Text('پاسخ:',
                textDirection: TextDirection.rtl,
                style: TextStyle(fontFamily: 'Vazirmatn', color: AppColors.brightGold, fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Vazirmatn', color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// دکمه‌ی طلایی شروعِ سؤال (پیش از دیدن اولین سؤال هر دست) - با درخشش ملایم
/// و ضربان آرام تا توجه بازیکن را جلب کند.
class _StartQuestionButton extends StatefulWidget {
  final VoidCallback onTap;
  const _StartQuestionButton({required this.onTap});

  @override
  State<_StartQuestionButton> createState() => _StartQuestionButtonState();
}

class _StartQuestionButtonState extends State<_StartQuestionButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _scale = Tween(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 20),
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: AppColors.brightGold.withValues(alpha: 0.55), blurRadius: 24, spreadRadius: 2),
              const BoxShadow(color: Colors.black54, blurRadius: 14, offset: Offset(0, 6)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_arrow_rounded, color: AppColors.black, size: 30),
              const SizedBox(width: 8),
              const Text(
                'شروع سؤال',
                textDirection: TextDirection.rtl,
                style: TextStyle(fontFamily: 'Vazirmatn', color: AppColors.black, fontWeight: FontWeight.w900, fontSize: 19),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
