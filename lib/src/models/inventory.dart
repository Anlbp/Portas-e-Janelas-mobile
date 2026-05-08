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
  double? custoEncomenda;

  Produto({
    required this.id,
    required this.nome,
    required this.preco,
    required this.material,
    required this.quantidade,
    this.custoEncomenda,
  }) {
    custoEncomenda ??= preco * 0.7;
  }

  double get getCustoEncomenda => custoEncomenda ?? (preco * 0.7);

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

class _MonthSalesAccumulator {
  int itens = 0;
  double receita = 0;
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
        cpf: '111.222.333-44',
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
        cpf: '222.333.444-55',
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
        (k, v) => MapEntry('\$k', {'i': v.itens, 'r': v.receita}),
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

  InventoryPermissions permissionsForRole(dynamic roleObj) {
    final role = roleObj as String;
    switch (role) {
      case 'operario':
        return const InventoryPermissions(
          canCreateCliente: true,
          canCreateProduto: true,
          canUpdateQuantidade: true,
          canUpdatePreco: false,
          canRemove: false,
        );
      case 'gerente':
        return const InventoryPermissions(
          canCreateCliente: true,
          canCreateProduto: true,
          canUpdateQuantidade: true,
          canUpdatePreco: true,
          canRemove: true,
        );
      case 'administrador':
        return const InventoryPermissions(
          canCreateCliente: true,
          canCreateProduto: true,
          canUpdateQuantidade: true,
          canUpdatePreco: true,
          canRemove: true,
        );
    }
    throw ArgumentError('Invalid role: $role');
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
    final monthKey = (now.year * 100) + now.month;
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
