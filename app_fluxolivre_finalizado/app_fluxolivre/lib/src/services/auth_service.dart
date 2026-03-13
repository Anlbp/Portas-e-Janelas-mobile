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

/// Chaves para SharedPreferences.
const String _keyLembrarMe = 'auth_lembrar_me';
const String _keyCpfSalvo = 'auth_cpf_salvo';
const String _keyFalhasConsecutivas = 'auth_falhas_consecutivas';
const String _keyBloqueioAte = 'auth_bloqueio_ate';
const int kMaxFalhas = 10;
const Duration kDuracaoBloqueio = Duration(hours: 1);

class AuthService {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

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
      return const AuthResult.sucesso();
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
}

enum AuthStatus { sucesso, falha, bloqueado }

class AuthResult {
  final AuthStatus status;
  final String? mensagem;
  final int segundosBloqueio;

  const AuthResult.sucesso()
      : status = AuthStatus.sucesso,
        mensagem = null,
        segundosBloqueio = 0;

  AuthResult.falha(this.mensagem)
      : status = AuthStatus.falha,
        segundosBloqueio = 0;

  AuthResult.bloqueado(this.segundosBloqueio)
      : status = AuthStatus.bloqueado,
        mensagem =
            'Acesso bloqueado por $kMaxFalhas tentativas. Tente novamente em 1 hora.';
}
