import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/game_settings.dart';
import '../models/player.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import 'game_screen.dart';

/// صفحه ساخت محیط بازی.
///
/// پس‌زمینه فقط محیط جنگل و تابلوی عنوان را نشان می‌دهد.
/// تمام پنل‌های کرمی، ورودی‌ها و کنترل‌ها به‌صورت Widget واقعی ساخته می‌شوند
/// تا روی نسبت‌های مختلف صفحه قابل‌اعتماد و قابل‌اسکرول باشند.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int playerCount = 4;
  int roundsCount = 3;
  String? manualNarratorId;

  final List<TextEditingController> _nameControllers = [];

  @override
  void initState() {
    super.initState();
    _syncControllers();
    
    // صفحه ست آپ فقط عمودی است
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // موسیقی ادامه می‌یابد (به SetupScreen منتقل شده)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider = context.read<SettingsProvider>();
      final audioService = AudioService();
      audioService.setMusicEnabled(settingsProvider.isMusicOn);
      audioService.setVolume(0.4); // 40% صدای پیش‌فرض
    });
  }

  void _syncControllers() {
    while (_nameControllers.length < playerCount) {
      _nameControllers.add(TextEditingController());
    }
    while (_nameControllers.length > playerCount) {
      _nameControllers.removeLast().dispose();
    }
  }

  @override
  void dispose() {
    for (final controller in _nameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _namesValid {
    for (final controller in _nameControllers) {
      final name = controller.text.trim();
      if (name.isEmpty || name.length > 20) return false;
    }
    return true;
  }

  void _startGame() async {
    // راوی باید قبل از هر چیز انتخاب شده باشد؛ بنابراین اگر کاربر بدون انتخاب راوی
    // روی «شروع بازی» بزند، همین پیام را می‌بیند.
    if (manualNarratorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لطفاً راوی را انتخاب کنید',
            textAlign: TextAlign.right,
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_namesValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'اسم هر بازیکن نباید خالی باشد و باید کمتر از ۲۰ کاراکتر باشد',
            textAlign: TextAlign.right,
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final narratorIndex = int.tryParse(
      manualNarratorId!.replaceFirst('idx', ''),
    );
    if (narratorIndex == null ||
        narratorIndex < 0 ||
        narratorIndex >= playerCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لطفاً راوی را انتخاب کنید',
            textAlign: TextAlign.right,
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final players = List.generate(playerCount, (i) {
      return Player(
        id: 'p$i-${DateTime.now().microsecondsSinceEpoch}',
        name: _nameControllers[i].text.trim(),
        avatarColor:
            Player.defaultAvatarColors[i % Player.defaultAvatarColors.length],
      );
    });

    final settings = GameSettings(
      roundsCount: roundsCount,
      narratorMode: NarratorSelectionMode.manual,
      manualNarratorId: players[narratorIndex].id,
    );

    final gameProvider = context.read<GameProvider>();
    await gameProvider.setupGame(gamePlayers: players, settings: settings);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GameScreen()),
      );
    }
  }

  Future<void> _pickManualNarrator() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.gold),
        ),
        title: const Text(
          'انتخاب راوی',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            color: AppColors.gold,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: playerCount,
            itemBuilder: (context, i) {
              final name = _nameControllers[i].text.trim().isEmpty
                  ? 'بازیکن ${i + 1}'
                  : _nameControllers[i].text.trim();
              return ListTile(
                leading: CircleAvatar(
                  radius: 10,
                  backgroundColor: Player.defaultAvatarColors[
                      i % Player.defaultAvatarColors.length],
                ),
                title: Text(
                  name,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    color: Colors.white,
                  ),
                ),
                onTap: () => Navigator.pop(dialogContext, 'idx$i'),
              );
            },
          ),
        ),
      ),
    );

    if (selected != null) {
      setState(() => manualNarratorId = selected);
    }
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.gold),
        ),
        title: const Text(
          'راهنمای بازی',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            color: AppColors.gold,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'یک نفر به عنوان راوی انتخاب می‌شود و خودش جواب نمی‌دهد. راوی سوال را نمایش می‌دهد و ۷ ثانیه فرصت هست تا بازیکنان جواب بدهند. '
          'هرکس زودتر جواب داد، راوی روی نام او می‌زند و درست یا غلط بودن جواب را با دکمه‌ی سبز یا قرمز مشخص می‌کند. '
          'جواب‌های سریع‌تر از ۳ ثانیه ۷ امتیاز و بقیه ۵ امتیاز می‌گیرند. هر دست شامل ۵ سوال است.',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            color: Colors.white70,
            height: 1.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'متوجه شدم',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                color: AppColors.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _syncControllers();

    return Scaffold(
      backgroundColor: AppColors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          final isVeryNarrow = screenWidth < 350;

          // همه پنل‌ها یک عرض مشترک دارند؛ روی تبلت بیش از حد بزرگ نمی‌شوند.
          final panelWidth = math.min(
            600.0,
            math.max(
              300.0,
              screenWidth * 0.74,
            ),
          ).clamp(0.0, math.max(0.0, screenWidth - 24.0)).toDouble();
          final horizontalPadding = math.max(
            12.0,
            (screenWidth - panelWidth) / 2,
          );

          // فضای بالای محتوا نسبت به طرح اصلی صفحه حفظ می‌شود، اما از اینجا
          // به بعد ارتفاع پنل‌ها توسط محتوای واقعی Flutter تعیین می‌شود.
          final topSpace = math.min(
            math.max(150.0, screenHeight * 0.215),
            330.0,
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              // کاربر این فایل را با نسخه‌ی جدیدِ فقط-پس‌زمینه، با همان نام
              // panel_setup_parchment.png جایگزین خواهد کرد.
              Image.asset(
                'assets/images/panel_setup_parchment.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),

              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    top: topSpace,
                    left: horizontalPadding,
                    right: horizontalPadding,
                    bottom: math.max(24.0, screenHeight * 0.025),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: panelWidth),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _PlayersCountPanel(
                            width: panelWidth,
                            playerCount: playerCount,
                            onDecrease: playerCount > 2
                                ? () => setState(() {
                                      playerCount--;
                                      if (manualNarratorId != null) {
                                        final idx = int.tryParse(
                                          manualNarratorId!.replaceFirst('idx', ''),
                                        );
                                        // بازیکنی که هنگام کم‌کردن تعداد حذف می‌شود همیشه
                                        // آخرین نفر (اندیس playerCount جدید) است؛ پس فقط وقتی
                                        // راوی باید ریست شود که دقیقاً همان نفر بوده باشد، نه
                                        // یکی قبل از او (idx == playerCount هم درست است، نه
                                        // idx == playerCount - 1).
                                        if (idx == null || idx >= playerCount) {
                                          manualNarratorId = null;
                                        }
                                      }
                                      _syncControllers();
                                    })
                                : null,
                            onIncrease: playerCount < 10
                                ? () => setState(() {
                                      playerCount++;
                                      _syncControllers();
                                    })
                                : null,
                          ),
                          SizedBox(height: isVeryNarrow ? 10 : 14),
                          _PlayersPanel(
                            width: panelWidth,
                            controllers: _nameControllers,
                            playerCount: playerCount,
                            narratorIndex: _selectedNarratorIndex,
                          ),
                          SizedBox(height: isVeryNarrow ? 10 : 14),
                          _NarratorRoundsPanel(
                            width: panelWidth,
                            roundsCount: roundsCount,
                            manualNarratorLabel: _manualNarratorLabel,
                            onRoundsDecrease: roundsCount > 1
                                ? () => setState(() => roundsCount--)
                                : null,
                            onRoundsIncrease: roundsCount < 10
                                ? () => setState(() => roundsCount++)
                                : null,
                            onSelectNarrator: _pickManualNarrator,
                          ),
                          SizedBox(height: isVeryNarrow ? 18 : 24),
                          _BottomActions(
                            width: panelWidth,
                            onHelp: _showHelp,
                            onStart: _startGame,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // دکمه برگشت مستقل از محتوای اسکرول است و همیشه در جای امن بالای صفحه می‌ماند.
              SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Image.asset(
                        'assets/images/btn_back.png',
                        width: (screenWidth * 0.11).clamp(48.0, 58.0),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  int? get _selectedNarratorIndex {
    if (manualNarratorId == null) return null;
    return int.tryParse(manualNarratorId!.replaceFirst('idx', ''));
  }

  String get _manualNarratorLabel {
    if (manualNarratorId == null) return 'انتخاب راوی';
    final idx = int.parse(manualNarratorId!.replaceFirst('idx', ''));
    if (idx < 0 || idx >= _nameControllers.length) return 'انتخاب راوی';
    final name = _nameControllers[idx].text.trim();
    return name.isEmpty ? 'بازیکن ${idx + 1}' : name;
  }
}

/// قاب اصلی کرمی‌رنگ که قبلاً بخشی از تصویر پس‌زمینه بود.
class _ParchmentPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double minHeight;

  const _ParchmentPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.minHeight = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFE9B5),
            Color(0xFFF6DFA5),
            Color(0xFFEED093),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF7A4A1B),
          width: 3,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
          BoxShadow(
            color: Color(0x66FFF0BD),
            blurRadius: 2,
            spreadRadius: 1,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(5),
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(21),
          border: Border.all(
            color: const Color(0x557A4A1B),
            width: 1,
          ),
        ),
        child: child,
      ),
    );
  }
}

