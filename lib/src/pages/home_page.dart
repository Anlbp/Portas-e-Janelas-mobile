import 'dart:async';
import 'dart:convert';

import 'package:app_fluxolivre/src/pages/login_page.dart';

import 'package:app_fluxolivre/src/pages/user_management_page.dart';
import 'package:app_fluxolivre/src/services/recommendation_engine.dart';
import 'package:app_fluxolivre/src/services/auth_service.dart';
import 'package:app_fluxolivre/src/services/session_store.dart';

import 'package:flutter/material.dart';

String _mensagemDoDiaTexto() {
  const mensagens = <String>[
    'Planeje bem cada medição antes de cortar alumínio ou perfil.',
    'Hoje é um bom dia para revisitar orçamentos pendentes e retornar contatos.',
    'Peça ajuda quando levantar vidros grandes — segurança em primeiro lugar.',
    'Vidro temperado combinado com esquadrias de qualidade dura anos com manutenção simples.',
    'Organize os pedidos por prioridade de entrega e evita surpresas na produção.',
    'Confira sempre vedação e ferragens após montagem.',
    'Uma porta bem alinhada evita rangidos e preserva fechamentos.',
    'No caixa forte do negócio, pequenas economias repetidas fazem grande diferença.',
    'Clientes bem informados sobre prazos reais ficam mais satisfeitos no fim.',
    'Dedique alguns minutos ao estoque: evita ruptura na hora do fechamento.',
    'Bom trabalho em equipe: quem fecha vende mais quando o backstage responde rápido.',
    'Finalize o dia atualizando o que foi vendido ou recebido de fornecedor.',
    'Chuva prevista? Vale reforçar proteção de obra com visita ou lembrete ao cliente.',
    'Em dúvidas técnicas, documente antes e depois: evita retrabalho custoso.',
  ];
  final hoje = DateTime.now();
  final ix =
      (hoje.difference(DateTime(hoje.year, 1, 1)).inDays + hoje.year % 997) %
      mensagens.length;
  return mensagens[ix];
}

IconButtonThemeData _homeIconButtonRipple(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return IconButtonThemeData(
    style: IconButton.styleFrom(
      overlayColor: WidgetStateColor.resolveWith((states) {
        if (dark) {
          if (states.contains(WidgetState.pressed)) {
            return const Color(0x40FFFFFF);
          }
          if (states.contains(WidgetState.hovered)) {
            return const Color(0x20FFFFFF);
          }
        } else {
          if (states.contains(WidgetState.pressed)) {
            return Colors.black26;
          }
          if (states.contains(WidgetState.hovered)) {
            return Colors.black12;
          }
        }
        return Colors.transparent;
      }),
    ),
  );
}

FilledButtonThemeData _homeFilledButtonRipple(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return FilledButtonThemeData(
    style: ButtonStyle(
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return dark ? const Color(0x40FFFFFF) : Colors.black26;
        }
        return Colors.transparent;
      }),
    ),
  );
}

TextButtonThemeData _homeTextButtonRipple(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return TextButtonThemeData(
    style: ButtonStyle(
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return dark ? const Color(0x33FFFFFF) : Colors.black26;
        }
        return Colors.transparent;
      }),
    ),
  );
}

enum AppThemeMode { light, dark, fullMoon }

class HomePage extends StatefulWidget {
  final UserProfile perfil;

  const HomePage({super.key, required this.perfil});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  AppThemeMode _themeMode = AppThemeMode.dark;
  bool _sidebarVisible = true;

  /// Boas-vindas em tela cheia (área de conteúdo) só após login; some ao tocar no rail ou em Continuar.
  bool _postLoginWelcomeVisible = true;
  final List<ChatMessage> _chatLog = [];
  Cliente? _clienteSelecionado;
  Produto? _produtoSelecionado;

  final _clienteController = TextEditingController();
  final _produtoController = TextEditingController();
  final _auditoriaController = TextEditingController();
  final _chatInputController = TextEditingController();

  Timer? _searchDebounce;
  Timer? _sessionSaveDebounce;
  String? _sessionId;
  bool _sessionHydrated = false;

  late final InventorySystem _inventorySystem;
  late final AuditLog _auditLog;
  late final RecommendationEngine _recommendationEngine;

