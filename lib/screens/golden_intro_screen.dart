import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/gold_button.dart';
import 'game_screen.dart';

/// صفحه معرفی دور طلایی؛ فقط وقتی چند نفر در صدر جدول دقیقاً امتیاز و خطای
/// یکسان دارند نمایش داده می‌شود.
class GoldenIntroScreen extends StatefulWidget {
  const GoldenIntroScreen({super.key});

  @override
  State<GoldenIntroScreen> createState() => _GoldenIntroScreenState();
}

class _GoldenIntroScreenState extends State<GoldenIntroScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // موسیقی پس‌زمینه دیگر اینجا پخش نمی‌شود؛ فقط در Home و Setup پخش می‌شود.
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final players = game.goldenPlayers;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final shortest = w < h ? w : h;
            final titleSize = (shortest * 0.08).clamp(26.0, 38.0);
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/bg_result_forest.png',
                  fit: BoxFit.cover,
                ),
                Container(color: Colors.black.withValues(alpha: 0.24)),
                SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    (w * 0.07).clamp(18.0, 30.0),
                    (h * 0.07).clamp(28.0, 56.0),
                    (w * 0.07).clamp(18.0, 30.0),
                    (h * 0.05).clamp(20.0, 36.0),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'دور طلایی',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontWeight: FontWeight.w900,
                          fontSize: titleSize,
                          color: AppColors.brightGold,
                          shadows: const [Shadow(color: Colors.black87, blurRadius: 8)],
                        ),
                      ),
                      SizedBox(height: (h * 0.02).clamp(10.0, 18.0)),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all((shortest * 0.045).clamp(14.0, 22.0)),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4E4BD).withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.gold, width: 2),
                          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 14, offset: Offset(0, 6))],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'بازی به تساوی کامل رسیده!',
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontWeight: FontWeight.w900,
                                fontSize: (shortest * 0.045).clamp(16.0, 21.0),
                                color: const Color(0xFF4A3418),
                              ),
                            ),
                            SizedBox(height: (h * 0.014).clamp(8.0, 14.0)),
                            Text(
                              'این بازیکنان دور طلایی را بازی می‌کنند.\nهرکس فقط یک سؤال را درست جواب بدهد، برنده بازی است.\nاگر کسی جواب درست ندهد، سؤال بعدی نمایش داده می‌شود.',
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                height: 1.75,
                                fontSize: (shortest * 0.036).clamp(13.0, 17.0),
                                color: const Color(0xFF4A3418),
                              ),
                            ),
                            SizedBox(height: (h * 0.022).clamp(12.0, 20.0)),
                            ...players.map((p) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Container(
                                width: double.infinity,
                                constraints: const BoxConstraints(minHeight: 48),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: p.avatarColor.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: p.avatarColor.withValues(alpha: 0.75)),
                                ),
                                child: Row(
                                  textDirection: TextDirection.rtl,
                                  children: [
                                    CircleAvatar(
                                      radius: 15,
                                      backgroundColor: p.avatarColor,
                                      child: Text(
                                        p.name.isEmpty ? '' : p.name[0],
                                        style: const TextStyle(fontFamily: 'Vazirmatn', color: Colors.black, fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        p.name,
                                        textDirection: TextDirection.rtl,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.w800, color: Color(0xFF4A3418)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                          ],
                        ),
                      ),
                      SizedBox(height: (h * 0.025).clamp(14.0, 24.0)),
                      SizedBox(
                        width: (w * 0.78).clamp(220.0, 360.0),
                        height: AppTheme.primaryButtonHeight,
                        child: GoldButton(
                          text: 'شروع دور طلایی',
                          icon: Icons.local_fire_department_rounded,
                          height: AppTheme.primaryButtonHeight,
                          onPressed: () async {
                            await game.startGoldenRound();
                            if (!context.mounted) return;
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const GameScreen()),
                            );
                          },
                        ),
                      ),
                    ],
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
