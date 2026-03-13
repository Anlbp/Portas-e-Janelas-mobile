import 'dart:async';
import 'package:app_fluxolivre/src/pages/forgot_password_page.dart';
import 'package:app_fluxolivre/src/pages/home_page.dart';
import 'package:app_fluxolivre/src/services/auth_service.dart';
import 'package:app_fluxolivre/src/widgets/password_strength_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _cpfController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _obscureSenha = true;
  bool _lembrarMe = false;
  bool _carregando = false;
  String? _erro;
  bool _biometriaDisponivel = false;
  Timer? _bloqueioTimer;
  int _segundosBloqueio = 0;

  final _authService = AuthService();
  final _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _carregarEstadoSalvo();
    _verificarBiometria();
    _verificarBloqueio();
  }

  Future<void> _carregarEstadoSalvo() async {
    final lembrar = await _authService.lembrarMeAtivo;
    final cpf = await _authService.cpfSalvo;
    if (mounted) {
      setState(() {
        _lembrarMe = lembrar;
        if (cpf != null && cpf.length == 11) {
          _cpfController.text = _formatarCpf(cpf);
        }
      });
    }
  }

  Future<void> _verificarBiometria() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (mounted) {
        setState(() => _biometriaDisponivel = canCheck && isSupported);
      }
    } catch (_) {
      if (mounted) setState(() => _biometriaDisponivel = false);
    }
  }

  Future<void> _verificarBloqueio() async {
    if (!await _authService.estaBloqueado()) return;
    await _atualizarTimerBloqueio();
  }

  Future<void> _atualizarTimerBloqueio() async {
    final segundos = await _authService.segundosRestantesBloqueio();
    if (!mounted) return;
    setState(() => _segundosBloqueio = segundos);
    if (segundos > 0) {
      _bloqueioTimer?.cancel();
      _bloqueioTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
        final s = await _authService.segundosRestantesBloqueio();
        if (!mounted) return;
        setState(() => _segundosBloqueio = s);
        if (s <= 0) _bloqueioTimer?.cancel();
      });
    }
  }

  String _formatarCpf(String cpf) {
    final n = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (n.length <= 3) return n;
    if (n.length <= 6) return '${n.substring(0, 3)}.${n.substring(3)}';
    if (n.length <= 9) return '${n.substring(0, 3)}.${n.substring(3, 6)}.${n.substring(6)}';
    return '${n.substring(0, 3)}.${n.substring(3, 6)}.${n.substring(6, 9)}-${n.substring(9)}';
  }

  String? _validarCpf(String? v) {
    if (v == null || v.isEmpty) return 'Informe o CPF';
    final n = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (n.length != 11) return 'CPF deve ter 11 dígitos';
    return null;
  }

  String? _validarSenha(String? v) {
    if (v == null || v.isEmpty) return 'Informe a senha';
    if (v.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  Future<void> _entrar() async {
    _erro = null;
    if (!_formKey.currentState!.validate()) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _carregando = true);
    await _authService.salvarLembrarMe(
      ativo: _lembrarMe,
      cpf: _lembrarMe ? _cpfController.text : null,
    );

    final result = await _authService.login(
      cpf: _cpfController.text,
      senha: _senhaController.text,
    );

    if (!mounted) return;
    setState(() => _carregando = false);

    switch (result.status) {
      case AuthStatus.sucesso:
        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
        break;
      case AuthStatus.falha:
        setState(() => _erro = result.mensagem);
        messenger.showSnackBar(
          SnackBar(content: Text(result.mensagem ?? 'Erro ao entrar')),
        );
        break;
      case AuthStatus.bloqueado:
        await _atualizarTimerBloqueio();
        if (!mounted) return;
        setState(() => _erro = result.mensagem);
        messenger.showSnackBar(
          SnackBar(
            content: Text(result.mensagem ?? 'Bloqueado'),
            backgroundColor: Colors.red,
          ),
        );
        break;
    }
  }

  Future<void> _loginBiometria() async {
    if (!_biometriaDisponivel) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometria não disponível neste dispositivo')),
      );
      return;
    }
    try {
      final autenticado = await _localAuth.authenticate(
        localizedReason: 'Use a biometria para entrar no FluxoLivre',
      );
      if (!autenticado || !mounted) return;
      setState(() => _carregando = true);
      final result = await _authService.loginComBiometria();
      if (!mounted) return;
      setState(() => _carregando = false);
      if (result.status == AuthStatus.sucesso) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.mensagem ?? 'Falha na biometria')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  void _abrirEsqueciSenha() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
    );
  }

  @override
  void dispose() {
    _bloqueioTimer?.cancel();
    _cpfController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloqueado = _segundosBloqueio > 0;

    return Scaffold(
      backgroundColor: const Color(0xFF241E20),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF241E20),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 32),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/casaportas.jpg',
                            width: 100,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(Icons.lock_outline, size: 64, color: Colors.amber.shade200),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Bem-vindo de volta',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Entre com seu CPF e senha para acessar o FluxoLivre',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _cpfController,
                          keyboardType: TextInputType.number,
                          readOnly: bloqueado,
                          decoration: InputDecoration(
                            labelText: 'CPF',
                            hintText: '000.000.000-00',
                            prefixIcon: const Icon(Icons.badge_outlined),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                          ),
                          inputFormatters: [
                            _CpfInputFormatter(),
                          ],
                          validator: _validarCpf,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _senhaController,
                          obscureText: _obscureSenha,
                          readOnly: bloqueado,
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            hintText: 'Sua senha',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureSenha ? Icons.visibility_off : Icons.visibility,
                              ),
                              onPressed: () => setState(() => _obscureSenha = !_obscureSenha),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                          ),
                          validator: _validarSenha,
                          onChanged: (_) => setState(() {}),
                        ),
                        PasswordStrengthIndicator(senha: _senhaController.text),
                        if (_erro != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_erro!, style: const TextStyle(color: Colors.red))),
                              ],
                            ),
                          ),
                        ],
                        if (bloqueado) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Bloqueado. Tente novamente em ${_formatarTempo(_segundosBloqueio)}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFFFFC107), fontWeight: FontWeight.w500),
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: bloqueado ? null : _abrirEsqueciSenha,
                          child: const Text('Esqueci minha senha', style: TextStyle(color: Color(0xFFFFC107))),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Checkbox(
                              value: _lembrarMe,
                              onChanged: bloqueado ? null : (v) => setState(() => _lembrarMe = v ?? false),
                              activeColor: const Color(0xFFFFC107),
                              checkColor: const Color(0xFF241E20),
                            ),
                            const Text('Lembrar-me', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: bloqueado || _carregando ? null : _entrar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC107),
                            foregroundColor: const Color(0xFF241E20),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          child: _carregando
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Entrar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        if (_biometriaDisponivel) ...[
                          const SizedBox(height: 20),
                          OutlinedButton.icon(
                            onPressed: bloqueado || _carregando ? null : _loginBiometria,
                            icon: const Icon(Icons.fingerprint, color: Color(0xFFFFC107)),
                            label: const Text('Entrar com biometria', style: TextStyle(color: Color(0xFFFFC107))),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFFFC107)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        TextButton(
                          onPressed: () => _toast('Suporte: suporte@fluxolivre.com'),
                          child: Text('Suporte', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () => _toast('Termos de uso'),
                              child: Text('Termos', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                            ),
                            Text(' | ', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
                            TextButton(
                              onPressed: () => _toast('Política de privacidade'),
                              child: Text('Privacidade', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                            ),
                          ],
                        ),
                      ],
                    ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatarTempo(int segundos) {
    final m = segundos ~/ 60;
    final s = segundos % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 11) {
      return oldValue;
    }
    String formatted = text;
    if (text.length > 9) {
      formatted = '${text.substring(0, 3)}.${text.substring(3, 6)}.${text.substring(6, 9)}-${text.substring(9)}';
    } else if (text.length > 6) {
      formatted = '${text.substring(0, 3)}.${text.substring(3, 6)}.${text.substring(6)}';
    } else if (text.length > 3) {
      formatted = '${text.substring(0, 3)}.${text.substring(3)}';
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