  @override
  void initState() {
    super.initState();
    _inventorySystem = InventorySystem(onChanged: _schedulePersistSession);
    _auditLog = AuditLog(onChanged: _schedulePersistSession);

    _recommendationEngine = RecommendationEngine();

    void debouncedSearch() {
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 600), () {
        if (mounted) setState(() {});
      });
    }

    _clienteController.addListener(debouncedSearch);
    _produtoController.addListener(debouncedSearch);
    _auditoriaController.addListener(debouncedSearch);
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrateSession());
  }

  void _schedulePersistSession() {
    if (_sessionId == null || !_sessionHydrated) return;
    _sessionSaveDebounce?.cancel();
    _sessionSaveDebounce = Timer(const Duration(milliseconds: 450), () {
      unawaited(_persistSessionToDisk());
    });
  }

  Future<void> _hydrateSession() async {
    final sid = await SessionStore.getOrCreateSessionId(widget.perfil.cpf);
    _sessionId = sid;
    final payload = await SessionStore.loadPayload(sid);
    if (!mounted) return;
    var changed = false;
    if (payload.inv != null && payload.inv!.isNotEmpty) {
      try {
        final map = jsonDecode(payload.inv!) as Map<String, dynamic>;
        _inventorySystem.hydrateFromSessionMap(map);
        changed = true;
      } catch (_) {}
    } else {
      final cat = await SessionStore.loadCatalog(widget.perfil.cpf);
      if (cat != null && cat.isNotEmpty) {
        try {
          final map = jsonDecode(cat) as Map<String, dynamic>;
          _inventorySystem.hydrateCatalogOnly(map);
          changed = true;
        } catch (_) {}
      }
    }
    if (payload.audit != null && payload.audit!.isNotEmpty) {
      try {
        final list = jsonDecode(payload.audit!) as List<dynamic>;
        _auditLog.hydrateFromJson(list, widget.perfil);
        changed = true;
      } catch (_) {}
    }
    _auditLog.pruneOlderThan24h();
    _sessionHydrated = true;
    if (changed && mounted) setState(() {});
    unawaited(_persistSessionToDisk());
  }

  Future<void> _persistSessionToDisk() async {
    final sid = _sessionId;
    if (sid == null || !_sessionHydrated) return;
    try {
      final inv = jsonEncode(_inventorySystem.toSessionMap());
      final audit = jsonEncode(_auditLog.toSessionJsonList());
      final cat = jsonEncode(_inventorySystem.toCatalogMap());
      await SessionStore.savePayload(
        sessionId: sid,
        inventoryJson: inv,
        auditJson: audit,
      );
      await SessionStore.saveCatalog(widget.perfil.cpf, cat);
    } catch (_) {}
  }

  @override
  void dispose() {
    _sessionSaveDebounce?.cancel();
    _searchDebounce?.cancel();
    _clienteController.dispose();
    _produtoController.dispose();
    _auditoriaController.dispose();
    _chatInputController.dispose();
    super.dispose();
  }

  bool get _isOperario => widget.perfil.role == UserRole.operario;
  bool get _isAdministrador => widget.perfil.role == UserRole.administrador;

  /// Só gerente e administrador podem registar/editar produtos via assistente IA.
  bool get _podeIaEditarEstoque =>
      widget.perfil.role == UserRole.administrador ||
      widget.perfil.role == UserRole.gerente;
  bool get _darkMode => _themeMode != AppThemeMode.light;

  ThemeData get _theme {
    if (_themeMode == AppThemeMode.dark) {
      const surface = Color(0xFF121212);
      const cardFill = Color(0xFF1C1C1E);
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: surface,
        splashColor: const Color(0x3FFFFFFF),
        highlightColor: const Color(0x14FFFFFF),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF2D79FF),
          secondary: const Color(0xFF2D79FF),
          surface: surface,
          surfaceContainerLowest: surface,
          surfaceContainerLow: cardFill,
          surfaceContainer: const Color(0xFF242424),
          surfaceContainerHigh: const Color(0xFF2E2E2E),
          onSurface: Colors.white,
          onSurfaceVariant: const Color(0xFFB0B0B0),
        ),
        cardTheme: CardThemeData(
          color: cardFill,
          surfaceTintColor: Colors.transparent,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        iconButtonTheme: _homeIconButtonRipple(Brightness.dark),
        filledButtonTheme: _homeFilledButtonRipple(Brightness.dark),
        textButtonTheme: _homeTextButtonRipple(Brightness.dark),
      );
    }
    if (_themeMode == AppThemeMode.fullMoon) {
      const surface = Color(0xFF000000);
      const cardFill = Color(0xFF1A1608);
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: surface,
        splashColor: const Color(0x3FFFFFFF),
        highlightColor: const Color(0x14FFFFFF),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFFFC107),
          secondary: const Color(0xFFFFC107),
          surface: surface,
          surfaceContainerLowest: surface,
          surfaceContainerLow: cardFill,
          surfaceContainer: const Color(0xFF26200D),
          surfaceContainerHigh: const Color(0xFF322A10),
          onSurface: Color(0xFFFFE082),
          onSurfaceVariant: Color(0xFFFFD54F),
        ),
        cardTheme: CardThemeData(
          color: cardFill,
          surfaceTintColor: Colors.transparent,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        iconButtonTheme: _homeIconButtonRipple(Brightness.dark),
        filledButtonTheme: _homeFilledButtonRipple(Brightness.dark),
        textButtonTheme: _homeTextButtonRipple(Brightness.dark),
      );
    }
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      splashColor: Colors.black26,
      highlightColor: Colors.black12,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF2D79FF),
        secondary: Color(0xFF2D79FF),
      ),
      cardTheme: CardThemeData(
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      iconButtonTheme: _homeIconButtonRipple(Brightness.light),
      filledButtonTheme: _homeFilledButtonRipple(Brightness.light),
      textButtonTheme: _homeTextButtonRipple(Brightness.light),
    );
  }

  Future<void> _onLogout() async {
    final navigator = Navigator.of(context);
    final sid = _sessionId;
    if (sid != null) {
      await SessionStore.clearSessionForUser(
        cpf: widget.perfil.cpf,
        sessionId: sid,
      );
    }
    if (!navigator.mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  void _onAddCliente() {
    final perms = _inventorySystem.permissionsForRole(widget.perfil.role);
    if (!perms.canCreateCliente) {
      _showSnack('Seu perfil não pode adicionar clientes.');
      return;
    }
    _showClientePopup();
  }

  void _onAddProduto() {
    final perms = _inventorySystem.permissionsForRole(widget.perfil.role);
    if (!perms.canCreateProduto) {
      _showSnack('Seu perfil não pode adicionar produtos.');
      return;
    }
    _showProdutoPopup();
  }

  void _onEditCliente() {
    final perms = _inventorySystem.permissionsForRole(widget.perfil.role);
    if (!perms.canUpdatePreco) {
      _showSnack('Somente gerente ou administrador podem editar clientes.');
      return;
    }
    if (_clienteSelecionado == null) {
      _showSnack('Selecione um cliente na lista para editar.');
      return;
    }
    _showClientePopup(existing: _clienteSelecionado);
  }

  void _onEditProduto() {
    final perms = _inventorySystem.permissionsForRole(widget.perfil.role);
    if (!perms.canUpdatePreco) {
      _showSnack('Somente gerente ou administrador podem editar produtos.');
      return;
    }
    if (_produtoSelecionado == null) {
      _showSnack('Selecione um produto na lista para editar.');
      return;
    }
    _showProdutoPopup(existing: _produtoSelecionado);
  }

  void _onDeleteProdutoSelecionado() {
    final perms = _inventorySystem.permissionsForRole(widget.perfil.role);
    if (!perms.canRemove) {
      _showSnack('Somente gerente ou administrador podem remover produtos.');
      return;
    }
    final produto = _produtoSelecionado;
    if (produto == null) {
      _showSnack('Selecione um produto para remover.');
      return;
    }
    setState(() {
      _inventorySystem.removerProduto(produto);
      _auditLog.registrar(
        usuario: widget.perfil,
        tipo: AuditActionType.remocao,
        descricao: 'Produto ${produto.nome} removido',
      );
      _produtoSelecionado = null;
    });
  }

  void _showClientePopup({Cliente? existing}) {
    final nomeController = TextEditingController(text: existing?.nome ?? '');
    final cpfController = TextEditingController(text: existing?.cpf ?? '');

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            existing == null ? 'Adicionar cliente' : 'Editar cliente',
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cpfController,
                  decoration: const InputDecoration(
                    labelText: 'CPF',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final nome = nomeController.text.trim();
                final cpf = cpfController.text.trim();
                if (nome.isEmpty || cpf.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Informe nome e CPF.')),
                  );
                  return;
                }

                setState(() {
                  final nowId = DateTime.now().millisecondsSinceEpoch
                      .toString();
                  if (existing == null) {
                    final cliente = Cliente(
                      id: nowId,
                      nome: nome,
                      cpf: cpf,
                      segmento: 'Residencial',
                    );
                    _inventorySystem.addCliente(cliente);
                    _auditLog.registrar(
                      usuario: widget.perfil,
                      tipo: AuditActionType.adicao,
                      descricao: 'Cliente $nome adicionado',
                    );
                    _clienteSelecionado = cliente;
                  } else {
                    existing.nome = nome;
                    existing.cpf = cpf;
                    _auditLog.registrar(
                      usuario: widget.perfil,
                      tipo: AuditActionType.alteracao,
                      descricao: 'Cliente $nome atualizado',
                    );
                  }
                });
                Navigator.pop(context);
              },
              child: Text(existing == null ? 'Adicionar' : 'Salvar'),
            ),
          ],
        );
      },
    );
  }

  void _showProdutoPopup({Produto? existing}) {
    final nomeController = TextEditingController(text: existing?.nome ?? '');
    final custoController = TextEditingController(
      text: (existing?.preco ?? 0).toStringAsFixed(existing == null ? 0 : 2),
    );
    final materialController = TextEditingController(
      text: existing?.material ?? '',
    );
    final quantidadeController = TextEditingController(
      text: (existing?.quantidade ?? 1).toString(),
    );

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            existing == null ? 'Adicionar produto' : 'Editar produto',
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: custoController,
                  decoration: const InputDecoration(
                    labelText: 'Custo',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: materialController,
                  decoration: const InputDecoration(
                    labelText: 'Material',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: quantidadeController,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final nome = nomeController.text.trim();
                final material = materialController.text.trim();
                final custoText = custoController.text.trim().replaceAll(
                  ',',
                  '.',
                );
                final custo = double.tryParse(custoText);
                final quantidade = int.tryParse(
                  quantidadeController.text.trim(),
                );

                if (nome.isEmpty ||
                    material.isEmpty ||
                    custo == null ||
                    quantidade == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Preencha nome, custo, material e quantidade.',
                      ),
                    ),
                  );
                  return;
                }

                final perms = _inventorySystem.permissionsForRole(
                  widget.perfil.role,
                );
                final podeEditarCampos = perms.canUpdatePreco;

                setState(() {
                  if (existing == null) {
                    final produto = Produto(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      nome: nome,
                      preco: custo,
                      material: material,
                      quantidade: quantidade,
                    );
                    _inventorySystem.addProduto(produto);
                    _auditLog.registrar(
                      usuario: widget.perfil,
                      tipo: AuditActionType.adicao,
                      descricao: 'Produto $nome adicionado',
                    );
                    _produtoSelecionado = produto;
                  } else {
                    if (!podeEditarCampos) {
                      _showSnack(
                        'Somente gerente ou administrador podem editar informações do produto.',
                      );
                      return;
                    }
                    existing.nome = nome;
                    existing.preco = custo;
                    existing.material = material;
                    existing.quantidade = quantidade;
                    _auditLog.registrar(
                      usuario: widget.perfil,
                      tipo: AuditActionType.alteracao,
                      descricao: 'Produto $nome atualizado',
                    );
                    _produtoSelecionado = existing;
                  }
                });
                Navigator.pop(context);
              },
              child: Text(existing == null ? 'Adicionar' : 'Salvar'),
            ),
          ],
        );
      },
    );
  }

  void _onToggleQuantidade(Produto produto, int delta) {
    final perms = _inventorySystem.permissionsForRole(widget.perfil.role);
    if (!perms.canUpdateQuantidade) {
      _showSnack('Seu perfil não pode alterar quantidade.');
      return;
    }
    if (delta > 0) {
      _inventorySystem.atualizarQuantidade(produto, delta);
      _auditLog.registrar(
        usuario: widget.perfil,
        tipo: AuditActionType.alteracao,
        descricao:
            'Estoque de ${produto.nome} aumentado para ${produto.quantidade}',
      );
      setState(() {});
      return;
    }

    // delta < 0 simula uma venda: diminui estoque e aumenta vendas/receita.
    final vendido = _inventorySystem.registrarVenda(
      produto,
      quantidade: -delta,
    );
    if (!vendido) {
      _showSnack('Sem estoque para vender ${produto.nome}.');
      return;
    }
    _auditLog.registrar(
      usuario: widget.perfil,
      tipo: AuditActionType.alteracao,
      descricao:
          'Venda registrada: ${produto.nome} (-${-delta}). Estoque agora: ${produto.quantidade}',
    );
    setState(() {});
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Envia mensagem para o assistente IA e atualiza o chat
  Future<void> _enviarMensagemIa(String text) async {
    if (text.trim().isEmpty) return;

    // Adiciona mensagem do usuário imediatamente
    setState(() {
      _chatLog.add(ChatMessage(isUser: true, text: text.trim()));
    });
    _chatInputController.clear();

    // Adiciona mensagem de "pensando..." como placeholder com animação
    setState(() {
      _chatLog.add(
        ChatMessage(
          isUser: false,
          text: 'Pensando... 🤖',
          isLoading: true,
          isThinking: true,
        ),
      );
    });

    final linhasEstoque = RecommendationEngine.montarLinhasEstoque(
      _inventorySystem.produtos
          .map(
            (p) => <String, Object?>{
              'id': p.id,
              'nome': p.nome,
              'material': p.material,
              'preco': p.preco,
              'quantidade': p.quantidade,
            },
          )
          .toList(),
    );

    final outcome = await _recommendationEngine.responderComEstoque(
      mensagemUsuario: text.trim(),
      perfil: widget.perfil,
      linhasEstoque: linhasEstoque,
    );

    var resposta = outcome.texto;
    if (outcome.acao != null) {
      final erro = _aplicarAcaoIa(outcome.acao!);
      if (erro != null) {
        resposta += '\n\n⚠ $erro';
      } else {
        resposta += '\n\n✓ Alteração registada no estoque.';
      }
    }

    // Remove a mensagem de thinking e adiciona a resposta real
    setState(() {
      if (_chatLog.isNotEmpty && _chatLog.last.isThinking) {
        _chatLog.removeLast();
      }
      _chatLog.add(ChatMessage(isUser: false, text: resposta));
    });
  }

  /// Aplica instrução da IA no inventário (com permissão de perfil).
  String? _aplicarAcaoIa(IaEstoqueAcao acao) {
    if (!_podeIaEditarEstoque) {
      return 'Apenas gerente ou administrador podem adicionar ou editar produtos pelo assistente.';
    }
    switch (acao.op) {
      case IaEstoqueOp.add:
        final nome = acao.nome?.trim();
        if (nome == null || nome.isEmpty) {
          return 'O assistente não indicou o nome do produto.';
        }
        final preco = acao.preco;
        if (preco == null || preco <= 0) {
          return 'Preço inválido ou em falta.';
        }
        final qtd = acao.quantidade ?? 0;
        if (qtd < 0) return 'Quantidade inválida.';
        final id = 'ia_${DateTime.now().millisecondsSinceEpoch}';
        _inventorySystem.addProduto(
          Produto(
            id: id,
            nome: nome,
            preco: preco,
            material: acao.material?.trim() ?? '',
            quantidade: qtd,
          ),
        );
        return null;
      case IaEstoqueOp.update:
        final id = acao.id?.trim();
        if (id == null || id.isEmpty) {
          return 'ID do produto em falta para atualização.';
        }
        Produto? alvo;
        for (final p in _inventorySystem.produtos) {
          if (p.id == id) {
            alvo = p;
            break;
          }
        }
        if (alvo == null) {
          return 'Produto com id=$id não encontrado.';
        }
        _inventorySystem.atualizarDadosProduto(
          alvo,
          nome: acao.nome,
          material: acao.material,
          preco: acao.preco,
          quantidade: acao.quantidade,
        );
        return null;
    }
  }

  int get _pageCount {
    if (_isAdministrador) return 6;
    if (_isOperario) return 4;
    return 5;
  }

  Widget _buildCurrentPage() {
    var idx = _selectedIndex;
    if (idx >= _pageCount) idx = 0;

    if (_isAdministrador) {
      switch (idx) {
        case 0:
          return _buildClienteProdutoPage();
        case 1:
          return _buildEncomendasPage();
        case 2:
          return UserManagementPage(administradorLogado: widget.perfil);
        case 3:
          return _buildAuditoriaPage();
        case 4:
          return _buildAnalyticsPage();
        case 5:
          return _buildIaPage();
        default:
          return _buildClienteProdutoPage();
      }
    }

    switch (idx) {
      case 0:
        return _buildClienteProdutoPage();
      case 1:
        return _buildEncomendasPage();
      case 2:
        return _isOperario ? _buildAnalyticsPage() : _buildAuditoriaPage();
      case 3:
        return _isOperario ? _buildIaPage() : _buildAnalyticsPage();
      case 4:
        return _buildIaPage();
      default:
        return _buildClienteProdutoPage();
    }
  }

  String get _currentTitle {
    List<String> labels;
    if (_isAdministrador) {
      labels = const [
        'Clientes/Produtos',
        'Encomendas',
        'Gestão de Usuários',
        'Auditoria',
        'Analíticas',
        'Assistente IA',
      ];
    } else if (_isOperario) {
      labels = const [
        'Clientes/Produtos',
        'Encomendas',
        'Analíticas',
        'Assistente IA',
      ];
    } else {
      labels = const [
        'Clientes/Produtos',
        'Encomendas',
        'Auditoria',
        'Analíticas',
        'Assistente IA',
      ];
    }
    final idx = _selectedIndex.clamp(0, labels.length - 1);
    return labels[idx];
  }

  void _onRailDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
      _postLoginWelcomeVisible = false;
    });
  }

  void _dismissPostLoginWelcome() {
    if (!_postLoginWelcomeVisible) return;
    setState(() => _postLoginWelcomeVisible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedIndex >= _pageCount) {
      _selectedIndex = 0;
    }

    final barScheme = _theme.colorScheme;

    return Theme(
      data: _theme,
      child: Scaffold(
        appBar: AppBar(
          // Evita mudança de cor ao rolar o corpo (Material 3 “scrolled under”).
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          // Não usar Theme.of(context) aqui: o contexto do State fica *acima* deste Theme,
          // então pegaria o tema global (claro) em vez de _theme.
          backgroundColor: barScheme.surface,
          foregroundColor: barScheme.onSurface,
          iconTheme: IconThemeData(color: barScheme.onSurface),
          actionsIconTheme: IconThemeData(color: barScheme.onSurface),
          leading: IconButton(
            icon: Icon(_sidebarVisible ? Icons.menu_open : Icons.menu),
            onPressed: () {
              setState(() {
                _sidebarVisible = !_sidebarVisible;
              });
            },
            tooltip: _sidebarVisible
                ? 'Ocultar barra lateral'
                : 'Mostrar barra lateral',
          ),
          title: Text(_currentTitle),
          actions: [
            IconButton(
              icon: Icon(switch (_themeMode) {
                AppThemeMode.light => Icons.light_mode,
                AppThemeMode.dark => Icons.nightlight_round,
                AppThemeMode.fullMoon => Icons.nights_stay,
              }),
              onPressed: () {
                setState(() {
                  if (_themeMode == AppThemeMode.light) {
                    _themeMode = AppThemeMode.dark;
                  } else if (_themeMode == AppThemeMode.dark) {
                    _themeMode = AppThemeMode.fullMoon;
                  } else {
                    _themeMode = AppThemeMode.light;
                  }
                });
              },
              tooltip: 'Alternar tema (claro, escuro, lua cheia)',
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _onLogout,
              tooltip: 'Sair',
            ),
          ],
        ),
        body: Row(
          children: [
            if (_sidebarVisible) ...[
              SizedBox(
                width: 56,
                child: NavigationRail(
                  extended: false,
                  minExtendedWidth: 56,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onRailDestinationSelected,
                  labelType: NavigationRailLabelType.none,
                  leading: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        widget.perfil.nome.characters.first,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  trailing: const SizedBox.shrink(),
                  destinations: _isAdministrador
                      ? const [
                          NavigationRailDestination(
                            icon: Icon(Icons.inventory_2_outlined),
                            selectedIcon: Icon(Icons.inventory_2),
                            label: Text('Clientes'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.shopping_cart_checkout_outlined),
                            selectedIcon: Icon(Icons.shopping_cart_checkout),
                            label: Text('Encomendas'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.people_outlined),
                            selectedIcon: Icon(Icons.people),
                            label: Text('Usuários'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.fact_check_outlined),
                            selectedIcon: Icon(Icons.fact_check),
                            label: Text('Auditoria'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.analytics_outlined),
                            selectedIcon: Icon(Icons.analytics),
                            label: Text('Analíticas'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.smart_toy_outlined),
                            selectedIcon: Icon(Icons.smart_toy),
                            label: Text('IA'),
                          ),
                        ]
                      : _isOperario
                      ? const [
                          NavigationRailDestination(
                            icon: Icon(Icons.inventory_2_outlined),
                            selectedIcon: Icon(Icons.inventory_2),
                            label: Text('Clientes'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.shopping_cart_checkout_outlined),
                            selectedIcon: Icon(Icons.shopping_cart_checkout),
                            label: Text('Encomendas'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.analytics_outlined),
                            selectedIcon: Icon(Icons.analytics),
                            label: Text('Analíticas'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.smart_toy_outlined),
                            selectedIcon: Icon(Icons.smart_toy),
                            label: Text('IA'),
                          ),
                        ]
                      : const [
                          NavigationRailDestination(
                            icon: Icon(Icons.inventory_2_outlined),
                            selectedIcon: Icon(Icons.inventory_2),
                            label: Text('Clientes'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.shopping_cart_checkout_outlined),
                            selectedIcon: Icon(Icons.shopping_cart_checkout),
                            label: Text('Encomendas'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.fact_check_outlined),
                            selectedIcon: Icon(Icons.fact_check),
                            label: Text('Auditoria'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.analytics_outlined),
                            selectedIcon: Icon(Icons.analytics),
                            label: Text('Analíticas'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.smart_toy_outlined),
                            selectedIcon: Icon(Icons.smart_toy),
                            label: Text('IA'),
                          ),
                        ],
                ),
              ),
              const VerticalDivider(width: 1),
            ],
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RepaintBoundary(child: _buildCurrentPage()),
                  if (_postLoginWelcomeVisible)
                    Positioned.fill(
                      child: _PostLoginWelcomeOverlay(
                        nome: widget.perfil.nome,
                        isOperario: _isOperario,
                        onContinue: _dismissPostLoginWelcome,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsPage() {
    final a = _inventorySystem.resumoAnaliticas();
    final ano = DateTime.now().year;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AnaliticaSectionTitle('Novos clientes', _darkMode),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _KpiCard(
                  titulo: 'Hoje',
                  valor: a.dia.novosClientes.toString(),
                  icone: Icons.person_add_alt_1_outlined,
                  darkMode: _darkMode,
                ),
                _KpiCard(
                  titulo: 'Últimos 7 dias',
                  valor: a.semana.novosClientes.toString(),
                  icone: Icons.date_range_outlined,
                  darkMode: _darkMode,
                ),
                _KpiCard(
                  titulo: 'Este mês',
                  valor: a.mes.novosClientes.toString(),
                  icone: Icons.calendar_month_outlined,
                  darkMode: _darkMode,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _AnaliticaSectionTitle('Novas vendas', _darkMode),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _KpiCard(
                  titulo: 'Hoje',
                  valor: '${a.dia.numeroVendas} venda(s)',
                  subtitulo: 'R\$ ${a.dia.totalVendas.toStringAsFixed(2)}',
                  icone: Icons.point_of_sale_outlined,
                  darkMode: _darkMode,
                ),
                _KpiCard(
                  titulo: 'Últimos 7 dias',
                  valor: '${a.semana.numeroVendas} venda(s)',
                  subtitulo: 'R\$ ${a.semana.totalVendas.toStringAsFixed(2)}',
                  icone: Icons.point_of_sale_outlined,
                  darkMode: _darkMode,
                ),
                _KpiCard(
                  titulo: 'Este mês',
                  valor: '${a.mes.numeroVendas} venda(s)',
                  subtitulo: 'R\$ ${a.mes.totalVendas.toStringAsFixed(2)}',
                  icone: Icons.point_of_sale_outlined,
                  darkMode: _darkMode,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _AnaliticaSectionTitle(
              'Novas encomendas (entradas de estoque)',
              _darkMode,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _KpiCard(
                  titulo: 'Hoje',
                  valor: '${a.dia.numeroEncomendas} registro(s)',
                  subtitulo:
                      'Custo R\$ ${a.dia.custoEncomendas.toStringAsFixed(2)}',
                  icone: Icons.inventory_outlined,
                  darkMode: _darkMode,
                ),
                _KpiCard(
                  titulo: 'Últimos 7 dias',
                  valor: '${a.semana.numeroEncomendas} registro(s)',
                  subtitulo:
                      'Custo R\$ ${a.semana.custoEncomendas.toStringAsFixed(2)}',
                  icone: Icons.inventory_outlined,
                  darkMode: _darkMode,
                ),
                _KpiCard(
                  titulo: 'Este mês',
                  valor: '${a.mes.numeroEncomendas} registro(s)',
                  subtitulo:
                      'Custo R\$ ${a.mes.custoEncomendas.toStringAsFixed(2)}',
                  icone: Icons.inventory_outlined,
                  darkMode: _darkMode,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SaldoLucroCard(
              dia: a.dia,
              semana: a.semana,
              mes: a.mes,
              darkMode: _darkMode,
            ),
            const SizedBox(height: 24),
            _SimpleBarChart(
              titulo: 'Vendas no ano $ano (receita por mês)',
              meses: a.vendasMesAMesNoAno,
              darkMode: _darkMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClienteProdutoPage() {
    final qCliente = _clienteController.text.trim().toLowerCase();
    final qProduto = _produtoController.text.trim().toLowerCase();
    final clientesFiltrados = qCliente.isEmpty
        ? _inventorySystem.clientes
        : _inventorySystem.clientes.where(
            (c) => c.nome.toLowerCase().contains(qCliente),
          );
    final produtosFiltrados = (qProduto.isEmpty
        ? List<Produto>.from(_inventorySystem.produtos)
        : _inventorySystem.produtos
              .where((p) => p.nome.toLowerCase().contains(qProduto))
              .toList());

    final perms = _inventorySystem.permissionsForRole(widget.perfil.role);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 700;
          final conteudo = [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    titulo: 'Clientes',
                    onAdd: perms.canCreateCliente ? _onAddCliente : null,
                    onEdit: perms.canUpdatePreco ? _onEditCliente : null,
                    searchController: _clienteController,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Card(
                      child: ListView.builder(
                        itemCount: clientesFiltrados.length,
                        itemBuilder: (context, index) {
                          final cliente = clientesFiltrados.elementAt(index);
                          return ListTile(
                            selected: _clienteSelecionado?.id == cliente.id,
                            onTap: () {
                              setState(() => _clienteSelecionado = cliente);
                            },
                            title: Text(
                              cliente.nome,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              'CPF: ${cliente.cpf}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    titulo: 'Produtos',
                    onAdd: perms.canCreateProduto ? _onAddProduto : null,
                    onEdit: perms.canUpdatePreco ? _onEditProduto : null,
                    onDelete: perms.canRemove
                        ? _onDeleteProdutoSelecionado
                        : null,
                    searchController: _produtoController,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: produtosFiltrados.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'Nenhum produto encontrado.',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: produtosFiltrados.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final produto = produtosFiltrados[index];
                                final compactActions =
                                    isNarrow || _sidebarVisible;
                                final selected =
                                    _produtoSelecionado?.id == produto.id;
                                final scheme = Theme.of(context).colorScheme;
                                return Material(
                                  color: selected
                                      ? scheme.primary.withValues(alpha: 0.12)
                                      : null,
                                  child: InkWell(
                                    onTap: () => setState(
                                      () => _produtoSelecionado = produto,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  produto.nome,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        color: scheme.onSurface,
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                if (compactActions)
                                                  Text(
                                                    'Qtd: ${produto.quantidade} | R\$ ${produto.preco.toStringAsFixed(2)}',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: scheme
                                                              .onSurfaceVariant,
                                                        ),
                                                  )
                                                else
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        'Qtd: ${produto.quantidade}',
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                              color: scheme
                                                                  .onSurfaceVariant,
                                                            ),
                                                      ),
                                                      Text(
                                                        'Custo: R\$ ${produto.preco.toStringAsFixed(2)}',
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                              color: scheme
                                                                  .onSurfaceVariant,
                                                            ),
                                                      ),
                                                      Text(
                                                        produto
                                                                .material
                                                                .isNotEmpty
                                                            ? 'Material: ${produto.material}'
                                                            : 'Material',
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                              color: scheme
                                                                  .onSurfaceVariant,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.remove,
                                              size: 22,
                                            ),
                                            visualDensity:
                                                VisualDensity.compact,
                                            style: IconButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: const Size(36, 36),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            onPressed: () =>
                                                _onToggleQuantidade(
                                                  produto,
                                                  -1,
                                                ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.add,
                                              size: 22,
                                            ),
                                            visualDensity:
                                                VisualDensity.compact,
                                            style: IconButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: const Size(36, 36),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            onPressed: () =>
                                                _onToggleQuantidade(produto, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ];

          if (isNarrow) {
            return Column(
              children: [
                Expanded(child: conteudo[0]),
                const SizedBox(height: 16),
                Expanded(child: conteudo[2]),
              ],
            );
          }

          return Row(children: conteudo);
        },
      ),
    );
  }

  /// Edita o custo de encomenda de um produto
  void _onEditCustoEncomenda(Produto produto) {
    final perms = _inventorySystem.permissionsForRole(widget.perfil.role);
    if (!perms.canUpdatePreco) {
      _showSnack(
        'Somente gerente ou administrador podem editar custos de encomenda.',
      );
      return;
    }

    final custoController = TextEditingController(
      text: produto.getCustoEncomenda.toStringAsFixed(2),
    );

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar custo de encomenda'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Produto: ${produto.nome}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Preço do produto: R\$ ${produto.preco.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Custo de encomenda atual (30% desconto): R\$ ${produto.getCustoEncomenda.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: custoController,
                  decoration: const InputDecoration(
                    labelText: 'Novo custo de encomenda',
                    border: OutlineInputBorder(),
                    prefixText: 'R\$ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final custoText = custoController.text.trim().replaceAll(
                  ',',
                  '.',
                );
                final novoCusto = double.tryParse(custoText);

                if (novoCusto == null || novoCusto < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Informe um valor válido para o custo de encomenda.',
                      ),
                    ),
                  );
                  return;
                }

                setState(() {
                  produto.setCustoEncomenda(novoCusto);
                  _auditLog.registrar(
                    usuario: widget.perfil,
                    tipo: AuditActionType.alteracao,
                    descricao:
                        'Custo de encomenda de ${produto.nome} alterado para R\$ ${novoCusto.toStringAsFixed(2)}',
                  );
                });
                Navigator.pop(context);
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  /// Página de Encomendas - mostra produtos com seus custos de encomenda
  Widget _buildEncomendasPage() {
    final produtos = _inventorySystem.produtos;
    final perms = _inventorySystem.permissionsForRole(widget.perfil.role);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Encomendas',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sobre Encomendas'),
                      content: const Text(
                        'Nesta seção você pode visualizar e editar o custo de encomenda de cada produto.\n\n'
                        'O custo de encomenda é 30% menor que o preço do produto por padrão.\n\n'
                        'Este custo é utilizado quando você adiciona quantidade ao estoque (botão +) na seção de Produtos.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Entendi'),
                        ),
                      ],
                    ),
                  );
                },
                tooltip: 'Informações',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: produtos.isEmpty
                ? Card(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Nenhum produto cadastrado.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ),
                  )
                : Card(
                    child: ListView.separated(
                      itemCount: produtos.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final produto = produtos[index];
                        final scheme = Theme.of(context).colorScheme;
                        final custoEncomenda = produto.getCustoEncomenda;
                        final desconto =
                            ((1 - custoEncomenda / produto.preco) * 100)
                                .toStringAsFixed(0);

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: scheme.primaryContainer,
                            child: Icon(
                              Icons.shopping_cart_checkout,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                          title: Text(
                            produto.nome,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Preço: R\$ ${produto.preco.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                              Text(
                                'Custo de encomenda: R\$ ${custoEncomenda.toStringAsFixed(2)} ($desconto% menor)',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: scheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                          trailing: perms.canUpdatePreco
                              ? IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () =>
                                      _onEditCustoEncomenda(produto),
                                  tooltip: 'Editar custo de encomenda',
                                )
                              : null,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditoriaPage() {
    final q = _auditoriaController.text.trim().toLowerCase();
    final registrosFiltrados = q.isEmpty
        ? _auditLog.registros
        : _auditLog.registros.where(
            (r) => r.descricao.toLowerCase().contains(q),
          );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            titulo: 'Registro de auditoria',
            searchController: _auditoriaController,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Card(
              child: ListView.builder(
                itemCount: registrosFiltrados.length,
                itemBuilder: (context, index) {
                  final r = registrosFiltrados.elementAt(index);
                  return ListTile(
                    leading: Icon(
                      r.tipo == AuditActionType.adicao
                          ? Icons.add_circle_outline
                          : r.tipo == AuditActionType.alteracao
                          ? Icons.edit_outlined
                          : Icons.delete_outline,
                    ),
                    title: Text(r.descricao),
                    subtitle: Text(
                      '${r.usuario.nome} • ${r.horario.toLocal().toString().substring(0, 16)}',
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIaPage() {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Card(
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12.0),
                      itemCount: _chatLog.length,
                      itemBuilder: (context, index) {
                        final msg = _chatLog[index];
                        return Align(
                          alignment: msg.isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: msg.isUser
                                  ? colorScheme.primaryContainer
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.sizeOf(context).width * 0.75,
                            ),
                            child: Text(
                              msg.text,
                              style: TextStyle(
                                color: msg.isUser
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatInputController,
                            decoration: const InputDecoration(
                              hintText: 'Digite sua mensagem...',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onSubmitted: (text) {
                              if (text.trim().isEmpty) return;
                              _enviarMensagemIa(text.trim());
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          icon: const Icon(Icons.send),
                          onPressed: () {
                            final text = _chatInputController.text.trim();
                            if (text.isEmpty) return;
                            _enviarMensagemIa(text);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tela de boas-vindas após login; cobre só a área de conteúdo. O rail permanece clicável.
class _PostLoginWelcomeOverlay extends StatelessWidget {
  final String nome;
  final bool isOperario;
  final VoidCallback onContinue;

  const _PostLoginWelcomeOverlay({
    required this.nome,
    required this.isOperario,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textColor = scheme.onSurface;
    return Material(
      color: scheme.surface.withValues(alpha: 0.96),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.waving_hand,
                          size: 52,
                          color: scheme.primary,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Olá, $nome',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bem-vindo ao Fluxo Livre — Portas e Janelas.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 22),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.format_quote,
                                      color: scheme.primary,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Mensagem do dia',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(color: textColor),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _mensagemDoDiaTexto(),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(height: 1.4, color: textColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          isOperario
                              ? 'Toque em qualquer ícone na barra à esquerda para começar, '
                                    'ou use o botão abaixo.'
                              : 'Toque em qualquer ícone na barra à esquerda (Clientes, Auditoria, Analíticas…) '
                                    'ou use o botão abaixo.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: onContinue,
                          child: const Text('Continuar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final String? subtitulo;
  final IconData icone;
  final bool darkMode;

  const _KpiCard({
    required this.titulo,
    required this.valor,
    this.subtitulo,
    required this.icone,
    this.darkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = darkMode ? Colors.white : const Color(0xFF1C1C1E);
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icone, color: colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                titulo,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: textColor),
              ),
              const SizedBox(height: 4),
              Text(
                valor,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: textColor),
              ),
              if (subtitulo != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitulo!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AnaliticaSectionTitle extends StatelessWidget {
  final String texto;
  final bool darkMode;

  const _AnaliticaSectionTitle(this.texto, this.darkMode);

  @override
  Widget build(BuildContext context) {
    final labelColor = darkMode ? Colors.white : const Color(0xFF1C1C1E);
    return Text(
      texto,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: labelColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SaldoLucroCard extends StatelessWidget {
  final IndicadoresPeriodo dia;
  final IndicadoresPeriodo semana;
  final IndicadoresPeriodo mes;
  final bool darkMode;

  const _SaldoLucroCard({
    required this.dia,
    required this.semana,
    required this.mes,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelColor = darkMode ? Colors.white : const Color(0xFF1C1C1E);

    Widget linha(String periodo, IndicadoresPeriodo i) {
      final s = i.saldoLiquido;
      final neg = s < 0;
      final detailStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
        color: scheme.onSurfaceVariant,
        fontSize: 10,
        height: 1.2,
      );
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              periodo,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'R\$ ${s.abs().toStringAsFixed(2)}',
                maxLines: 1,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: neg ? scheme.error : const Color(0xFF2E7D32),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              neg ? 'Déficit' : 'Lucro',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: labelColor.withValues(alpha: 0.75),
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Vendas R\$ ${i.totalVendas.toStringAsFixed(2)}',
                    style: detailStyle,
                  ),
                  Text(
                    'Enc. R\$ ${i.custoEncomendas.toStringAsFixed(2)}',
                    style: detailStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: scheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Saldo (vendas − encomendas)',
                    maxLines: 2,
                    softWrap: true,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: labelColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Receita vs. custo das entradas.',
              maxLines: 2,
              softWrap: true,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 8),
            linha('Hoje', dia),
            linha('7 dias', semana),
            linha('Mês', mes),
          ],
        ),
      ),
    );
  }
}

class _SimpleBarChart extends StatelessWidget {
  final String titulo;
  final List<ResumoMesVendas> meses;
  final bool darkMode;

  const _SimpleBarChart({
    required this.titulo,
    required this.meses,
    required this.darkMode,
  });

  static const double _plotH = 52.0;
  static const double _labelH = 13.0;
  static const double _minDesignW = 200.0;
  static const double _perMonthW = 16.0;

  @override
  Widget build(BuildContext context) {
    final values = meses.map((m) => m.receita).toList(growable: false);
    final maxVal = values.fold<double>(1.0, (acc, v) => v > acc ? v : acc);
    final lineColor = Theme.of(context).colorScheme.primary;
    final labelColor = darkMode ? Colors.white : const Color(0xFF1C1C1E);
    final n = meses.length;
    final designW = n <= 0
        ? _minDesignW
        : (_minDesignW > n * _perMonthW ? _minDesignW : n * _perMonthW);
    final designH = _plotH + _labelH;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              titulo,
              maxLines: 2,
              softWrap: true,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: labelColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, c) {
                return Align(
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: designW,
                      height: designH,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: designW,
                            height: _plotH,
                            child: CustomPaint(
                              painter: _VendasLinePainter(
                                values: values,
                                maxY: maxVal,
                                lineColor: lineColor,
                                gridAlpha: darkMode ? 0.14 : 0.08,
                              ),
                              size: Size(designW, _plotH),
                            ),
                          ),
                          SizedBox(
                            width: designW,
                            height: _labelH,
                            child: Row(
                              children: List.generate(n, (i) {
                                return Expanded(
                                  child: Text(
                                    _monthLabelPt(meses[i].month),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.clip,
                                    style: TextStyle(
                                      fontSize: 8,
                                      height: 1,
                                      letterSpacing: -0.25,
                                      color: labelColor,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _VendasLinePainter extends CustomPainter {
  final List<double> values;
  final double maxY;
  final Color lineColor;
  final double gridAlpha;

  _VendasLinePainter({
    required this.values,
    required this.maxY,
    required this.lineColor,
    required this.gridAlpha,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    if (n == 0) return;

    const padT = 4.0;
    const padB = 3.0;
    final h = (size.height - padT - padB).clamp(1.0, size.height);
    final maxV = maxY <= 0 ? 1.0 : maxY;

    final gridPaint = Paint()
      ..color = lineColor.withValues(alpha: gridAlpha)
      ..strokeWidth = 1;
    for (var g = 1; g <= 2; g++) {
      final gy = padT + (g / 3) * h;
      canvas.drawLine(Offset(0, gy), Offset(size.width, gy), gridPaint);
    }

    double xFor(int i) => ((i + 0.5) / n) * size.width;

    double yFor(double v) {
      final t = (v / maxV).clamp(0.0, 1.0);
      return padT + h - t * h;
    }

    final points = <Offset>[
      for (var i = 0; i < n; i++) Offset(xFor(i), yFor(values[i])),
    ];

    if (n >= 2) {
      final fill = Path()
        ..moveTo(points.first.dx, size.height - padB)
        ..lineTo(points.first.dx, points.first.dy);
      for (var i = 1; i < n; i++) {
        fill.lineTo(points[i].dx, points[i].dy);
      }
      fill
        ..lineTo(points.last.dx, size.height - padB)
        ..close();
      canvas.drawPath(
        fill,
        Paint()
          ..color = lineColor.withValues(alpha: 0.14)
          ..style = PaintingStyle.fill,
      );
    }

    final stroke = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (n >= 2) {
      final line = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < n; i++) {
        line.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(line, stroke);
    }

    final dotFill = Paint()..color = lineColor;
    final dotBorder = Paint()
      ..color = lineColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final p in points) {
      canvas.drawCircle(p, 3, dotFill);
      canvas.drawCircle(p, 3, dotBorder);
    }
  }

  @override
  bool shouldRepaint(covariant _VendasLinePainter oldDelegate) {
    if (oldDelegate.values.length != values.length) return true;
    if (oldDelegate.maxY != maxY ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridAlpha != gridAlpha) {
      return true;
    }
    for (var i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) return true;
    }
    return false;
  }
}

class _SectionHeader extends StatelessWidget {
  final String titulo;
  final VoidCallback? onAdd;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final TextEditingController? searchController;

  const _SectionHeader({
    required this.titulo,
    this.onAdd,
    this.onEdit,
    this.onDelete,
    this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
            ),
            if (onAdd != null) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: onAdd,
                tooltip: 'Adicionar',
              ),
            ],
            if (onEdit != null) ...[
              const SizedBox(width: 2),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: onEdit,
                tooltip: 'Editar',
              ),
            ],
            if (onDelete != null) ...[
              const SizedBox(width: 2),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
                tooltip: 'Remover selecionado',
              ),
            ],
          ],
        ),
        if (searchController != null) ...[
          const SizedBox(height: 8),
          TextField(
            controller: searchController,
            decoration: const InputDecoration(
              isDense: true,
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ],
    );
  }
}

class Cliente {
  final String id;
  String nome;
  String cpf;
  final String segmento;
  final DateTime dataCadastro;

  Cliente({
    required this.id,
    required this.nome,
    required this.cpf,
    required this.segmento,
    DateTime? dataCadastro,
  }) : dataCadastro = dataCadastro ?? DateTime.now();
}

class Produto {
  final String id;
  String nome;
  double preco;
  String material;
  int quantidade;
  double?
  custoEncomenda; // Custo de encomenda (30% menos que o preco por padrao)

  Produto({
    required this.id,
    required this.nome,
    required this.preco,
    required this.material,
    required this.quantidade,
    this.custoEncomenda,
  }) {
    // Define o custo de encomenda como 30% menor que o preco, se nao for fornecido
    custoEncomenda ??= preco * 0.7;
  }

  /// Obtém o custo de encomenda do produto
  double get getCustoEncomenda => custoEncomenda ?? (preco * 0.7);

  /// Define o custo de encomenda
  void setCustoEncomenda(double valor) {
    custoEncomenda = valor;
  }
}

class InventoryPermissions {
  final bool canCreateCliente;
  final bool canCreateProduto;
  final bool canUpdateQuantidade;
  final bool canUpdatePreco;
  final bool canRemove;

  const InventoryPermissions({
    required this.canCreateCliente,
    required this.canCreateProduto,
    required this.canUpdateQuantidade,
    required this.canUpdatePreco,
    required this.canRemove,
  });
}

class _VendaRegistro {
  final DateTime quando;
  final double valor;

  _VendaRegistro({required this.quando, required this.valor});
}

class _EncomendaRegistro {
  final DateTime quando;
  final double valorCusto;

  _EncomendaRegistro({required this.quando, required this.valorCusto});
}

class InventorySystem {
  final List<Cliente> clientes = [];
  final List<Produto> produtos = [];
  int _itensVendidos = 0;
  double _receitaTotal = 0;
  final Map<int, _MonthSalesAccumulator> _vendasPorMes = {};
  final List<_VendaRegistro> _vendasRegistradas = [];
  final List<_EncomendaRegistro> _encomendasRegistradas = [];
  final void Function()? onChanged;

  InventorySystem({this.onChanged}) {
    final hoje = DateTime.now();
    clientes.addAll([
      Cliente(
        id: '1',
        nome: 'Cliente residencial',
        cpf: '11122233344',
        segmento: 'Residencial',
        dataCadastro: DateTime(
          hoje.year,
          hoje.month,
          hoje.day,
        ).subtract(const Duration(days: 2)),
      ),
      Cliente(
        id: '2',
        nome: 'Cliente comércio',
        cpf: '22233344455',
        segmento: 'Comercial',
        dataCadastro: DateTime(hoje.year, hoje.month, 1),
      ),
    ]);
    produtos.addAll([
      Produto(
        id: '1',
        nome: 'Porta de aço',
        preco: 1500,
        material: 'Aço galvanizado',
        quantidade: 3,
      ),
      Produto(
        id: '2',
        nome: 'Janela de PVC',
        preco: 900,
        material: 'PVC',
        quantidade: 5,
      ),
    ]);
  }

  void _notify() => onChanged?.call();

  List<Map<String, dynamic>> _clientesToJsonList() {
    return clientes
        .map(
          (c) => {
            'id': c.id,
            'nome': c.nome,
            'cpf': c.cpf,
            'seg': c.segmento,
            'dc': c.dataCadastro.millisecondsSinceEpoch,
          },
        )
        .toList();
  }

  List<Map<String, dynamic>> _produtosToJsonList() {
    return produtos
        .map(
          (p) => {
            'id': p.id,
            'nome': p.nome,
            'preco': p.preco,
            'mat': p.material,
            'q': p.quantidade,
            'ce': p.custoEncomenda,
          },
        )
        .toList();
  }

  /// Só clientes e produtos (persistência por CPF, sobrevive ao logout).
  Map<String, dynamic> toCatalogMap() {
    return {
      'v': 1,
      'clientes': _clientesToJsonList(),
      'produtos': _produtosToJsonList(),
    };
  }

  Map<String, dynamic> toSessionMap() {
    return {
      'v': 1,
      'clientes': _clientesToJsonList(),
      'produtos': _produtosToJsonList(),
      'iv': _itensVendidos,
      'rt': _receitaTotal,
      'vpm': _vendasPorMes.map(
        (k, v) => MapEntry('$k', {'i': v.itens, 'r': v.receita}),
      ),
      'vr': _vendasRegistradas
          .map((e) => {'ms': e.quando.millisecondsSinceEpoch, 'v': e.valor})
          .toList(),
      'er': _encomendasRegistradas
          .map(
            (e) => {'ms': e.quando.millisecondsSinceEpoch, 'c': e.valorCusto},
          )
          .toList(),
    };
  }

  void _applyClientesProdutosFromJson(Map<String, dynamic> json) {
    final cl = (json['clientes'] as List<dynamic>?) ?? [];
    final pr = (json['produtos'] as List<dynamic>?) ?? [];
    clientes.clear();
    for (final raw in cl) {
      final m = raw as Map<String, dynamic>;
      clientes.add(
        Cliente(
          id: m['id'] as String,
          nome: m['nome'] as String,
          cpf: m['cpf'] as String,
          segmento: m['seg'] as String? ?? 'Residencial',
          dataCadastro: DateTime.fromMillisecondsSinceEpoch(
            (m['dc'] as num).toInt(),
            isUtc: false,
          ),
        ),
      );
    }
    produtos.clear();
    for (final raw in pr) {
      final m = raw as Map<String, dynamic>;
      final custoEncomenda = m['ce'] as num?;
      produtos.add(
        Produto(
          id: m['id'] as String,
          nome: m['nome'] as String,
          preco: (m['preco'] as num).toDouble(),
          material: m['mat'] as String? ?? '',
          quantidade: (m['q'] as num).toInt(),
          custoEncomenda: custoEncomenda?.toDouble(),
        ),
      );
    }
  }

  /// Restaura só listas de clientes e produtos (ex.: após logout, sem snapshot de sessão).
  void hydrateCatalogOnly(Map<String, dynamic> json) {
    if (json['v'] != 1) return;
    _applyClientesProdutosFromJson(json);
  }

  void hydrateFromSessionMap(Map<String, dynamic> json) {
    if (json['v'] != 1) return;
    _applyClientesProdutosFromJson(json);
    _itensVendidos = (json['iv'] as num?)?.toInt() ?? 0;
    _receitaTotal = (json['rt'] as num?)?.toDouble() ?? 0;
    _vendasPorMes.clear();
    final vpm = json['vpm'];
    if (vpm is Map<String, dynamic>) {
      for (final e in vpm.entries) {
        final key = int.tryParse(e.key);
        if (key == null) continue;
        final mv = e.value as Map<String, dynamic>;
        final acc = _MonthSalesAccumulator()
          ..itens = (mv['i'] as num?)?.toInt() ?? 0
          ..receita = (mv['r'] as num?)?.toDouble() ?? 0;
        _vendasPorMes[key] = acc;
      }
    }
    _vendasRegistradas.clear();
    for (final raw in (json['vr'] as List<dynamic>?) ?? []) {
      final m = raw as Map<String, dynamic>;
      _vendasRegistradas.add(
        _VendaRegistro(
          quando: DateTime.fromMillisecondsSinceEpoch(
            (m['ms'] as num).toInt(),
            isUtc: false,
          ),
          valor: (m['v'] as num).toDouble(),
        ),
      );
    }
    _encomendasRegistradas.clear();
    for (final raw in (json['er'] as List<dynamic>?) ?? []) {
      final m = raw as Map<String, dynamic>;
      _encomendasRegistradas.add(
        _EncomendaRegistro(
          quando: DateTime.fromMillisecondsSinceEpoch(
            (m['ms'] as num).toInt(),
            isUtc: false,
          ),
          valorCusto: (m['c'] as num).toDouble(),
        ),
      );
    }
  }

  InventoryPermissions permissionsForRole(UserRole role) {
    switch (role) {
      case UserRole.operario:
        return const InventoryPermissions(
          canCreateCliente: true,
          canCreateProduto: true,
          canUpdateQuantidade: true,
          canUpdatePreco: false,
          canRemove: false,
        );
      case UserRole.gerente:
        return const InventoryPermissions(
          canCreateCliente: true,
          canCreateProduto: true,
          canUpdateQuantidade: true,
          canUpdatePreco: true,
          canRemove: true,
        );
      case UserRole.administrador:
        return const InventoryPermissions(
          canCreateCliente: true,
          canCreateProduto: true,
          canUpdateQuantidade: true,
          canUpdatePreco: true,
          canRemove: true,
        );
    }
  }

  void addCliente(Cliente cliente) {
    clientes.add(cliente);
    _notify();
  }

  void addProduto(Produto produto) {
    produtos.add(produto);
    final now = DateTime.now();
    _encomendasRegistradas.add(
      _EncomendaRegistro(
        quando: now,
        valorCusto: produto.preco * produto.quantidade,
      ),
    );
    _notify();
  }

  void atualizarQuantidade(Produto produto, int delta) {
    if (delta > 0) {
      final now = DateTime.now();
      // Usa o custo de encomenda (30% menor que o preco) em vez do preco do produto
      _encomendasRegistradas.add(
        _EncomendaRegistro(
          quando: now,
          valorCusto: produto.getCustoEncomenda * delta,
        ),
      );
    }
    produto.quantidade = (produto.quantidade + delta).clamp(0, 9999);
    _notify();
  }

  bool registrarVenda(Produto produto, {int quantidade = 1}) {
    if (quantidade <= 0) return false;
    if (produto.quantidade < quantidade) return false;
    final now = DateTime.now();
    final monthKey = (now.year * 100) + now.month; // yyyyMM
    produto.quantidade -= quantidade;
    _itensVendidos += quantidade;
    final receita = produto.preco * quantidade;
    _receitaTotal += receita;
    final acc = _vendasPorMes.putIfAbsent(
      monthKey,
      () => _MonthSalesAccumulator(),
    );
    acc.itens += quantidade;
    acc.receita += receita;
    _vendasRegistradas.add(_VendaRegistro(quando: now, valor: receita));
    _notify();
    return true;
  }

  List<ResumoMesVendas> ultimosMeses({int quantidade = 6}) {
    final now = DateTime.now();
    final result = <ResumoMesVendas>[];
    for (var back = quantidade - 1; back >= 0; back--) {
      final d = DateTime(now.year, now.month - back, 1);
      final key = (d.year * 100) + d.month;
      final acc = _vendasPorMes[key];
      result.add(
        ResumoMesVendas(
          year: d.year,
          month: d.month,
          label: _monthLabelPt(d.month),
          itens: acc?.itens ?? 0,
          receita: acc?.receita ?? 0,
        ),
      );
    }
    return result;
  }

  void atualizarPreco(Produto produto, double novoPreco) {
    produto.preco = novoPreco;
    _notify();
  }

  /// Atualização genérica (ex.: assistente IA).
  void atualizarDadosProduto(
    Produto produto, {
    String? nome,
    String? material,
    double? preco,
    int? quantidade,
  }) {
    if (nome != null) produto.nome = nome;
    if (material != null) produto.material = material;
    if (preco != null) produto.preco = preco;
    if (quantidade != null) {
      produto.quantidade = quantidade.clamp(0, 9999);
    }
    _notify();
  }

  void removerProduto(Produto produto) {
    produtos.remove(produto);
    _notify();
  }

  ResumoVendas resumoVendas() {
    return ResumoVendas(
      receitaTotal: _receitaTotal,
      totalItens: _itensVendidos,
      meses: ultimosMeses(quantidade: 6),
    );
  }

  DateTime _fimDoDia(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  IndicadoresPeriodo _indicadoresPeriodo({
    required DateTime inicio,
    required DateTime fim,
  }) {
    final novosClientes = clientes
        .where(
          (c) =>
              !c.dataCadastro.isBefore(inicio) && !c.dataCadastro.isAfter(fim),
        )
        .length;
    final vendas = _vendasRegistradas
        .where((v) => !v.quando.isBefore(inicio) && !v.quando.isAfter(fim))
        .toList();
    final enc = _encomendasRegistradas
        .where((e) => !e.quando.isBefore(inicio) && !e.quando.isAfter(fim))
        .toList();
    final totalV = vendas.fold<double>(0, (s, v) => s + v.valor);
    final totalE = enc.fold<double>(0, (s, e) => s + e.valorCusto);
    return IndicadoresPeriodo(
      novosClientes: novosClientes,
      numeroVendas: vendas.length,
      totalVendas: totalV,
      numeroEncomendas: enc.length,
      custoEncomendas: totalE,
    );
  }

  ResumoAnaliticasApp resumoAnaliticas() {
    final now = DateTime.now();
    final inicioHoje = DateTime(now.year, now.month, now.day);
    final fimAgora = _fimDoDia(now);
    final inicioSemana = inicioHoje.subtract(const Duration(days: 6));
    final inicioMes = DateTime(now.year, now.month, 1);

    return ResumoAnaliticasApp(
      dia: _indicadoresPeriodo(inicio: inicioHoje, fim: fimAgora),
      semana: _indicadoresPeriodo(inicio: inicioSemana, fim: fimAgora),
      mes: _indicadoresPeriodo(inicio: inicioMes, fim: fimAgora),
      vendasMesAMesNoAno: mesesDoAno(now.year),
    );
  }

  List<ResumoMesVendas> mesesDoAno(int year) {
    final result = <ResumoMesVendas>[];
    for (var m = 1; m <= 12; m++) {
      final key = (year * 100) + m;
      final acc = _vendasPorMes[key];
      result.add(
        ResumoMesVendas(
          year: year,
          month: m,
          label: _monthLabelPt(m),
          itens: acc?.itens ?? 0,
          receita: acc?.receita ?? 0,
        ),
      );
    }
    return result;
  }
}

class IndicadoresPeriodo {
  final int novosClientes;
  final int numeroVendas;
  final double totalVendas;
  final int numeroEncomendas;
  final double custoEncomendas;

  const IndicadoresPeriodo({
    required this.novosClientes,
    required this.numeroVendas,
    required this.totalVendas,
    required this.numeroEncomendas,
    required this.custoEncomendas,
  });

  double get saldoLiquido => totalVendas - custoEncomendas;
}

class ResumoAnaliticasApp {
  final IndicadoresPeriodo dia;
  final IndicadoresPeriodo semana;
  final IndicadoresPeriodo mes;
  final List<ResumoMesVendas> vendasMesAMesNoAno;

  const ResumoAnaliticasApp({
    required this.dia,
    required this.semana,
    required this.mes,
    required this.vendasMesAMesNoAno,
  });
}

class ResumoVendas {
  final double receitaTotal;
  final int totalItens;
  final List<ResumoMesVendas> meses;

  ResumoVendas({
    required this.receitaTotal,
    required this.totalItens,
    required this.meses,
  });
}

class ResumoMesVendas {
  final int year;
  final int month;
  final String label;
  final int itens;
  final double receita;

  ResumoMesVendas({
    required this.year,
    required this.month,
    required this.label,
    required this.itens,
    required this.receita,
  });
}

class _MonthSalesAccumulator {
  int itens = 0;
  double receita = 0;
}

String _monthLabelPt(int month) {
  switch (month) {
    case 1:
      return 'Jan';
    case 2:
      return 'Fev';
    case 3:
      return 'Mar';
    case 4:
      return 'Abr';
    case 5:
      return 'Mai';
    case 6:
      return 'Jun';
    case 7:
      return 'Jul';
    case 8:
      return 'Ago';
    case 9:
      return 'Set';
    case 10:
      return 'Out';
    case 11:
      return 'Nov';
    case 12:
      return 'Dez';
  }
  return 'Mês';
}

enum AuditActionType { adicao, alteracao, remocao }

AuditActionType _parseStoredAuditTipo(String name) {
  for (final t in AuditActionType.values) {
    if (t.name == name) return t;
  }
  return AuditActionType.alteracao;
}

UserRole _parseStoredUserRole(String name) {
  for (final r in UserRole.values) {
    if (r.name == name) return r;
  }
  return UserRole.operario;
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
            role: _parseStoredUserRole(
              m['uRole'] as String? ?? fallbackPerfil.role.name,
            ),
          ),
        ),
      );
    }
    registros.sort((a, b) => b.horario.compareTo(a.horario));
    pruneOlderThan24h();
  }
}

class ChatMessage {
  final bool isUser;
  final String text;
  final bool isLoading;
  final bool isThinking; // Nova flag para indicar que a IA está "pensando"

  ChatMessage({
    required this.isUser,
    required this.text,
    this.isLoading = false,
    this.isThinking = false,
  });
}
