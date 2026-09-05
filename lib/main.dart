import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'providers/game_provider.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // پیش‌فرض کل برنامه عمودی است. فقط دو صفحه‌ی «بازی» و «پایان بازی» به افقی تغییر می‌کنند.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const KomandoelApp());
}

class KomandoelApp extends StatelessWidget {
  const KomandoelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
      ],
      child: MaterialApp(
        title: 'کوماندوئل',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        locale: const Locale('fa', 'IR'),
        supportedLocales: const [Locale('fa', 'IR'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const HomeScreen(),
      ),
    );
  }
}