class _PlayersCountPanel extends StatelessWidget {
  final double width;
  final int playerCount;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  const _PlayersCountPanel({
    required this.width,
    required this.playerCount,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    final titleSize = (width * 0.043).clamp(15.0, 22.0);
    final numberSize = (width * 0.065).clamp(23.0, 34.0);
    final counterButtonSize = (width * 0.095).clamp(48.0, 54.0);

    return _ParchmentPanel(
      minHeight: math.max(150.0, width * 0.42),
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.04,
        vertical: 12,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'تعداد بازیکنان',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontWeight: FontWeight.w700,
                fontSize: titleSize,
                color: const Color(0xFF5C3A15),
              ),
            ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CounterBtn(
                asset: 'assets/images/btn_minus.png',
                size: counterButtonSize,
                onTap: onDecrease,
              ),
              SizedBox(width: width * 0.08),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$playerCount',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontWeight: FontWeight.w900,
                      fontSize: numberSize,
                      color: const Color(0xFF5C3A15),
                    ),
                  ),
                ),
              ),
              SizedBox(width: width * 0.08),
              _CounterBtn(
                asset: 'assets/images/btn_plus.png',
                size: counterButtonSize,
                onTap: onIncrease,
              ),
            ],
          ),
        ],
      ),
    ),
  );
  }
}

