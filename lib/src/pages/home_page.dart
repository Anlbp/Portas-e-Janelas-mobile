import 'dart:async';
import 'package:app_fluxolivre/src/pages/login_page.dart';
import 'package:app_fluxolivre/src/services/auth_service.dart';
import 'package:flutter/material.dart';

enum AppThemeMode { light, dark, fullMoon }

class HomePage extends StatefulWidget {
  final UserProfile perfil;

  const HomePage({
    super.key,
    required this.perfil,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  AppThemeMode _themeMode = AppThemeMode.dark;
  bool _sidebarVisible = true;
  final List<ChatMessage> _chatLog = [];
  Cliente? _clienteSelecionado;
  Produto? _produtoSelecionado;

  final _clienteController = TextEditingController();
  final _produtoController = TextEditingController();
  final _auditoriaController = TextEditingController();
  final _chatInputController = TextEditingController();

  Timer? _searchDebounce;

  final InventorySystem _inventorySystem = InventorySystem();
  final AuditLog _auditLog = AuditLog();
  final RecommendationEngine _recommendationEngine = RecommendationEngine();

  @override
  void initState() {
    super.initState();
    void debouncedSearch() {
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 600), () {
        if (mounted) setState(() {});
      });
    }
    _clienteController.addListener(debouncedSearch);
    _produtoController.addListener(debouncedSearch);
    _auditoriaController.addListener(debouncedSearch);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _clienteController.dispose();
    _produtoController.dispose();
    _auditoriaController.dispose();
    _chatInputController.dispose();
    super.dispose();
  }

  bool get _isOperario => widget.perfil.role == UserRole.operario;
  bool get _darkMode => _themeMode != AppThemeMode.light;

