import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// "DB" de usuários: CPF (apenas números) -> senha.
/// Administrador: 11144477735 / Admin!2025
/// Gerente: 22255588846 / Gerente@2025
/// Vendedor: 33366699957 / Vendedor#2025
final Map<String, String> _dbUsuarios = {
  '11144477735': 'Admin!2025',
  '22255588846': 'Gerente@2025',
  '33366699957': 'Vendedor#2025',
};

enum UserRole {
  administrador,
  gerente,
  operario,
}

class UserProfile {
  final String cpf;
  final String nome;
  final UserRole role;

  const UserProfile({
    required this.cpf,
    required this.nome,
    required this.role,
  });
}

final Map<String, UserProfile> _dbPerfis = {
  '11144477735': const UserProfile(
    cpf: '11144477735',
    nome: 'Administrador',
    role: UserRole.administrador,
  ),
  '22255588846': const UserProfile(
    cpf: '22255588846',
    nome: 'Gerente',
    role: UserRole.gerente,
  ),
  '33366699957': const UserProfile(
    cpf: '33366699957',
    nome: 'Operário',
    role: UserRole.operario,
  ),
};

/// Chaves para SharedPreferences.
const String _keyLembrarMe = 'auth_lembrar_me';
const String _keyCpfSalvo = 'auth_cpf_salvo';
const String _keyFalhasConsecutivas = 'auth_falhas_consecutivas';
const String _keyBloqueioAte = 'auth_bloqueio_ate';
const String _keyUsuariosSalvos = 'auth_usuarios_cadastrados';
const int kMaxFalhas = 10;
const Duration kDuracaoBloqueio = Duration(hours: 1);

class AuthService {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._() {
    // Carrega usuários salvos ao iniciar
    _carregarUsuariosSalvos();
  }

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _storage async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Remove caracteres não numéricos do CPF.
  String normalizarCpf(String cpf) =>
      cpf.replaceAll(RegExp(r'[^0-9]'), '');

  bool validarCpf(String cpf) {
    final n = normalizarCpf(cpf);
    return n.length == 11;
  }

  /// Verifica se está no período de bloqueio.
  Future<bool> estaBloqueado() async {
    final prefs = await _storage;
    final ate = prefs.getInt(_keyBloqueioAte);
    if (ate == null) return false;
    if (DateTime.now().millisecondsSinceEpoch >= ate) {
      await prefs.remove(_keyBloqueioAte);
      await prefs.setInt(_keyFalhasConsecutivas, 0);
      return false;
    }
    return true;
  }

  /// Retorna segundos restantes de bloqueio (0 se não bloqueado).
  Future<int> segundosRestantesBloqueio() async {
    final prefs = await _storage;
    final ate = prefs.getInt(_keyBloqueioAte);
    if (ate == null) return 0;
    final restante = ate - DateTime.now().millisecondsSinceEpoch;
    return restante > 0 ? (restante / 1000).ceil() : 0;
  }

  Future<AuthResult> login({required String cpf, required String senha}) async {
    if (await estaBloqueado()) {
      final segundos = await segundosRestantesBloqueio();
      return AuthResult.bloqueado(segundos);
    }

    final cpfNorm = normalizarCpf(cpf);
    final senhaLimpa = senha.trim();
    final senhaEsperada = _dbUsuarios[cpfNorm];
    final ok = senhaEsperada != null && senhaLimpa == senhaEsperada;

    final prefs = await _storage;
    if (ok) {
      await prefs.setInt(_keyFalhasConsecutivas, 0);
      await prefs.remove(_keyBloqueioAte);
      final perfil = _dbPerfis[cpfNorm];
      return AuthResult.sucesso(perfil);
    }

    int falhas = (prefs.getInt(_keyFalhasConsecutivas) ?? 0) + 1;
    await prefs.setInt(_keyFalhasConsecutivas, falhas);

    if (falhas >= kMaxFalhas) {
      final bloqueioAte =
          DateTime.now().add(kDuracaoBloqueio).millisecondsSinceEpoch;
      await prefs.setInt(_keyBloqueioAte, bloqueioAte);
      return AuthResult.bloqueado(kDuracaoBloqueio.inSeconds);
    }
    return AuthResult.falha(
        'CPF ou senha incorretos. Tentativas restantes: ${kMaxFalhas - falhas}');
  }

  Future<void> salvarLembrarMe({required bool ativo, String? cpf}) async {
    final prefs = await _storage;
    await prefs.setBool(_keyLembrarMe, ativo);
    if (ativo && cpf != null && cpf.isNotEmpty) {
      await prefs.setString(_keyCpfSalvo, normalizarCpf(cpf));
    } else if (!ativo) {
      await prefs.remove(_keyCpfSalvo);
    }
  }

  Future<bool> get lembrarMeAtivo async {
    final prefs = await _storage;
    return prefs.getBool(_keyLembrarMe) ?? false;
  }

  Future<String?> get cpfSalvo async {
    final prefs = await _storage;
    return prefs.getString(_keyCpfSalvo);
  }

