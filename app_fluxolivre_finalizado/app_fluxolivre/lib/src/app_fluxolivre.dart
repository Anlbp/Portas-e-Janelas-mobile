import 'package:app_fluxolivre/src/pages/home_page.dart';
import 'package:app_fluxolivre/src/pages/login_page.dart';
import 'package:flutter/material.dart';

class AppFluxolivre extends StatelessWidget {
  const AppFluxolivre({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "AppFluxoLivre",
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginPage(),
        '/': (_) => const HomePage(),
      },
    );
  }
}
