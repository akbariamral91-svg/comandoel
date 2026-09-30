import 'package:flutter/material.dart';
import '../models/player.dart';
import '../providers/game_provider.dart' show ScoreEvent;
import '../theme/app_theme.dart';
import 'player_profile_avatar.dart';

/// جهت قرارگیری دکمه‌های سبز/قرمز/لغو نسبت به مستطیل، بسته به اینکه
/// مستطیل کجای صفحه (بالا، پایین، چپ، راست) قرار دارد تا دکمه‌ها همیشه
/// به سمت داخل صفحه باز شوند و از صفحه بیرون نزنند.
enum PillActionDirection { below, above, right, left }

/// مستطیل گرد (بدون گوشه‌ی تیز) حاوی اسم و امتیاز بازیکن - جایگزین دایره‌ی قبلی
/// برای چیدمان جدید صفحه‌ی بازی (افقی، اطراف عکس پس‌زمینه)
class PlayerNamePill extends StatefulWidget {
  final Player player;
  final bool isSelected;
  final bool isLeader;
  final bool isNarrator;
  final ScoreEvent? scoreEvent;
  final VoidCallback onTap;
  final VoidCallback onMarkCorrect;
  final VoidCallback onMarkWrong;
  final VoidCallback onCancel;
  final PillActionDirection actionDirection;
  final double width;
  final double height;

  const PlayerNamePill({
    super.key,
    required this.player,
    required this.onTap,
    required this.onMarkCorrect,
    required this.onMarkWrong,
    required this.onCancel,
    this.isSelected = false,
    this.isLeader = false,
    this.isNarrator = false,
    this.scoreEvent,
    this.actionDirection = PillActionDirection.below,
    this.width = 150,
    this.height = AppTheme.playerPillHeight,
  });

  @override
  State<PlayerNamePill> createState() => _PlayerNamePillState();
}

