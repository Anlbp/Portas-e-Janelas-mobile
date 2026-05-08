import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app_fluxolivre/src/services/auth_service.dart';

/// Resultado do assistente: texto ao usuário e possível instrução sobre estoque.
class IaAssistenteOutcome {
  final String texto;
  final IaEstoqueAcao? acao;

  const IaAssistenteOutcome({required this.texto, this.acao});
}

/// Instrução interpretada a partir da linha `@@@ACTION` da IA (executada no app).
class IaEstoqueAcao {
  final IaEstoqueOp op;
  final String? id;
  final String? nome;
  final String? material;
  final double? preco;
  final int? quantidade;

  const IaEstoqueAcao({
    required this.op,
    this.id,
    this.nome,
    this.material,
    this.preco,
    this.quantidade,
  });
}

enum IaEstoqueOp { add, update }

/// Fluxo Livre — assistente Groq com contexto de estoque e alterações condicionais ao perfil.
class RecommendationEngine {
  /// Substitua por uma chave em https://console.groq.com/keys
  static const String _apiKeyGroq = '';

  static const String _groqEndpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  static const String _model = 'llama-3.3-70b-versatile';

  static const String _marcadorAcao = '@@@ACTION';

  static bool _podeAlterarEstoqueViaIa(UserRole role) =>
      role == UserRole.administrador || role == UserRole.gerente;

  /// Monta o bloco de estoque enviado ao modelo (IDs e valores reais do app).
  static String montarLinhasEstoque(List<Map<String, Object?>> produtos) {
    if (produtos.isEmpty) {
      return '(nenhum produto cadastrado no momento)';
    }
    final buf = StringBuffer();
    for (final p in produtos) {
      final id = p['id']?.toString() ?? '?';
      final nome = p['nome']?.toString() ?? '';
      final mat = p['material']?.toString() ?? '';
      final preco = p['preco'];
      final qtd = p['quantidade'];
      buf.writeln(
        '- id=$id | $nome | material: $mat | preço R\$ $preco | qtd em estoque: $qtd',
      );
    }
    return buf.toString().trim();
  }

  String _systemPromptComEstoque({
    required UserProfile perfil,
    required String linhasEstoque,
    required bool podeAlterar,
  }) =>
      '''
${_systemPromptBase()}

**UTILIZADOR LOGADO:** ${perfil.nome} (${perfil.role.name}).
**ALTERAR CADASTRO DE PRODUTOS VIA ASSISTENTE:** ${podeAlterar ? 'SIM — este utilizador pode pedir para registar ou atualizar produtos no sistema.' : 'NÃO — este utilizador NÃO pode alterar produtos pelo assistente. Se pedir adição ou edição, recusa educadamente e explica que só gerente ou administrador podem fazê-lo.'}

**ESTOQUE ATUAL NO APP (única fonte de verdade para preços, nomes e quantidades):**
$linhasEstoque

Regras:
- Para perguntas sobre preços, tipos ou disponibilidade, usa **apenas** os dados acima.
- Se não houver produto adequado no estoque, diz claramente e sugere encomenda ou orçamento.
- Para recomendações técnicas gerais (ex.: PVC vs alumínio), podes usar conhecimento de domínio.

**FORMATO DE ALTERAÇÃO (só se podeAlterar for verdade e o utilizador pedir explicitamente para registar/alterar produto):**
Coloca no **final** da resposta, sozinha numa linha, um JSON assim (sem texto extra nessa linha):
$_marcadorAcao{"op":"add_product","nome":"...","material":"...","preco":0.0,"quantidade":0}
ou
$_marcadorAcao{"op":"update_product","id":"ID_EXISTENTE","nome":"...","material":"...","preco":0.0,"quantidade":0}
Em update_product, inclui só os campos que devem mudar; mantém os outros como estão no sistema.
Se faltar informação essencial (ex.: nome ou preço num novo produto), pergunta ao utilizador e **não** incluas $_marcadorAcao até teres dados suficientes.
Se podeAlterar for falso, **nunca** incluas $_marcadorAcao.
''';

  String _systemPromptBase() => '''
Você é o assistente IA da Fluxo Livre — especialistas em portas e janelas.

**PRODUTOS (geral):**
- Portas: aço galvanizado, alumínio, madeira/MDF, vidro temperado
- Janelas: PVC, alumínio (correr, basculante, maxim-ar), vidro duplo/temperado

**SERVIÇOS:** Fabricação sob medida, instalação, garantia.

**ESTILO:** Português BR, cordial e técnico de forma acessível.
''';

