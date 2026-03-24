import 'package:app_fluxolivre/src/pages/login_page.dart';
import 'package:app_fluxolivre/src/widgets/password_strength_indicator.dart';
import 'package:flutter/material.dart';

class ResetPasswordPage extends StatefulWidget {
  final String? email;

  const ResetPasswordPage({super.key, this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _obscureNova = true;
  bool _obscureConfirmar = true;
  bool _carregando = false;
  bool _mostrar2FA = false;
  final _codigo2FAController = TextEditingController();

  @override
  void dispose() {
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    _codigo2FAController.dispose();
    super.dispose();
  }

  String? _validarSenha(String? v) {
    if (v == null || v.isEmpty) return 'Informe a nova senha';
    if (v.length < 8) return 'Mínimo 8 caracteres';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Use ao menos uma letra maiúscula';
    if (!RegExp(r'[a-z]').hasMatch(v)) return 'Use ao menos uma letra minúscula';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Use ao menos um número';
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(v)) return 'Use ao menos um caractere especial';
    return null;
  }

  String? _validarConfirmacao(String? v) {
    if (v == null || v.isEmpty) return 'Confirme a senha';
    if (v != _novaSenhaController.text) return 'As senhas não coincidem';
    return null;
  }

  Future<void> _redefinir() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _carregando = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Senha redefinida com sucesso! Em produção, a senha seria atualizada no servidor.')),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova senha'),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF003366),
              Colors.blue.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  Icon(Icons.vpn_key, size: 56, color: Colors.amber.shade200),
                  const SizedBox(height: 16),
                  const Text(
                    'Redefinir senha',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crie uma nova senha com no mínimo 8 caracteres, incluindo maiúsculas, minúsculas, números e símbolos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _novaSenhaController,
                    obscureText: _obscureNova,
                    decoration: InputDecoration(
                      labelText: 'Nova senha',
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNova ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureNova = !_obscureNova),
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
                  PasswordStrengthIndicator(senha: _novaSenhaController.text),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmarSenhaController,
                    obscureText: _obscureConfirmar,
                    decoration: InputDecoration(
                      labelText: 'Confirmar nova senha',
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmar ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureConfirmar = !_obscureConfirmar),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                    ),
                    validator: _validarConfirmacao,
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    value: _mostrar2FA,
                    onChanged: (v) => setState(() => _mostrar2FA = v ?? false),
                    title: const Text(
                      'Autenticação em dois fatores (2FA)',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    activeColor: Colors.amber,
                    checkColor: const Color(0xFF003366),
                  ),
                  if (_mostrar2FA) ...[
                    TextFormField(
                      controller: _codigo2FAController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Código do autenticador ou e-mail',
                        hintText: '000000',
                        prefixIcon: const Icon(Icons.smartphone),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _carregando ? null : _redefinir,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: const Color(0xFF003366),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _carregando
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Redefinir senha'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
