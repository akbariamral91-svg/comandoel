import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gold_button.dart';
import 'setup_screen.dart';
import 'settings_screen.dart';

/// صفحه‌ی شروع - سوار بر عکس پس‌زمینه‌ی جنگل (که خودش اسم «کوماندوئل» را در خود دارد)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late AudioService _audioService;

  @override
  void initState() {
    super.initState();
    // صفحه شروع فقط عمودی است
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    _audioService = AudioService();
    
    // موسیقی را شروع کن (با توجه به تنظیمات کاربر)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider = context.read<SettingsProvider>();
      _audioService.setMusicEnabled(settingsProvider.isMusicOn);
      // سطح صدا را به 0.4 تنظیم کن (40% از صدای پیش‌فرض)
      _audioService.setVolume(0.4);
    });
  }

  @override
  void dispose() {
    // موسیقی را متوقف نکنیم زیرا بین صفحات باید ادامه یابد
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/images/bg_home_forest.png', fit: BoxFit.fill),

              // زیرنویس - دقیقاً زیر اسم «کوماندوئل» که در خود عکس نوشته شده
              Positioned(
                left: 0,
                right: 0,
                top: 0.312 * h,
                child: const Text(
                  'بازی حدس و هوش',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                  ),
                ),
              ),

              SafeArea(
                child: Stack(
                  children: [
                    // دکمه تنظیمات - بالا راست
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GoldIconButton(
                        icon: Icons.settings,
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierColor: Colors.black87,
                            builder: (_) => const SettingsSheet(),
                          );
                        },
                      ),
                    ),

                    // دکمه پشتیبانی - بالا چپ
                    Positioned(
                      top: 12,
                      left: 12,
                      child: GoldIconButton(
                        icon: Icons.headset_mic_outlined,
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierColor: Colors.black87,
                            builder: (_) => const SettingsSheet(initialTabSupport: true),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // دکمه شروع بازی - وسط پایین صفحه، روی مسیر جنگل
              Positioned(
                left: 0,
                right: 0,
                bottom: 0.14 * h,
                child: Center(
                  child: SizedBox(
                    width: 0.62 * w,
                    height: AppTheme.primaryButtonHeight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SetupScreen()),
                        );
                      },
                      child: Image.asset(
                        'assets/images/btn_start_game.png',
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.contain,
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
}