  /// Resposta à mensagem do utilizador com inventário e permissões do perfil.
  Future<IaAssistenteOutcome> responderComEstoque({
    required String mensagemUsuario,
    required UserProfile perfil,
    required String linhasEstoque,
  }) async {
    final textoFallbackConfig = _mensagemSemChave();
    if (textoFallbackConfig != null) {
      return IaAssistenteOutcome(texto: textoFallbackConfig);
    }

    final podeAlterar = _podeAlterarEstoqueViaIa(perfil.role);
    final system = _systemPromptComEstoque(
      perfil: perfil,
      linhasEstoque: linhasEstoque,
      podeAlterar: podeAlterar,
    );

    try {
      final response = await http
          .post(
            Uri.parse(_groqEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKeyGroq',
            },
            body: jsonEncode({
              'model': _model,
              'messages': [
                {'role': 'system', 'content': system},
                {'role': 'user', 'content': mensagemUsuario},
              ],
              'temperature': 0.45,
              'max_tokens': 1200,
              'top_p': 0.9,
            }),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List?;
        final raw = _groqAssistantText(choices);
        if (raw.isEmpty) {
          return IaAssistenteOutcome(
            texto: _erroGroq('resposta vazia', response.body),
          );
        }
        return _extrairOutcome(raw, podeAlterar: podeAlterar);
      }

      final code = response.statusCode;
      if (code == 401) {
        return IaAssistenteOutcome(
          texto: '❌ API Key inválida. Gere nova: console.groq.com/keys',
        );
      }
      if (code == 429) {
        return IaAssistenteOutcome(texto: '⏳ Rate limit. Aguarde 1min.');
      }
      if (code >= 500) {
        return IaAssistenteOutcome(texto: '🌐 Groq server error. Tente depois.');
      }

      return IaAssistenteOutcome(
        texto: _erroGroq('HTTP ${response.statusCode}', response.body),
      );
    } catch (e) {
      if (e.toString().contains('Timeout')) {
        return IaAssistenteOutcome(texto: '⏰ Timeout. Pergunta mais simples?');
      }
      if (e.toString().contains('Socket') || e.toString().contains('Network')) {
        return IaAssistenteOutcome(texto: '🌐 Sem internet.');
      }
      return IaAssistenteOutcome(texto: _erroGroq('exceção', e.toString()));
    }
  }

  IaAssistenteOutcome _extrairOutcome(String raw, {required bool podeAlterar}) {
    final lines = raw.split('\n');
    String? actionLine;
    final textLines = <String>[];
    for (final line in lines) {
      final t = line.trim();
      if (t.startsWith(_marcadorAcao)) {
        actionLine = t;
      } else {
        textLines.add(line);
      }
    }
    var texto = textLines.join('\n').trim();
    IaEstoqueAcao? acao;
    if (actionLine != null && podeAlterar) {
      acao = _parseAcao(actionLine);
    } else if (actionLine != null && !podeAlterar) {
      // Garante que operários não disparem alterações mesmo que o modelo envie linha.
      if (!texto.toLowerCase().contains('gerente') &&
          !texto.toLowerCase().contains('administrador')) {
        texto +=
            '\n\n(Só gerente ou administrador podem registar ou alterar produtos pelo assistente.)';
      }
    }

    if (texto.isEmpty && acao != null) {
      texto = 'Registo no estoque processado.';
    }

    return IaAssistenteOutcome(texto: texto.isEmpty ? raw : texto, acao: acao);
  }

  IaEstoqueAcao? _parseAcao(String line) {
    final idx = line.indexOf(_marcadorAcao);
    if (idx < 0) return null;
    var jsonStr = line.substring(idx + _marcadorAcao.length).trim();
    if (jsonStr.startsWith(':')) jsonStr = jsonStr.substring(1).trim();
    try {
      final m = jsonDecode(jsonStr) as Map<String, dynamic>;
      final opRaw = (m['op'] as String?)?.toLowerCase() ?? '';
      if (opRaw == 'add_product') {
        return IaEstoqueAcao(
          op: IaEstoqueOp.add,
          nome: m['nome'] as String?,
          material: m['material'] as String?,
          preco: (m['preco'] as num?)?.toDouble(),
          quantidade: (m['quantidade'] as num?)?.toInt(),
        );
      }
      if (opRaw == 'update_product') {
        return IaEstoqueAcao(
          op: IaEstoqueOp.update,
          id: m['id'] as String?,
          nome: m['nome'] as String?,
          material: m['material'] as String?,
          preco: (m['preco'] as num?)?.toDouble(),
          quantidade: (m['quantidade'] as num?)?.toInt(),
        );
      }
    } catch (_) {}
    return null;
  }

  String? _mensagemSemChave() {
    if (_apiKeyGroq == 'SUA_CHAVE_GROQ_AQUI' || _apiKeyGroq.isEmpty) {
      return '🔑 Configure API Key Groq em recommendation_engine.dart\n'
          'console.groq.com/keys';
    }
    return null;
  }

  /// Compatível com chamadas antigas — sem estoque.
  Future<String> respostaParaMensagem(String mensagem) async {
    final out = await responderComEstoque(
      mensagemUsuario: mensagem,
      perfil: const UserProfile(
        cpf: '0',
        nome: 'Visitante',
        role: UserRole.operario,
      ),
      linhasEstoque: '(sem dados de estoque)',
    );
    return out.texto;
  }

  static String _groqAssistantText(List? choices) {
    if (choices == null || choices.isEmpty) return '';
    final first = choices.first;
    if (first is! Map) return '';
    final message = first['message'];
    if (message is! Map) return '';
    final raw = message['content'];
    return raw?.toString().trim() ?? '';
  }

  String _erroGroq(String motivo, [String? detalhe]) {
    final raw = detalhe?.trim() ?? '';
    if (raw.isEmpty) return '[Groq] Falha: $motivo.';
    final short =
        raw.length > 400 ? '${raw.substring(0, 400)}…' : raw;
    return '[Groq] Falha: $motivo.\n$short';
  }

  void setInventorySystem(dynamic inventory) {}
}