class _PlayerNamePillState extends State<PlayerNamePill>
    with SingleTickerProviderStateMixin {
  late AnimationController _popController;
  late Animation<double> _popScale;
  bool _flashGreen = false;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _popScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _popController, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant PlayerNamePill oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newEvent = widget.scoreEvent;
    final oldEvent = oldWidget.scoreEvent;
    if (newEvent != null && newEvent.eventId != oldEvent?.eventId) {
      setState(() => _flashGreen = true);
      _popController.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _flashGreen = false);
      });
    }
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  double get _avatarSize => (widget.height * 0.72).clamp(32.0, 40.0);

  /// نسخه‌ی درخشان‌تر و پراشباع‌تر از رنگ بازیکن - برای حاشیه‌ی کارت و
  /// حلقه‌ی دور عکس پروفایل، تا هر بازیکن رنگ مشخص و زنده‌ی خودش را داشته
  /// باشد (دقیقاً مثل طرح مرجع: هر کارت با رنگ خودش قاب‌بندی شده).
  Color _vivid(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withSaturation((hsl.saturation + 0.22).clamp(0.0, 1.0))
        .withLightness((hsl.lightness + 0.10).clamp(0.15, 0.72))
        .toColor();
  }

  Alignment get _actionAlignment => switch (widget.actionDirection) {
    PillActionDirection.below => Alignment.topCenter,
    PillActionDirection.above => Alignment.bottomCenter,
    PillActionDirection.right => Alignment.centerLeft,
    PillActionDirection.left => Alignment.centerRight,
  };

  @override
  Widget build(BuildContext context) {
    final blocked = widget.player.isBlockedForCurrentQuestion;
    final disabled = blocked || widget.isNarrator;

    final accent = widget.player.avatarColor;
    final vividAccent = _vivid(accent);
    final ringColor = widget.isSelected ? AppColors.brightGold : vividAccent;
    final borderColor = widget.isSelected ? AppColors.brightGold : vividAccent;
    final crownSize = _avatarSize * 0.56;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: disabled ? null : widget.onTap,
          child: AnimatedBuilder(
            animation: _popController,
            builder: (context, child) => Transform.scale(scale: _popScale.value, child: child),
            child: Container(
              width: widget.width,
              height: widget.height,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(AppColors.black, accent, 0.52)!,
                    Color.lerp(AppColors.black, accent, 0.22)!,
                  ],
                ),
                borderRadius: BorderRadius.circular(widget.height / 2),
                border: Border.all(
                  color: borderColor,
                  width: widget.isSelected || widget.isLeader ? 2.6 : 2.0,
                ),
                boxShadow: [
                  if (widget.isSelected)
                    BoxShadow(color: AppColors.brightGold.withValues(alpha: 0.6), blurRadius: 14, spreadRadius: 1.5),
                  BoxShadow(color: vividAccent.withValues(alpha: 0.28), blurRadius: 10, offset: const Offset(0, 3)),
                  const BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4)),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // خط ظریفِ نورِ شیشه‌ای بالای کارت برای حس براق و پرمایه
                  Positioned(
                    left: widget.height * 0.3,
                    right: widget.height * 0.3,
                    top: 2.5,
                    child: Container(
                      height: 1.4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // عکس پروفایل سمت چپ (برای کادرهای سمت چپ صفحه)
                      if (widget.actionDirection == PillActionDirection.right)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: ringColor.withValues(alpha: 0.55), blurRadius: 8, spreadRadius: 0.5)],
                              ),
                              child: PlayerProfileAvatar(
                                player: widget.player,
                                size: _avatarSize * 0.85,
                                borderColor: ringColor,
                                borderWidth: widget.isSelected ? 2.2 : 1.8,
                              ),
                            ),
                          ),
                        ),
                      Flexible(
                        child: Text(
                          widget.player.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontWeight: FontWeight.w700,
                            fontSize: widget.height * 0.28,
                            color: Colors.white,
                            shadows: const [Shadow(color: Colors.black54, blurRadius: 3)],
                          ),
                        ),
                      ),
                      SizedBox(width: widget.width * 0.04),
                      Icon(Icons.star_rounded,
                          color: _flashGreen ? AppColors.success : AppColors.brightGold,
                          size: widget.height * 0.32),
                      const SizedBox(width: 2),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 250),
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontWeight: FontWeight.w900,
                          fontSize: widget.height * 0.30,
                          color: _flashGreen ? AppColors.success : AppColors.brightGold,
                        ),
                        child: Text('${widget.player.score}'),
                      ),
                      if (widget.isNarrator)
                        Padding(
                          padding: const EdgeInsets.only(right: 3),
                          child: Icon(Icons.campaign,
                              color: Colors.white70, size: widget.height * 0.30),
                        ),
                      // عکس پروفایل سمت راست (برای کادرهای سمت راست صفحه)
                      if (widget.actionDirection == PillActionDirection.left)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: ringColor.withValues(alpha: 0.55), blurRadius: 8, spreadRadius: 0.5)],
                              ),
                              child: PlayerProfileAvatar(
                                player: widget.player,
                                size: _avatarSize * 0.85,
                                borderColor: ringColor,
                                borderWidth: widget.isSelected ? 2.2 : 1.8,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (blocked)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(widget.height / 2),
                      ),
                      child: Center(
                        child: Icon(Icons.close, color: AppColors.error, size: widget.height * 0.42),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // تاج طلایی بازیکن پیشتاز (اختیاری برای کادرهای بالا/پایین)
        if (widget.isLeader && 
            (widget.actionDirection == PillActionDirection.above ||
             widget.actionDirection == PillActionDirection.below))
          Positioned(
            top: -_avatarSize * 0.45,
            child: IgnorePointer(
              child: Icon(
                Icons.emoji_events_rounded,
                color: AppColors.brightGold,
                size: crownSize * 0.8,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1))],
              ),
            ),
          ),

        if (_flashGreen && widget.scoreEvent != null)
          Positioned(
            top: -_avatarSize - widget.height * 0.28,
            child: Text(
              '+${widget.scoreEvent!.points}',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontWeight: FontWeight.w900,
                fontSize: widget.height * 0.34,
                color: AppColors.brightGold,
              ),
            ),
          ),

        if (widget.isSelected)
          Align(
            alignment: _actionAlignment,
            child: FractionalTranslation(
              translation: _actionOffset,
              child: _ActionButtonsRow(
                direction: widget.actionDirection,
                onCorrect: widget.onMarkCorrect,
                onWrong: widget.onMarkWrong,
                onCancel: widget.onCancel,
                baseSize: widget.height,
              ),
            ),
          ),
      ],
    );
  }

  Offset get _actionOffset => switch (widget.actionDirection) {
    PillActionDirection.below => const Offset(0, 0.3),
    PillActionDirection.above => const Offset(0, -0.3),
    PillActionDirection.right => const Offset(0.15, 0),
    PillActionDirection.left => const Offset(-0.15, 0),
  };
}

class _ActionButtonsRow extends StatelessWidget {
  final PillActionDirection direction;
  final VoidCallback onCorrect;
  final VoidCallback onWrong;
  final VoidCallback onCancel;
  final double baseSize;

  const _ActionButtonsRow({
    required this.direction,
    required this.onCorrect,
    required this.onWrong,
    required this.onCancel,
    required this.baseSize,
  });

  @override
  Widget build(BuildContext context) {
    final isVertical =
        direction == PillActionDirection.left || direction == PillActionDirection.right;

    const mainBtnSize = AppTheme.gameActionButtonSize;
    const cancelBtnSize = AppTheme.gameActionButtonSize;
    final gap = baseSize * 0.08;

    final buttons = [
      _MiniBtn(color: AppColors.success, icon: Icons.check, onTap: onCorrect, size: mainBtnSize),
      SizedBox(width: gap, height: gap),
      _MiniBtn(color: AppColors.error, icon: Icons.close, onTap: onWrong, size: mainBtnSize),
      SizedBox(width: gap, height: gap),
      _MiniBtn(color: AppColors.neutralGray, icon: Icons.close, onTap: onCancel, size: cancelBtnSize),
    ];

    return Container(
      padding: EdgeInsets.all(gap),
      decoration: BoxDecoration(
        color: AppColors.charcoal.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)),
      ),
      child: isVertical
          ? Column(mainAxisSize: MainAxisSize.min, children: buttons)
          : Row(mainAxisSize: MainAxisSize.min, children: buttons),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _MiniBtn({required this.color, required this.icon, required this.onTap, required this.size});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        child: Icon(icon, color: Colors.white, size: size * 0.6),
      ),
    );
  }
}
