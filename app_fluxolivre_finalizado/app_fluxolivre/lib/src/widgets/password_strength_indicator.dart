import 'package:flutter/material.dart';

enum ForcaSenha { fraco, medio, forte }

ForcaSenha calcularForcaSenha(String senha) {
  if (senha.isEmpty) return ForcaSenha.fraco;
  int score = 0;
  if (senha.length >= 8) score++;
  if (senha.length >= 12) score++;
  if (RegExp(r'[A-Z]').hasMatch(senha)) score++;
  if (RegExp(r'[a-z]').hasMatch(senha)) score++;
  if (RegExp(r'[0-9]').hasMatch(senha)) score++;
  if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(senha)) score++;
  if (score <= 2) return ForcaSenha.fraco;
  if (score <= 4) return ForcaSenha.medio;
  return ForcaSenha.forte;
}

class PasswordStrengthIndicator extends StatelessWidget {
  final String senha;

  const PasswordStrengthIndicator({super.key, required this.senha});

  @override
  Widget build(BuildContext context) {
    final forca = calcularForcaSenha(senha);
    if (senha.isEmpty) return const SizedBox.shrink();
    final (label, color) = switch (forca) {
      ForcaSenha.fraco => ('Fraco', Colors.red),
      ForcaSenha.medio => ('Médio', Colors.orange),
      ForcaSenha.forte => ('Forte', Colors.green),
    };
    final value = switch (forca) {
      ForcaSenha.fraco => 0.33,
      ForcaSenha.medio => 0.66,
      ForcaSenha.forte => 1.0,
    };
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
