import 'package:shared_preferences/shared_preferences.dart';

/// Sessão de trabalho (até logout), inventário completo e auditoria.
/// Catálogo de clientes/produtos por CPF sobrevive ao logout.
class SessionStore {
  SessionStore._();

  static String _sessaoKey(String cpf) => 'fluxo_sessao_ativa_$cpf';
  static String _invKey(String sessionId) => 'fluxo_inv_$sessionId';
  static String _auditKey(String sessionId) => 'fluxo_audit_$sessionId';
  static String _catalogKey(String cpf) => 'fluxo_catalog_$cpf';

  /// Reutiliza a sessão aberta para o CPF ou cria uma nova (primeiro login / após logout).
  static Future<String> getOrCreateSessionId(String cpf) async {
    final prefs = await SharedPreferences.getInstance();
    final existente = prefs.getString(_sessaoKey(cpf));
    if (existente != null && existente.isNotEmpty) return existente;
    final id = '${cpf}_${DateTime.now().millisecondsSinceEpoch}';
    await prefs.setString(_sessaoKey(cpf), id);
    return id;
  }

  static Future<({String? inv, String? audit})> loadPayload(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    return (
      inv: prefs.getString(_invKey(sessionId)),
      audit: prefs.getString(_auditKey(sessionId)),
    );
  }

  static Future<void> savePayload({
    required String sessionId,
    required String inventoryJson,
    required String auditJson,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_invKey(sessionId), inventoryJson);
    await prefs.setString(_auditKey(sessionId), auditJson);
  }

  /// Lista de clientes e produtos (mesmo formato `v:1` parcial do inventário).
  static Future<void> saveCatalog(String cpf, String catalogJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_catalogKey(cpf), catalogJson);
  }

  static Future<String?> loadCatalog(String cpf) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_catalogKey(cpf));
  }

  /// Logout: encerra a sessão e remove dados persistidos desta sessão.
  static Future<void> clearSessionForUser({
    required String cpf,
    required String sessionId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessaoKey(cpf));
    await prefs.remove(_invKey(sessionId));
    await prefs.remove(_auditKey(sessionId));
  }
}