  /// Simula login por biometria: usa credenciais salvas (lembrar-me).
  Future<AuthResult> loginComBiometria() async {
    final cpf = await cpfSalvo;
    if (cpf == null || cpf.isEmpty) {
      return AuthResult.falha(
          'Use "Lembrar-me" e faça login uma vez para ativar a biometria.');
    }
    final senha = _dbUsuarios[cpf];
    if (senha == null) {
      return AuthResult.falha('Usuário não encontrado. Faça login com CPF e senha.');
    }
    return login(cpf: cpf, senha: senha);
  }

  Future<void> logout() async {
    // Limpa apenas sessão; opcionalmente manter "lembrar-me".
    // Se quiser limpar tudo: (await _storage).clear();
  }

  /// Carrega usuários salvos do SharedPreferences.
  Future<void> _carregarUsuariosSalvos() async {
    final prefs = await _storage;
    final usuariosJson = prefs.getString(_keyUsuariosSalvos);
    if (usuariosJson != null && usuariosJson.isNotEmpty) {
      try {
        final lista = jsonDecode(usuariosJson) as List<dynamic>;
        for (final item in lista) {
          final m = item as Map<String, dynamic>;
          final cpf = m['cpf'] as String;
          final senha = m['senha'] as String;
          final nome = m['nome'] as String;
          final roleStr = m['role'] as String;
          UserRole? role;
          for (final r in UserRole.values) {
            if (r.name == roleStr) {
              role = r;
              break;
            }
          }
          if (role != null) {
            _dbUsuarios[cpf] = senha;
            _dbPerfis[cpf] = UserProfile(
              cpf: cpf,
              nome: nome,
              role: role,
            );
          }
        }
      } catch (_) {
        // Ignora erro ao carregar
      }
    }
  }

  /// Salva usuários no SharedPreferences.
  Future<void> _salvarUsuariosNoStorage() async {
    final prefs = await _storage;
    final lista = <Map<String, dynamic>>[];
    for (final entry in _dbPerfis.entries) {
      // Não salva usuários padrão (iniciais)
      if (entry.value.role == UserRole.administrador && entry.value.nome == 'Administrador') continue;
      if (entry.value.role == UserRole.gerente && entry.value.nome == 'Gerente') continue;
      if (entry.value.role == UserRole.operario && entry.value.nome == 'Operário') continue;
      
      final senha = _dbUsuarios[entry.key] ?? '';
      lista.add({
        'cpf': entry.key,
        'senha': senha,
        'nome': entry.value.nome,
        'role': entry.value.role.name,
      });
    }
    await prefs.setString(_keyUsuariosSalvos, jsonEncode(lista));
  }

  /// Verifica se o CPF já está cadastrado.
  bool cpfJaCadastrado(String cpf) {
    final cpfNorm = normalizarCpf(cpf);
    return _dbUsuarios.containsKey(cpfNorm);
  }

  /// Cria um novo usuário (apenas para administrador).
  Future<AuthResult> criarUsuario({
    required String cpf,
    required String senha,
    required String nome,
    required UserRole role,
  }) async {
    final cpfNorm = normalizarCpf(cpf);
    
    if (!validarCpf(cpf)) {
      return AuthResult.falha('CPF inválido. Deve ter 11 dígitos.');
    }
    
    if (cpfJaCadastrado(cpf)) {
      return AuthResult.falha('CPF já cadastrado.');
    }
    
    if (senha.length < 6) {
      return AuthResult.falha('Senha deve ter no mínimo 6 caracteres.');
    }
    
    if (nome.trim().isEmpty) {
      return AuthResult.falha('Nome não pode ser vazio.');
    }
    
    _dbUsuarios[cpfNorm] = senha;
    _dbPerfis[cpfNorm] = UserProfile(
      cpf: cpfNorm,
      nome: nome.trim(),
      role: role,
    );
    
    // Persiste no storage
    await _salvarUsuariosNoStorage();
    
    return AuthResult.sucesso(_dbPerfis[cpfNorm]);
  }

  /// Lista todos os usuários cadastrados (apenas para administrador).
  List<UserProfile> listarUsuarios() {
    return _dbPerfis.values.toList();
  }
}

enum AuthStatus { sucesso, falha, bloqueado }

class AuthResult {
  final AuthStatus status;
  final String? mensagem;
  final int segundosBloqueio;
  final UserProfile? perfil;

  const AuthResult.sucesso(this.perfil)
      : status = AuthStatus.sucesso,
        mensagem = null,
        segundosBloqueio = 0;

  AuthResult.falha(this.mensagem)
      : status = AuthStatus.falha,
        segundosBloqueio = 0,
        perfil = null;

  AuthResult.bloqueado(this.segundosBloqueio)
      : status = AuthStatus.bloqueado,
        mensagem =
            'Acesso bloqueado por $kMaxFalhas tentativas. Tente novamente em 1 hora.',
        perfil = null;
}
