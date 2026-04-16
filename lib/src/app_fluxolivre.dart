import 'package:app_fluxolivre/src/pages/splash_page.dart';
import 'package:flutter/material.dart';

class AppFluxolivre extends StatelessWidget {
  const AppFluxolivre({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "AppFluxoLivre",
      home: const SplashPage(),
    );
  }
}
