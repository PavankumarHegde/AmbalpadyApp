import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this for SystemChrome
import 'package:flutter_localizations/flutter_localizations.dart';
import 'Config/Localization/AppLocalizations.dart';
import 'Config/Theme/AppTheme.dart';
import 'SplashScreen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Set the status bar color and icon brightness
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppTheme.primaryRed,         // Red bar to match branding
      statusBarIconBrightness: Brightness.light,   // White icons
    ),
  );

  runApp(const AmbalpadyApp());
}

class AmbalpadyApp extends StatelessWidget {
  const AmbalpadyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClubIgnite App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      supportedLocales: const [
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first;
      },
      home: const SplashScreen(),
    );
  }
}
