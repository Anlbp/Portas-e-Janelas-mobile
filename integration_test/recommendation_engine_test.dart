// recommendation_engine_test.dart

// import 'package:flutter_test/flutter_test.dart';
// import 'package:app_fluxolivre/src/services/recommendation_engine.dart';
// import 'package:app_fluxolivre/src/services/auth_service.dart';
//
// void main() {
//   group('RecommendationEngine', () {
//     late RecommendationEngine engine;
//
//     setUp(() {
//       engine = RecommendationEngine();
//     });
//
//     test('Deve montar linhas do estoque corretamente', () {
//       final produtos = [
//         {
//           'id': '1',
//           'nome': 'Janela PVC',
//           'material': 'PVC',
//           'preco': 450.0,
//           'quantidade': 10,
//         },
//         {
//           'id': '2',
//           'nome': 'Porta Alumínio',
//           'material': 'Alumínio',
//           'preco': 700.0,
//           'quantidade': 5,
//         },
//       ];
//
//       final resultado = RecommendationEngine.montarLinhasEstoque(produtos);
//
//       expect(resultado.contains('Janela PVC'), true);
//       expect(resultado.contains('Porta Alumínio'), true);
//     });
//
//     test('Deve retornar mensagem quando estoque estiver vazio', () {
//       final resultado = RecommendationEngine.montarLinhasEstoque([]);
//
//       expect(
//         resultado,
//         '(nenhum produto cadastrado no momento)',
//       );
//     });
//
//     test('Deve retornar texto simples via respostaParaMensagem', () async {
//       final resposta = await engine.respostaParaMensagem(
//         'Olá, vocês trabalham com PVC?',
//       );
//
//       expect(resposta.isNotEmpty, true);
//     });
//
//     test('Deve responder com estoque para operário', () async {
//       final perfil = UserProfile(
//         cpf: '123',
//         nome: 'Operário Teste',
//         role: UserRole.operario,
//       );
//
//       final resposta = await engine.responderComEstoque(
//         mensagemUsuario: 'Qual o preço da janela PVC?',
//         perfil: perfil,
//         linhasEstoque: '''
// - id=1 | Janela PVC | material: PVC | preço R\$ 450.0 | qtd em estoque: 10
// ''',
//       );
//
//       expect(resposta.texto.isNotEmpty, true);
//     });
//
//     test('Deve impedir alteração para operário', () async {
//       final perfil = UserProfile(
//         cpf: '123',
//         nome: 'Operário',
//         role: UserRole.operario,
//       );
//
//       final resposta = await engine.responderComEstoque(
//         mensagemUsuario: 'Adicionar produto novo',
//         perfil: perfil,
//         linhasEstoque: '(sem estoque)',
//       );
//
//       expect(resposta.acao, null);
//     });
//
//     test('Deve permitir alteração para gerente', () async {
//       final perfil = UserProfile(
//         cpf: '999',
//         nome: 'Gerente',
//         role: UserRole.gerente,
//       );
//
//       final resposta = await engine.responderComEstoque(
//         mensagemUsuario:
//             'Adicionar porta de vidro por 900 reais',
//         perfil: perfil,
//         linhasEstoque: '(sem estoque)',
//       );
//
//       expect(resposta.texto.isNotEmpty, true);
//     });
//
//     test('Deve tratar timeout corretamente', () async {
//       final perfil = UserProfile(
//         cpf: '1',
//         nome: 'Teste',
//         role: UserRole.administrador,
//       );
//
//       final resposta = await engine.responderComEstoque(
//         mensagemUsuario: '',
//         perfil: perfil,
//         linhasEstoque: '',
//       );
//
//       expect(resposta.texto.isNotEmpty, true);
//     });
//
//     test('Deve validar estrutura do outcome', () {
//       const outcome = IaAssistenteOutcome(
//         texto: 'Produto cadastrado',
//       );
//
//       expect(outcome.texto, 'Produto cadastrado');
//       expect(outcome.acao, null);
//     });
//
//     test('Deve validar criação de ação add', () {
//       const acao = IaEstoqueAcao(
//         op: IaEstoqueOp.add,
//         nome: 'Janela',
//         material: 'PVC',
//         preco: 500,
//         quantidade: 2,
//       );
//
//       expect(acao.op, IaEstoqueOp.add);
//       expect(acao.nome, 'Janela');
//     });
//
//     test('Deve validar criação de ação update', () {
//       const acao = IaEstoqueAcao(
//         op: IaEstoqueOp.update,
//         id: '1',
//         preco: 999,
//       );
//
//       expect(acao.op, IaEstoqueOp.update);
//       expect(acao.id, '1');
//     });
//   });
// }
