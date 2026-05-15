// cadastro_test.dart

// import 'package:flutter_test/flutter_test.dart';
// import 'package:integration_test/integration_test.dart';
// import 'package:app_fluxolivre/main.dart' as app;
//
// void main() {
//   IntegrationTestWidgetsFlutterBinding.ensureInitialized();
//
//   testWidgets('Teste de cadastro de usuário', (tester) async {
//     app.main();
//     await tester.pumpAndSettle();
//
//     // Abre tela de cadastro
//     await tester.tap(find.text('Cadastrar'));
//     await tester.pumpAndSettle();
//
//     // Preenche campos
//     await tester.enterText(find.byType(TextField).at(0), 'Andre');
//     await tester.enterText(find.byType(TextField).at(1), 'andre@email.com');
//     await tester.enterText(find.byType(TextField).at(2), '123456');
//
//     // Clica no botão
//     await tester.tap(find.text('Criar Conta'));
//     await tester.pumpAndSettle();
//
//     // Verifica sucesso
//     expect(find.text('Cadastro realizado'), findsOneWidget);
//   });
// }
