import 'dart:async';
import 'dart:math' as math;

import 'package:app_fluxolivre/src/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// Exibe [iconmoving.mp4] da pasta `web/` e, ao terminar, abre o login.
///
/// Para melhor fluidez e nitidez: use MP4 **H.264** (perfil baseline ou main),
/// resolução próxima do ecrã (ex.: 1080 px na maior dimensão), bitrate moderado
/// e teste em **release** (`flutter run --release`) — em debug o vídeo costuma
/// engasgar-se.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const _assetPath = 'web/iconmoving.mp4';
  static const _splashCap = Duration(seconds: 6);
  /// Evita `addListener` a cada frame do vídeo (pesado); checa o fim poucas vezes por segundo.
  static const _endPollInterval = Duration(milliseconds: 200);

  VideoPlayerController? _controller;
  Timer? _maxWait;
  Timer? _endPoll;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
    );
    _maxWait = Timer(_splashCap, _goLogin);
    _initVideo();
  }

  void _restoreSystemUi() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: null,
        systemNavigationBarColor: null,
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.asset(
      _assetPath,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      // Primeiro frame na árvore antes de `play` reduz picos de trabalho no mesmo frame.
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || _navigated) return;
        await controller.play();
        _endPoll?.cancel();
        _endPoll = Timer.periodic(_endPollInterval, (_) => _checkVideoEnd());
      });
    } catch (_) {
      _goLogin();
    }
  }

  void _checkVideoEnd() {
    final c = _controller;
    if (c == null || _navigated) return;
    final v = c.value;
    if (v.hasError) {
      _goLogin();
      return;
    }
    if (!v.isInitialized) return;
    final d = v.duration;
    if (d == Duration.zero) return;
    if (v.position + const Duration(milliseconds: 150) >= d) {
      _goLogin();
    }
  }

  void _goLogin() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _maxWait?.cancel();
    _endPoll?.cancel();
    _controller?.pause();
    _restoreSystemUi();
    final navigator = Navigator.of(context);
    navigator.pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
    );
  }

  @override
  void dispose() {
    _maxWait?.cancel();
    _endPoll?.cancel();
    _controller?.dispose();
    if (!_navigated) {
      _restoreSystemUi();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready =
        controller != null && controller.value.isInitialized;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          removeBottom: true,
          removeLeft: true,
          removeRight: true,
          child: ready
              ? ColoredBox(
                  color: Colors.black,
                  child: SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      clipBehavior: Clip.hardEdge,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: math.max(1, controller.value.size.width),
                        height: math.max(1, controller.value.size.height),
                        child: VideoPlayer(controller),
                      ),
                    ),
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(color: Colors.white54),
                ),
        ),
      ),
    );
  }
}
