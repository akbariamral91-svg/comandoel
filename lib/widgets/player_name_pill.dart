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
    this.width = 110,
    this.height = 40,
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
          onTap: disabled ? null : widget.onTap,
          child: AnimatedBuilder(
            animation: _popController,
            builder: (context, child) => Transform.scale(scale: _popScale.value, child: child),
            child: Container(
              width: widget.width,
              height: widget.height,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: widget.player.avatarColor.withOpacity(0.92),
                borderRadius: BorderRadius.circular(widget.height / 2),
                border: Border.all(
                  color: widget.isSelected
                      ? AppColors.brightGold
                      : (widget.isLeader ? AppColors.brightGold : Colors.black87),
                  width: widget.isSelected || widget.isLeader ? 2.4 : 1.4,
                ),
                boxShadow: [
                  if (widget.isSelected)
                    BoxShadow(color: AppColors.brightGold.withOpacity(0.6), blurRadius: 12, spreadRadius: 1),
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
                        const Padding(
                          padding: EdgeInsets.only(left: 3),
                          child: Icon(Icons.emoji_events, color: AppColors.brightGold, size: 13),
                        ),
                      Flexible(
                        child: Text(
                          widget.player.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 250),
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: _flashGreen ? AppColors.success : AppColors.brightGold,
                        ),
                        child: Text('${widget.player.score}'),
                      ),
                      if (widget.isNarrator)
                        const Padding(
                          padding: EdgeInsets.only(right: 3),
                          child: Icon(Icons.campaign, color: Colors.white70, size: 12),
                        ),
                    ],
                  ),
                  if (blocked)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(widget.height / 2),
                      ),
                      child: const Center(
                        child: Icon(Icons.close, color: AppColors.error, size: 16),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        if (_flashGreen && widget.scoreEvent != null)
          Positioned(
            top: -18,
            child: Text(
              '+${widget.scoreEvent!.points}',
              style: const TextStyle(
                fontFamily: 'Vazirmatn',
                fontWeight: FontWeight.w900,
                fontSize: 13,
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

  const _ActionButtonsRow({
    required this.direction,
    required this.onCorrect,
    required this.onWrong,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isVertical =
        direction == PillActionDirection.left || direction == PillActionDirection.right;

    final buttons = [
      _MiniBtn(color: AppColors.success, icon: Icons.check, onTap: onCorrect, size: 24),
      const SizedBox(width: 4, height: 4),
      _MiniBtn(color: AppColors.error, icon: Icons.close, onTap: onWrong, size: 24),
      const SizedBox(width: 4, height: 4),
      _MiniBtn(color: AppColors.neutralGray, icon: Icons.close, onTap: onCancel, size: 16),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.charcoal.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withOpacity(0.6)),
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