  ThemeData get _theme {
    if (_themeMode == AppThemeMode.dark) {
      return ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2D79FF),
          secondary: Color(0xFF2D79FF),
          surface: Color(0xFF121212),
          onSurface: Colors.white,
          onSurfaceVariant: Color(0xFFB0B0B0),
        ),
      );
    }
    if (_themeMode == AppThemeMode.fullMoon) {
      return ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF000000),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFC107),
          secondary: Color(0xFFFFC107),
          surface: Color(0xFF000000),
          onSurface: Color(0xFFFFE082),
          onSurfaceVariant: Color(0xFFFFD54F),
        ),
      );
    }
    return ThemeData.light().copyWith(
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF2D79FF),
        secondary: Color(0xFF2D79FF),
      ),
    );
  }

  void _onLogout() {
    Navigator.of(context).pushAndRemoveUntil(
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
          title: Text(existing == null ? 'Adicionar cliente' : 'Editar cliente'),
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
                  final nowId = DateTime.now().millisecondsSinceEpoch.toString();
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
          title: Text(existing == null ? 'Adicionar produto' : 'Editar produto'),
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
                final custoText = custoController.text.trim().replaceAll(',', '.');
                final custo = double.tryParse(custoText);
                final quantidade = int.tryParse(quantidadeController.text.trim());

                if (nome.isEmpty || material.isEmpty || custo == null || quantidade == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preencha nome, custo, material e quantidade.')),
                  );
                  return;
                }

                final perms = _inventorySystem.permissionsForRole(widget.perfil.role);
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
                      _showSnack('Somente gerente ou administrador podem editar informações do produto.');
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
    _inventorySystem.atualizarQuantidade(produto, delta);
    _auditLog.registrar(
      usuario: widget.perfil,
      tipo: AuditActionType.alteracao,
      descricao:
          'Quantidade de ${produto.nome} alterada para ${produto.quantidade}',
    );
    setState(() {});
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  int get _pageCount => _isOperario ? 3 : 4;

  Widget _buildCurrentPage() {
    var idx = _selectedIndex;
    if (idx >= _pageCount) idx = 0;
    switch (idx) {
      case 0:
        return _buildAnalyticsPage();
      case 1:
        return _buildClienteProdutoPage();
      case 2:
        return _isOperario ? _buildIaPage() : _buildAuditoriaPage();
      case 3:
        return _buildIaPage();
      default:
        return _buildAnalyticsPage();
    }
  }

  String get _currentTitle {
    final labels = <String>[
      'Analítica',
      'Clientes/Produtos',
      if (!_isOperario) 'Auditoria',
      'Recomendações IA',
    ];
    final idx = _selectedIndex >= labels.length ? 0 : _selectedIndex;
    return labels[idx];
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedIndex >= _pageCount) {
      _selectedIndex = 0;
    }

    return Theme(
      data: _theme,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(_sidebarVisible ? Icons.menu_open : Icons.menu),
            onPressed: () {
              setState(() {
                _sidebarVisible = !_sidebarVisible;
              });
            },
            tooltip: _sidebarVisible ? 'Ocultar barra lateral' : 'Mostrar barra lateral',
          ),
          title: Text(_currentTitle),
          actions: [
            IconButton(
              icon: Icon(
                switch (_themeMode) {
                  AppThemeMode.light => Icons.light_mode,
                  AppThemeMode.dark => Icons.nightlight_round,
                  AppThemeMode.fullMoon => Icons.nights_stay,
                },
              ),
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
                  onDestinationSelected: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  labelType: NavigationRailLabelType.none,
                  leading: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        widget.perfil.nome.characters.first,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ),
                  trailing: const SizedBox.shrink(),
                  destinations: [
                    const NavigationRailDestination(
                      icon: Icon(Icons.analytics_outlined),
                      selectedIcon: Icon(Icons.analytics),
                      label: Text('Analítica'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.inventory_2_outlined),
                      selectedIcon: Icon(Icons.inventory_2),
                      label: Text('Clientes/Produtos'),
                    ),
                    if (!_isOperario)
                      const NavigationRailDestination(
                        icon: Icon(Icons.fact_check_outlined),
                        selectedIcon: Icon(Icons.fact_check),
                        label: Text('Auditoria'),
                      ),
                    const NavigationRailDestination(
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
              child: RepaintBoundary(
                child: _buildCurrentPage(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsPage() {
    final resumo = _inventorySystem.resumoVendas();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _KpiCard(
                  titulo: 'Receita total',
                  valor: 'R\$ ${resumo.receitaTotal.toStringAsFixed(2)}',
                  icone: Icons.payments,
                  darkMode: _darkMode,
                ),
                _KpiCard(
                  titulo: 'Itens vendidos',
                  valor: resumo.totalItens.toString(),
                  icone: Icons.shopping_cart_checkout,
                  darkMode: _darkMode,
                ),
                _KpiCard(
                  titulo: 'Produtos ativos',
                  valor: _inventorySystem.produtos.length.toString(),
                  icone: Icons.inventory,
                  darkMode: _darkMode,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SimpleBarChart(
              receitaTotal: resumo.receitaTotal,
              totalItens: resumo.totalItens,
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
        : _inventorySystem.clientes
            .where((c) => c.nome.toLowerCase().contains(qCliente));
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
                            selected:
                                _clienteSelecionado?.id == cliente.id,
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
                    onDelete: perms.canRemove ? _onDeleteProdutoSelecionado : null,
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
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
                                        () => _produtoSelecionado = produto),
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
                                                        produto.material
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
                                            icon: const Icon(Icons.remove,
                                                size: 22),
                                            visualDensity:
                                                VisualDensity.compact,
                                            style: IconButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize:
                                                  const Size(36, 36),
                                              tapTargetSize: MaterialTapTargetSize
                                                  .shrinkWrap,
                                            ),
                                            onPressed: () =>
                                                _onToggleQuantidade(
                                                    produto, -1),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add,
                                                size: 22),
                                            visualDensity:
                                                VisualDensity.compact,
                                            style: IconButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize:
                                                  const Size(36, 36),
                                              tapTargetSize: MaterialTapTargetSize
                                                  .shrinkWrap,
                                            ),
                                            onPressed: () =>
                                                _onToggleQuantidade(
                                                    produto, 1),
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

          return Row(
            children: conteudo,
          );
        },
      ),
    );
  }

  Widget _buildAuditoriaPage() {
    final q = _auditoriaController.text.trim().toLowerCase();
    final registrosFiltrados = q.isEmpty
        ? _auditLog.registros
        : _auditLog.registros
            .where((r) => r.descricao.toLowerCase().contains(q));

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
                        '${r.usuario.nome} • ${r.horario.toLocal().toString().substring(0, 16)}'),
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
                                horizontal: 12, vertical: 8),
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
                              setState(() {
                                _chatLog.add(ChatMessage(
                                    isUser: true, text: text.trim()));
                                final resposta = _recommendationEngine
                                    .respostaParaMensagem(text.trim());
                                _chatLog.add(ChatMessage(
                                    isUser: false, text: resposta));
                              });
                              _chatInputController.clear();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          icon: const Icon(Icons.send),
                          onPressed: () {
                            final text =
                                _chatInputController.text.trim();
                            if (text.isEmpty) return;
                            setState(() {
                              _chatLog.add(ChatMessage(
                                  isUser: true, text: text));
                              final resposta = _recommendationEngine
                                  .respostaParaMensagem(text);
                              _chatLog.add(ChatMessage(
                                  isUser: false, text: resposta));
                            });
                            _chatInputController.clear();
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

class _KpiCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;
  final bool darkMode;

  const _KpiCard({
    required this.titulo,
    required this.valor,
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textColor,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                valor,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: textColor,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimpleBarChart extends StatelessWidget {
  final double receitaTotal;
  final int totalItens;
  final bool darkMode;

  const _SimpleBarChart({
    required this.receitaTotal,
    required this.totalItens,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    final labels = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun'];
    final maxVal = (receitaTotal + totalItens * 200).clamp(1.0, double.infinity);
    final values = [
      receitaTotal * 0.4,
      receitaTotal * 0.6,
      receitaTotal * 0.8,
      receitaTotal * 0.9,
      receitaTotal,
      receitaTotal * 0.85,
    ];
    final barColor = Theme.of(context).colorScheme.primary;
    final labelColor = darkMode ? Colors.white : const Color(0xFF1C1C1E);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vendas por período',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: labelColor,
                  ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(6, (i) {
                  final h = (values[i] / maxVal * 160).clamp(8.0, 160.0);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: h,
                            decoration: BoxDecoration(
                              color: barColor.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            labels[i],
                            style: TextStyle(
                              fontSize: 12,
                              color: labelColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
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

  Cliente({
    required this.id,
    required this.nome,
    required this.cpf,
    required this.segmento,
  });
}

class Produto {
  final String id;
  String nome;
  double preco;
  String material;
  int quantidade;

  Produto({
    required this.id,
    required this.nome,
    required this.preco,
    required this.material,
    required this.quantidade,
  });
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

class InventorySystem {
  final List<Cliente> clientes = [];
  final List<Produto> produtos = [];

  InventorySystem() {
    clientes.addAll([
      Cliente(
        id: '1',
        nome: 'Cliente residencial',
        cpf: '11122233344',
        segmento: 'Residencial',
      ),
      Cliente(
        id: '2',
        nome: 'Cliente comércio',
        cpf: '22233344455',
        segmento: 'Comercial',
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
  }

  void addProduto(Produto produto) {
    produtos.add(produto);
  }

  void atualizarQuantidade(Produto produto, int delta) {
    produto.quantidade = (produto.quantidade + delta).clamp(0, 9999);
  }

  void atualizarPreco(Produto produto, double novoPreco) {
    produto.preco = novoPreco;
  }

  void removerProduto(Produto produto) {
    produtos.remove(produto);
  }

  ResumoVendas resumoVendas() {
    final receita = produtos.fold<double>(
      0,
      (acc, p) => acc + (p.preco * p.quantidade),
    );
    final itens = produtos.fold<int>(
      0,
      (acc, p) => acc + p.quantidade,
    );
    return ResumoVendas(
      receitaTotal: receita,
      totalItens: itens,
    );
  }
}

class ResumoVendas {
  final double receitaTotal;
  final int totalItens;

  ResumoVendas({
    required this.receitaTotal,
    required this.totalItens,
  });
}

enum AuditActionType { adicao, alteracao, remocao }

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
  final List<AuditRecord> registros = [];

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
  }
}

class ChatMessage {
  final bool isUser;
  final String text;

  ChatMessage({required this.isUser, required this.text});
}

/// API key pode ser definida no código (ex.: constante ou variável de ambiente).
class RecommendationEngine {
  static const String _apiKeyPlaceholder = ''; // Reserve para API key no código

  String? get apiKey => _apiKeyPlaceholder.isEmpty ? null : _apiKeyPlaceholder;

  String respostaParaMensagem(String mensagem) {
    final m = mensagem.toLowerCase();
    if (m.contains('porta') && (m.contains('entrada') || m.contains('segur'))) {
      return cenarioPortaEntradaSegura();
    }
    if (m.contains('janela') && (m.contains('quarto') || m.contains('silêncio') || m.contains('isolamento'))) {
      return cenarioJanelaQuartoSilencio();
    }
    if (m.contains('janela') && (m.contains('sala') || m.contains('luz') || m.contains('grande'))) {
      return cenarioJanelaSalaLuz();
    }
    if (m.contains('porta') && (m.contains('interna') || m.contains('modern'))) {
      return cenarioPortaInternaModerna();
    }
    if (m.contains('janela') && m.contains('banheiro')) {
      return cenarioJanelaBanheiro();
    }
    return 'Descreva o ambiente (porta ou janela, local e preferências) para uma recomendação. Ex.: "porta de entrada com mais segurança" ou "janela para quarto com isolamento acústico".';
  }

  String cenarioPortaEntradaSegura() {
    return 'Recomendamos uma porta de aço galvanizado ou alumínio reforçado com pintura eletrostática. '
        'Esses materiais possuem alta resistência contra impactos, não enferrujam facilmente e suportam bem chuva e sol. '
        'Também sugerimos fechadura multiponto para maior segurança.';
  }

  String cenarioJanelaQuartoSilencio() {
    return 'Recomendamos uma janela com vidro duplo (insulado) e esquadrias de PVC. '
        'Esse tipo de janela reduz significativamente ruídos externos e mantém melhor o conforto térmico no quarto.';
  }

  String cenarioJanelaSalaLuz() {
    return 'Recomendamos uma janela de correr grande em alumínio com vidro temperado. '
        'Esse modelo permite maior entrada de luz natural, boa ventilação e ocupa pouco espaço ao abrir.';
  }

  String cenarioPortaInternaModerna() {
    return 'Recomendamos uma porta de madeira com acabamento laqueado ou porta de MDF com frisos modernos. '
        'Esses modelos oferecem boa privacidade e combinam bem com ambientes contemporâneos.';
  }

  String cenarioJanelaBanheiro() {
    return 'Recomendamos uma janela basculante de alumínio com vidro canelado ou fosco. '
        'Esse tipo de janela permite ventilação contínua e mantém a privacidade do ambiente.';
  }
}