class _PlayersPanel extends StatelessWidget {
  final double width;
  final List<TextEditingController> controllers;
  final int playerCount;
  final int? narratorIndex;

  const _PlayersPanel({
    required this.width,
    required this.controllers,
    required this.playerCount,
    required this.narratorIndex,
  });

  @override
  Widget build(BuildContext context) {
    final compact = width < 360;
    final rowHeight = compact ? 48.0 : 52.0;
    final fontSize = (width * 0.022).clamp(12.0, 15.0);
    final avatarRadius = (width * 0.018).clamp(8.0, 11.0);

    return _ParchmentPanel(
      minHeight: math.max(300.0, width * 0.90),
      padding: EdgeInsets.fromLTRB(
        width * 0.025,
        compact ? 8 : 10,
        width * 0.025,
        compact ? 8 : 10,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          // پنل در ۱۰ بازیکن هم جمع‌وجور می‌ماند و در صورت کوتاه بودن صفحه
          // خود صفحه به‌صورت کلی اسکرول می‌شود.
          maxHeight: compact ? 500 : 560,
        ),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemCount: playerCount - (narratorIndex == null ? 0 : 1),
          separatorBuilder: (_, __) => SizedBox(height: compact ? 5 : 7),
          itemBuilder: (context, visibleIndex) {
            int sourceIndex = visibleIndex;
            if (narratorIndex != null && sourceIndex >= narratorIndex!) {
              sourceIndex++;
            }
            return SizedBox(
              height: rowHeight,
              child: Row(
                textDirection: TextDirection.ltr,
                children: [
                  CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: Player.defaultAvatarColors[
                        sourceIndex % Player.defaultAvatarColors.length],
                  ),
                  SizedBox(width: compact ? 6 : 8),
                  Expanded(
                    child: TextField(
                      controller: controllers[sourceIndex],
                      maxLength: 20,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        color: const Color(0xFF3B2410),
                        fontSize: fontSize,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        isDense: true,
                        hintText: 'اسم بازیکن ${sourceIndex + 1}',
                        hintStyle: TextStyle(
                          fontFamily: 'Vazirmatn',
                          color: const Color(0xFF7A5A35),
                          fontSize: fontSize,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.34),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: compact ? 9 : 11,
                          vertical: compact ? 8 : 9,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: const Color(0x997A4A1B),
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: const Color(0x667A4A1B),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF9A641F),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NarratorRoundsPanel extends StatelessWidget {
  final double width;
  final int roundsCount;
  final String manualNarratorLabel;
  final VoidCallback? onRoundsDecrease;
  final VoidCallback? onRoundsIncrease;
  final VoidCallback onSelectNarrator;

  const _NarratorRoundsPanel({
    required this.width,
    required this.roundsCount,
    required this.manualNarratorLabel,
    required this.onRoundsDecrease,
    required this.onRoundsIncrease,
    required this.onSelectNarrator,
  });

  @override
  Widget build(BuildContext context) {
    final compact = width < 370;
    final titleSize = (width * 0.034).clamp(12.0, 17.0);
    final numberSize = (width * 0.05).clamp(18.0, 28.0);
    final counterSize = (width * 0.07).clamp(48.0, 52.0);

    return _ParchmentPanel(
      minHeight: math.max(150.0, width * 0.42),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 10 : 13,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _RoundsColumn(
              titleSize: titleSize,
              numberSize: numberSize,
              counterSize: counterSize,
              roundsCount: roundsCount,
              onDecrease: onRoundsDecrease,
              onIncrease: onRoundsIncrease,
            ),
          ),
          Container(
            width: 1,
            height: compact ? 92 : 112,
            margin: EdgeInsets.symmetric(horizontal: compact ? 7 : 10),
            color: const Color(0x557A4A1B),
          ),
          Expanded(
            child: _NarratorColumn(
              titleSize: titleSize,
              manualNarratorLabel: manualNarratorLabel,
              onSelect: onSelectNarrator,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundsColumn extends StatelessWidget {
  final double titleSize;
  final double numberSize;
  final double counterSize;
  final int roundsCount;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  const _RoundsColumn({
    required this.titleSize,
    required this.numberSize,
    required this.counterSize,
    required this.roundsCount,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'تعداد دست',
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontWeight: FontWeight.w700,
            fontSize: titleSize,
            color: const Color(0xFF5C3A15),
          ),
        ),
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CounterBtn(
              asset: 'assets/images/btn_minus.png',
              size: counterSize,
              onTap: onDecrease,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$roundsCount',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontWeight: FontWeight.w900,
                    fontSize: numberSize,
                    color: const Color(0xFF5C3A15),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            _CounterBtn(
              asset: 'assets/images/btn_plus.png',
              size: counterSize,
              onTap: onIncrease,
            ),
          ],
        ),
      ],
    );
  }
}

class _NarratorColumn extends StatelessWidget {
  final double titleSize;
  final String manualNarratorLabel;
  final VoidCallback onSelect;

  const _NarratorColumn({
    required this.titleSize,
    required this.manualNarratorLabel,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final hasNarrator = manualNarratorLabel != 'انتخاب راوی';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'راوی',
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontWeight: FontWeight.w700,
            fontSize: titleSize,
            color: const Color(0xFF5C3A15),
          ),
        ),
        const SizedBox(height: 6),
        _NarratorChip(
          label: manualNarratorLabel,
          selected: hasNarrator,
          onTap: onSelect,
        ),
      ],
    );
  }
}

class _BottomActions extends StatelessWidget {
  final double width;
  final VoidCallback onHelp;
  final VoidCallback onStart;

  const _BottomActions({
    required this.width,
    required this.onHelp,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final actionsWidth = math.min(width, 470.0);

    return SizedBox(
      width: actionsWidth,
      child: Row(
        children: [
          Expanded(
            flex: 36,
            child: _ImageActionButton(
              asset: 'assets/images/btn_help_pill.png',
              height: AppTheme.secondaryButtonHeight,
              onTap: onHelp,
            ),
          ),
          SizedBox(width: math.max(8, actionsWidth * 0.035)),
          Expanded(
            flex: 64,
            child: _ImageActionButton(
              asset: 'assets/images/btn_start_game.png',
              height: AppTheme.primaryButtonHeight,
              onTap: onStart,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageActionButton extends StatelessWidget {
  final String asset;
  final double height;
  final VoidCallback onTap;

  const _ImageActionButton({
    required this.asset,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Image.asset(
              asset,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class _CounterBtn extends StatelessWidget {
  final String asset;
  final VoidCallback? onTap;
  final double size;

  const _CounterBtn({
    required this.asset,
    required this.onTap,
    this.size = AppTheme.minTouchTarget,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: math.max(size, AppTheme.minTouchTarget),
          height: math.max(size, AppTheme.minTouchTarget),
          child: Opacity(
            opacity: onTap == null ? 0.4 : 1.0,
            child: Image.asset(
              asset,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class _NarratorChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NarratorChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.gold.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.32),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0x887A4A1B),
                width: 1,
              ),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Vazirmatn',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Color(0xFF5C3A15),
              ).copyWith(
                color: selected ? AppColors.black : const Color(0xFF5C3A15),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
