import 'package:app_fluxolivre/src/models/user.dart';

enum AuditActionType { adicao, alteracao, remocao }

AuditActionType _parseStoredAuditTipo(String name) {
  for (final t in AuditActionType.values) {
    if (t.name == name) return t;
  }
  return AuditActionType.alteracao;
}

class AuditRecord {
  final AuditActionType tipo;
  final String descricao;
  final DateTime horario;
  final UserProfile usuario;

  AuditRecord({
    required this.tipo,
    required this.descricao,
    required this.horario,
    required this.usuario,
  });
}

class AuditLog {
  AuditLog({this.onChanged});

  final void Function()? onChanged;
  final List<AuditRecord> registros = [];
  static const Duration _janela24h = Duration(hours: 24);

  void pruneOlderThan24h() {
    final corte = DateTime.now().subtract(_janela24h);
    registros.removeWhere((r) => r.horario.isBefore(corte));
  }

  void registrar({
    required UserProfile usuario,
    required AuditActionType tipo,
    required String descricao,
  }) {
    registros.insert(
      0,
      AuditRecord(
        tipo: tipo,
        descricao: descricao,
        horario: DateTime.now(),
        usuario: usuario,
      ),
    );
    pruneOlderThan24h();
    onChanged?.call();
  }

  List<Map<String, dynamic>> toSessionJsonList() {
    pruneOlderThan24h();
    return registros
        .map(
          (r) => {
            'tipo': r.tipo.name,
            'desc': r.descricao,
            'ms': r.horario.millisecondsSinceEpoch,
            'uCpf': r.usuario.cpf,
            'uNome': r.usuario.nome,
            'uRole': r.usuario.role.name,
          },
        )
        .toList();
  }

  void hydrateFromJson(List<dynamic> list, UserProfile fallbackPerfil) {
    registros.clear();
    for (final raw in list) {
      final m = raw as Map<String, dynamic>;
      registros.add(
        AuditRecord(
          tipo: _parseStoredAuditTipo(m['tipo'] as String? ?? 'alteracao'),
          descricao: m['desc'] as String? ?? '',
          horario: DateTime.fromMillisecondsSinceEpoch(
            (m['ms'] as num).toInt(),
            isUtc: false,
          ),
          usuario: UserProfile(
            cpf: m['uCpf'] as String? ?? fallbackPerfil.cpf,
            nome: m['uNome'] as String? ?? fallbackPerfil.nome,
            role: UserRole.values.firstWhere(
              (r) =>
                  r.name == (m['uRole'] as String? ?? fallbackPerfil.role.name),
              orElse: () => fallbackPerfil.role,
            ),
          ),
        ),
      );
    }
    registros.sort((a, b) => b.horario.compareTo(a.horario));
    pruneOlderThan24h();
  }
}
