import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/player.dart';
import '../models/game_settings.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import 'game_screen.dart';

/// صفحه‌ی ساخت محیط بازی - سوار بر عکس «panel_setup_parchment» که خودش شامل
/// جنگل + تابلوی «ساخت محیط بازی» + سه پنل پارچمنتی (تعداد بازیکن / اعضا / تعداد دست) است.
/// مختصات هر پنل با تحلیل پیکسلی دقیق از روی خود عکس استخراج شده.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int playerCount = 4;
  int roundsCount = 3;
  NarratorSelectionMode narratorMode = NarratorSelectionMode.random;
  String? manualNarratorId;

  final List<TextEditingController> _nameControllers = [];

  @override
  void initState() {
    super.initState();
    _syncControllers();
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
    for (final c in _nameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _namesValid {
    for (final c in _nameControllers) {
      final name = c.text.trim();
      if (name.isEmpty || name.length > 20) return false;
    }
    return true;
  }

  void _startGame() async {
    if (!_namesValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اسم هر بازیکن نباید خالی باشد و باید کمتر از ۲۰ کاراکتر باشد',
              textAlign: TextAlign.right),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final players = List.generate(playerCount, (i) {
      return Player(
        id: 'p$i-${DateTime.now().microsecondsSinceEpoch}',
        name: _nameControllers[i].text.trim(),
        avatarColor: Player.defaultAvatarColors[i % Player.defaultAvatarColors.length],
      );
    });

    String? resolvedNarratorId;
    if (narratorMode == NarratorSelectionMode.manual && manualNarratorId != null) {
      final idx = int.parse(manualNarratorId!.replaceFirst('idx', ''));
      if (idx >= 0 && idx < players.length) resolvedNarratorId = players[idx].id;
    }

    final settings = GameSettings(
      roundsCount: roundsCount,
      narratorMode: narratorMode,
      manualNarratorId: narratorMode == NarratorSelectionMode.manual
          ? (resolvedNarratorId ?? players.first.id)
          : null,
    );

    final gameProvider = context.read<GameProvider>();
    await gameProvider.setupGame(gamePlayers: players, settings: settings);

    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const GameScreen()));
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
        title: const Text('انتخاب راوی',
            textAlign: TextAlign.right,
            style: TextStyle(fontFamily: 'Vazirmatn', color: AppColors.gold, fontWeight: FontWeight.w700)),
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
                  backgroundColor: Player.defaultAvatarColors[i % Player.defaultAvatarColors.length],
                ),
                title: Text(name,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontFamily: 'Vazirmatn', color: Colors.white)),
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
        title: const Text('راهنمای بازی',
            textAlign: TextAlign.right,
            style: TextStyle(fontFamily: 'Vazirmatn', color: AppColors.gold, fontWeight: FontWeight.w700)),
        content: const Text(
          'یک نفر به عنوان راوی انتخاب می‌شود و خودش جواب نمی‌دهد. راوی سوال را نمایش می‌دهد و ۷ ثانیه فرصت هست تا بازیکنان جواب بدهند. '
          'هرکس زودتر جواب داد، راوی روی نام او می‌زند و درست یا غلط بودن جواب را با دکمه‌ی سبز یا قرمز مشخص می‌کند. '
          'جواب‌های سریع‌تر از ۳ ثانیه ۷ امتیاز و بقیه ۵ امتیاز می‌گیرند. هر دست شامل ۵ سوال است.',
          textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white70, height: 1.8),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('متوجه شدم', style: TextStyle(fontFamily: 'Vazirmatn', color: AppColors.gold)),
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
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/images/panel_setup_parchment.png', fit: BoxFit.fill),

              SafeArea(
                child: Stack(
                  children: [
                    // دکمه برگشت - بالا چپ
                    Positioned(
                      top: 8,
                      left: 8,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Image.asset('assets/images/btn_back.png', width: 0.11 * w),
                      ),
                    ),

                    // پنل ۱: تعداد بازیکنان (۱۴.۶٪-۸۵.۲٪ عرض, ۲۴.۵٪-۳۷.۸٪ ارتفاع)
                    Positioned(
                      left: 0.146 * w,
                      top: 0.245 * h,
                      width: 0.706 * w,
                      height: 0.133 * h,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('تعداد بازیکنان',
                                style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: Color(0xFF5C3A15))),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _CounterBtn(
                                  asset: 'assets/images/btn_minus.png',
                                  onTap: playerCount > 2
                                      ? () => setState(() {
                                            playerCount--;
                                            if (manualNarratorId != null) {
                                              final idx = int.parse(
                                                  manualNarratorId!.replaceFirst('idx', ''));
                                              if (idx >= playerCount) manualNarratorId = null;
                                            }
                                          })
                                      : null,
                                ),
                                Container(
                                  width: 54,
                                  alignment: Alignment.center,
                                  child: Text('$playerCount',
                                      style: const TextStyle(
                                          fontFamily: 'Vazirmatn',
                                          fontWeight: FontWeight.w900,
                                          fontSize: 24,
                                          color: Color(0xFF5C3A15))),
                                ),
                                _CounterBtn(
                                  asset: 'assets/images/btn_plus.png',
                                  onTap: playerCount < 10
                                      ? () => setState(() => playerCount++)
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // پنل ۲: اسامی بازیکنان (۱۴.۹٪-۸۵٪ عرض, ۳۹.۱٪-۶۹.۸٪ ارتفاع) - اسکرول‌پذیر
                    Positioned(
                      left: 0.149 * w,
                      top: 0.391 * h,
                      width: 0.701 * w,
                      height: 0.307 * h,
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 0.02 * w, vertical: 0.01 * h),
                        itemCount: playerCount,
                        itemBuilder: (context, i) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 0.006 * h),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 9,
                                backgroundColor:
                                    Player.defaultAvatarColors[i % Player.defaultAvatarColors.length],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _nameControllers[i],
                                  maxLength: 20,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontFamily: 'Vazirmatn', color: Color(0xFF3B2410), fontSize: 13),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    isDense: true,
                                    hintText: 'اسم بازیکن ${i + 1}',
                                    hintStyle: const TextStyle(fontFamily: 'Vazirmatn', color: Colors.brown),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.35),
                                    contentPadding:
                                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.brown.withOpacity(0.4)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // پنل ۳: تعداد دست + انتخاب راوی (کنار هم، برای صرفه‌جویی در فضای عمودی)
                    Positioned(
                      left: 0.150 * w,
                      top: 0.710 * h,
                      width: 0.699 * w,
                      height: 0.135 * h,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('تعداد دست',
                                    style: TextStyle(
                                        fontFamily: 'Vazirmatn',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: Color(0xFF5C3A15))),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _CounterBtn(
                                      asset: 'assets/images/btn_minus.png',
                                      onTap: roundsCount > 1 ? () => setState(() => roundsCount--) : null,
                                    ),
                                    Container(
                                      width: 40,
                                      alignment: Alignment.center,
                                      child: Text('$roundsCount',
                                          style: const TextStyle(
                                              fontFamily: 'Vazirmatn',
                                              fontWeight: FontWeight.w900,
                                              fontSize: 20,
                                              color: Color(0xFF5C3A15))),
                                    ),
                                    _CounterBtn(
                                      asset: 'assets/images/btn_plus.png',
                                      onTap: roundsCount < 10 ? () => setState(() => roundsCount++) : null,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 0.08 * h, color: Colors.brown.withOpacity(0.3)),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('راوی',
                                    style: TextStyle(
                                        fontFamily: 'Vazirmatn',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: Color(0xFF5C3A15))),
                                const SizedBox(height: 4),
                                _NarratorChip(
                                  label: 'شانسی',
                                  selected: narratorMode == NarratorSelectionMode.random,
                                  onTap: () => setState(() {
                                    narratorMode = NarratorSelectionMode.random;
                                    manualNarratorId = null;
                                  }),
                                ),
                                const SizedBox(height: 4),
                                Builder(builder: (context) {
                                  String label = 'انتخاب بازیکن';
                                  if (manualNarratorId != null) {
                                    final idx = int.parse(manualNarratorId!.replaceFirst('idx', ''));
                                    final name = _nameControllers[idx].text.trim();
                                    if (name.isNotEmpty) label = name;
                                  }
                                  return _NarratorChip(
                                    label: label,
                                    selected: narratorMode == NarratorSelectionMode.manual,
                                    onTap: () async {
                                      setState(() => narratorMode = NarratorSelectionMode.manual);
                                      await _pickManualNarrator();
                                    },
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // دکمه‌های پایین: راهنما + شروع بازی، کنار هم برای صرفه‌جویی در فضا
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0.015 * h,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: _showHelp,
                            child: Image.asset('assets/images/btn_help_pill.png', width: 0.24 * w),
                          ),
                          SizedBox(width: 0.03 * w),
                          GestureDetector(
                            onTap: _startGame,
                            child: Image.asset('assets/images/btn_start_game.png', width: 0.42 * w),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CounterBtn extends StatelessWidget {
  final String asset;
  final VoidCallback? onTap;
  const _CounterBtn({required this.asset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1.0,
        child: Image.asset(asset, width: 40),
      ),
    );
  }
}

class _NarratorChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NarratorChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.gold.withOpacity(0.85) : Colors.white.withOpacity(0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.brown.withOpacity(0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontWeight: FontWeight.w700,
            fontSize: 11,
            color: selected ? AppColors.black : const Color(0xFF5C3A15),
          ),
        ),
      ),
    );
  }
}
