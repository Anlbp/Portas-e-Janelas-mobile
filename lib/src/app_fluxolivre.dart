import 'package:app_fluxolivre/src/pages/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppFluxolivre extends StatelessWidget {
  const AppFluxolivre({super.key});

  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    splashColor: Colors.black26,
    highlightColor: Colors.black12,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D79FF)),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        overlayColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return Colors.black26;
          }
          if (states.contains(WidgetState.hovered)) {
            return Colors.black12;
          }
          return Colors.transparent;
        }),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return Colors.black26;
          }
          return Colors.transparent;
        }),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return Colors.black26;
          }
          return Colors.transparent;
        }),
      ),
    ),
  );

  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    splashColor: const Color(0x3FFFFFFF),
    highlightColor: const Color(0x14FFFFFF),
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFF2D79FF),
      secondary: const Color(0xFF2D79FF),
      surface: const Color(0xFF121212),
      onSurface: Colors.white,
      onSurfaceVariant: const Color(0xFFB0B0B0),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        overlayColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return const Color(0x40FFFFFF);
          }
          if (states.contains(WidgetState.hovered)) {
            return const Color(0x20FFFFFF);
          }
          return Colors.transparent;
        }),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return const Color(0x40FFFFFF);
          }
          return Colors.transparent;
        }),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return const Color(0x33FFFFFF);
          }
          return Colors.transparent;
        }),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AppFluxoLivre',
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashPage(),
    );
  }
}
