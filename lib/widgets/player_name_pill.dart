import 'package:flutter/material.dart';
import '../models/player.dart';
import '../providers/game_provider.dart' show ScoreEvent;
import '../theme/app_theme.dart';

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

  Alignment get _actionAlignment {
    switch (widget.actionDirection) {
      case PillActionDirection.below:
        return Alignment.topCenter;
      case PillActionDirection.above:
        return Alignment.bottomCenter;
      case PillActionDirection.right:
        return Alignment.centerLeft;
      case PillActionDirection.left:
        return Alignment.centerRight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocked = widget.player.isBlockedForCurrentQuestion;
    final disabled = blocked || widget.isNarrator;

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
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: widget.player.avatarColor.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(widget.height / 2),
                border: Border.all(
                  color: widget.isSelected
                      ? AppColors.brightGold
                      : (widget.isLeader ? AppColors.brightGold : Colors.black87),
                  width: widget.isSelected || widget.isLeader ? 2.4 : 1.4,
                ),
                boxShadow: [
                  if (widget.isSelected)
                    BoxShadow(color: AppColors.brightGold.withValues(alpha: 0.6), blurRadius: 12, spreadRadius: 1),
                  const BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.isLeader)
                        Padding(
                          padding: const EdgeInsets.only(left: 3),
                          child: Icon(Icons.emoji_events,
                              color: AppColors.brightGold, size: widget.height * 0.34),
                        ),
                      Flexible(
                        child: Text(
                          widget.player.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontWeight: FontWeight.w700,
                            fontSize: widget.height * 0.30,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: widget.width * 0.03),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 250),
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontWeight: FontWeight.w900,
                          fontSize: widget.height * 0.32,
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

        if (_flashGreen && widget.scoreEvent != null)
          Positioned(
            top: -widget.height * 0.5,
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

  Offset get _actionOffset {
    switch (widget.actionDirection) {
      case PillActionDirection.below:
        return const Offset(0, 0.3);
      case PillActionDirection.above:
        return const Offset(0, -0.3);
      case PillActionDirection.right:
        return const Offset(0.15, 0);
      case PillActionDirection.left:
        return const Offset(-0.15, 0);
    }
  }
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
