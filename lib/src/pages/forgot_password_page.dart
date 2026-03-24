import 'package:app_fluxolivre/src/pages/reset_password_page.dart';
import 'package:flutter/material.dart';

/// Respostas de segurança de demonstração (em produção viriam do backend).
const String kRespostaOndeNasceu = 'São Paulo';
const String kRespostaEscola = 'Escola Municipal Centro';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _resposta1Controller = TextEditingController();
  final _resposta2Controller = TextEditingController();

  bool _carregando = false;
  bool _etapaEmail = true;
  String? _erro;

  @override
  void dispose() {
    _emailController.dispose();
    _resposta1Controller.dispose();
    _resposta2Controller.dispose();
    super.dispose();
  }

  String? _validarEmail(String? v) {
    if (v == null || v.isEmpty) return 'Informe o e-mail';
    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(v)) return 'E-mail inválido';
    return null;
  }

  String? _validarObrigatorio(String? v, String campo) {
    if (v == null || v.trim().isEmpty) return 'Informe $campo';
    return null;
  }

  Future<void> _enviarEmail() async {
    _erro = null;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _carregando = false;
      _etapaEmail = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verifique seu e-mail para o link de recuperação. Em produção, um link seria enviado.')),
    );
  }

  void _irParaQuestoes() {
    _erro = null;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _etapaEmail = false);
  }

  Future<void> _validarQuestoes() async {
    _erro = null;
    if (!_formKey.currentState!.validate()) return;

    final r1 = _resposta1Controller.text.trim();
    final r2 = _resposta2Controller.text.trim();

    if (r1.toLowerCase() != kRespostaOndeNasceu.toLowerCase() ||
        r2.toLowerCase() != kRespostaEscola.toLowerCase()) {
      setState(() => _erro = 'Respostas de segurança incorretas.');
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResetPasswordPage(email: _emailController.text.isEmpty ? null : _emailController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar senha'),
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
                  Icon(Icons.lock_reset, size: 56, color: Colors.amber.shade200),
                  const SizedBox(height: 16),
                  Text(
                    _etapaEmail ? 'Esqueceu a senha?' : 'Questões de segurança',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _etapaEmail
                        ? 'Informe seu e-mail para receber o link de recuperação ou responda às questões de segurança.'
                        : 'Responda às perguntas para verificar sua identidade.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (_etapaEmail) ...[
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'E-mail',
                        hintText: 'seu@email.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                      ),
                      validator: _validarEmail,
                    ),
                    const SizedBox(height: 24),
                    if (_erro != null) ...[
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
                      const SizedBox(height: 16),
                    ],
                    ElevatedButton(
                      onPressed: _carregando ? null : _enviarEmail,
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
                          : const Text('Enviar link de recuperação'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _irParaQuestoes,
                      child: const Text('Prefiro responder às questões de segurança', style: TextStyle(color: Colors.amber)),
                    ),
                  ] else ...[
                    TextFormField(
                      controller: _resposta1Controller,
                      decoration: InputDecoration(
                        labelText: 'Onde você nasceu?',
                        hintText: 'Cidade de nascimento',
                        prefixIcon: const Icon(Icons.place_outlined),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                      ),
                      validator: (v) => _validarObrigatorio(v, 'onde nasceu'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _resposta2Controller,
                      decoration: InputDecoration(
                        labelText: 'Em que escola estudou?',
                        hintText: 'Nome da escola',
                        prefixIcon: const Icon(Icons.school_outlined),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                      ),
                      validator: (v) => _validarObrigatorio(v, 'a escola'),
                    ),
                    const SizedBox(height: 16),
                    if (_erro != null) ...[
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
                      const SizedBox(height: 16),
                    ],
                    ElevatedButton(
                      onPressed: _validarQuestoes,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: const Color(0xFF003366),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Verificar e redefinir senha'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() => _etapaEmail = true),
                      child: const Text('Voltar', style: TextStyle(color: Colors.amber)),
                    ),
                  ],
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
