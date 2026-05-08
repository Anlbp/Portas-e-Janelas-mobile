import 'package:app_fluxolivre/src/services/auth_service.dart';
import 'package:flutter/material.dart';

class UserManagementPage extends StatefulWidget {
  final UserProfile administradorLogado;

  const UserManagementPage({
    super.key,
    required this.administradorLogado,
  });

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _senhaController = TextEditingController();
  
  bool _obscureSenha = true;
  UserRole _selectedRole = UserRole.operario;
  bool _carregando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  String? _validarNome(String? v) {
    if (v == null || v.trim().isEmpty) return 'Informe o nome';
    return null;
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

  Future<void> _criarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);

    final result = await _authService.criarUsuario(
      cpf: _cpfController.text,
      senha: _senhaController.text,
      nome: _nomeController.text.trim(),
      role: _selectedRole,
    );

    if (!mounted) return;
    setState(() => _carregando = false);

    if (result.status == AuthStatus.sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuário criado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      _formKey.currentState!.reset();
      _nomeController.clear();
      _cpfController.clear();
      _senhaController.clear();
      setState(() => _selectedRole = UserRole.operario);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.mensagem ?? 'Erro ao criar usuário'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.administrador:
        return 'Admin';
      case UserRole.gerente:
        return 'Gerente';
      case UserRole.operario:
        return 'Operário';
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.administrador:
        return Colors.red.shade700;
      case UserRole.gerente:
        return Colors.blue.shade700;
      case UserRole.operario:
        return Colors.green.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuarios = _authService.listarUsuarios();
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 500;
        final titleStyle = isCompact
            ? Theme.of(context).textTheme.titleMedium
            : Theme.of(context).textTheme.titleLarge;

        return Padding(
          padding: EdgeInsets.all(isCompact ? 8.0 : 16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Seção de cadastro
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person_add, size: isCompact ? 20 : 24, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Cadastrar Novo Usuário',
                                  style: titleStyle?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _nomeController,
                            decoration: InputDecoration(
                              labelText: 'Nome completo',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isCompact ? 8 : 12,
                                vertical: isCompact ? 8 : 12,
                              ),
                            ),
                            validator: _validarNome,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _cpfController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'CPF',
                              hintText: '000.000.000-00',
                              prefixIcon: const Icon(Icons.badge_outlined),
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isCompact ? 8 : 12,
                                vertical: isCompact ? 8 : 12,
                              ),
                            ),
                            validator: _validarCpf,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _senhaController,
                            obscureText: _obscureSenha,
                            decoration: InputDecoration(
                              labelText: 'Senha',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureSenha ? Icons.visibility_off : Icons.visibility,
                                ),
                                onPressed: () => setState(() => _obscureSenha = !_obscureSenha),
                              ),
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isCompact ? 8 : 12,
                                vertical: isCompact ? 8 : 12,
                              ),
                            ),
                            validator: _validarSenha,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<UserRole>(
                            initialValue: _selectedRole,
                            decoration: InputDecoration(
                              labelText: 'Cargo',
                              prefixIcon: const Icon(Icons.work_outline),
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isCompact ? 8 : 12,
                                vertical: isCompact ? 8 : 12,
                              ),
                            ),
                            items: UserRole.values.map((role) {
                              return DropdownMenuItem(
                                value: role,
                                child: Text(_getRoleLabel(role)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedRole = value);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _carregando ? null : _criarUsuario,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFC107),
                                foregroundColor: const Color(0xFF241E20),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isCompact ? 8 : 16,
                                  vertical: isCompact ? 12 : 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _carregando
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text(
                                      'Cadastrar Usuário',
                                      style: TextStyle(
                                        fontSize: isCompact ? 14 : 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Lista de usuários
                Text(
                  'Usuários Cadastrados',
                  style: titleStyle?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...usuarios.map((usuario) => Card(
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 8 : 16,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      radius: isCompact ? 16 : 20,
                      backgroundColor: _getRoleColor(usuario.role),
                      child: Text(
                        usuario.nome.characters.first,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isCompact ? 12 : 14,
                        ),
                      ),
                    ),
                    title: Text(
                      usuario.nome,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'CPF: ${usuario.cpf}',
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Chip(
                      label: Text(
                        _getRoleLabel(usuario.role),
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                      backgroundColor: _getRoleColor(usuario.role),
                      padding: EdgeInsets.zero,
                      visualDensity: isCompact ? VisualDensity.compact : VisualDensity.standard,
                    ),
                  ),
                )),
              ],
            ),
          ),
        );
      },
    );
  }
}