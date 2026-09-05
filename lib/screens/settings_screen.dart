import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../services/audio_service.dart';

/// پنجره تنظیمات - سوار بر عکس زیرآبی (که خودش قاب گرد آبی رنگ دارد).
/// دکمه‌ها طوری چیده شده‌اند که روی موجود پشمالو یا یادداشت ماهی نیفتند:
/// آن دو المان تقریباً در ستون میانی-پایین عکس هستند، پس کنترل‌ها در
/// نوار بالا (خالی) و ستون چپ (خالی) قرار می‌گیرند.
class SettingsSheet extends StatefulWidget {
  final bool initialTabSupport;
  const SettingsSheet({super.key, this.initialTabSupport = false});

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late bool showSupport;

  @override
  void initState() {
    super.initState();
    showSupport = widget.initialTabSupport;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final screenW = MediaQuery.of(context).size.width;
    final cardWidth = screenW * 0.86;
    // نسبت واقعی عکس (۱۲۸۶×۱۲۲۳) حفظ می‌شود تا با BoxFit.fill هیچ بریدگی یا
    // جابه‌جایی نسبت به مختصات درصدی محاسبه‌شده رخ ندهد.
    const imageAspectRatio = 1286 / 1223;

    return Center(
      child: SizedBox(
        width: cardWidth,
        child: AspectRatio(
          aspectRatio: imageAspectRatio,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              return Stack(
                children: [
                  Image.asset('assets/images/bg_settings_underwater.png', fit: BoxFit.fill),

                // دکمه بستن - بالا راست (ناحیه‌ی کاملاً خالی آب)
                Positioned(
                  top: 0.05 * h,
                  right: 0.06 * w,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: math.max(48.0, 0.09 * w),
                      height: math.max(48.0, 0.09 * w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.85),
                        border: Border.all(color: Colors.blue.shade900, width: 1.4),
                      ),
                      child: Icon(Icons.close, color: Colors.blue.shade900, size: 0.05 * w),
                    ),
                  ),
                ),

                // عنوان + موسیقی - نوار بالا (ناحیه‌ی خالی آب، بالای یادداشت و حباب)
                Positioned(
                  top: 0.07 * h,
                  left: 0.06 * w,
                  width: 0.55 * w,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تنظیمات',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontWeight: FontWeight.w900,
                          fontSize: 0.05 * w,
                          color: Colors.white,
                          shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
                        ),
                      ),
                      SizedBox(height: 0.02 * h),
                      GestureDetector(
                        onTap: () {
                          // SettingsProvider رو اپدیت کن
                          settings.toggleMusic();
                          // AudioService رو بروز کن
                          AudioService().setMusicEnabled(settings.isMusicOn);
                        },
                        child: Container(
                          constraints: const BoxConstraints(minHeight: AppTheme.minTouchTarget),
                          padding: EdgeInsets.symmetric(horizontal: 0.03 * w, vertical: 0.018 * h),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                settings.isMusicOn ? Icons.music_note : Icons.music_off,
                                color: Colors.blue.shade800,
                                size: 0.045 * w,
                              ),
                              SizedBox(width: 0.02 * w),
                              Text('موسیقی',
                                  style: TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 0.032 * w,
                                      color: Colors.blue.shade900)),
                              SizedBox(width: 0.02 * w),
                              Switch(
                                value: settings.isMusicOn,
                                activeColor: Colors.blue.shade700,
                                onChanged: (_) {
                                  // SettingsProvider رو اپدیت کن
                                  settings.toggleMusic();
                                  // AudioService رو بروز کن
                                  AudioService().setMusicEnabled(settings.isMusicOn);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // پشتیبانی - ستون چپ (ناحیه‌ی خالی آب، سمت چپ یادداشت و حباب)
                Positioned(
                  top: 0.30 * h,
                  left: 0.06 * w,
                  width: 0.42 * w,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => showSupport = !showSupport),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: AppTheme.minTouchTarget),
                          padding: EdgeInsets.symmetric(horizontal: 0.03 * w, vertical: 0.018 * h),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.headset_mic_outlined, color: Colors.blue.shade800, size: 0.045 * w),
                              SizedBox(width: 0.02 * w),
                              Text('پشتیبانی',
                                  style: TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 0.032 * w,
                                      color: Colors.blue.shade900)),
                              Icon(
                                showSupport ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: Colors.blue.shade800,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (showSupport)
                        Container(
                          margin: EdgeInsets.only(top: 0.015 * h),
                          padding: EdgeInsets.all(0.025 * w),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'برای ارتباط با پشتیبانی کوماندوئل:\n@KomandoelSupport\nsupport@komandoel.app',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 0.026 * w,
                              height: 1.7,
                              color: Colors.blue.shade900,
                            ),
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
    ),
    );
  }
}
