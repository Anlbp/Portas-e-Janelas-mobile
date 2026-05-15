// login_test.dart

// import 'package:flutter_test/flutter_test.dart';
// import 'package:integration_test/integration_test.dart';
// import 'package:app_fluxolivre/main.dart' as app;
//
// void main() {
//   IntegrationTestWidgetsFlutterBinding.ensureInitialized();
//
//   testWidgets('Teste de login', (tester) async {
//     app.main();
//     await tester.pumpAndSettle();
//
//     // Preenche email
//     await tester.enterText(
//       find.byType(TextField).at(0),
//       'andre@email.com',
//     );
//
//     // Preenche senha
//     await tester.enterText(
//       find.byType(TextField).at(1),
//       '123456',
//     );
//
//     // Faz login
//     await tester.tap(find.text('Entrar'));
//     await tester.pumpAndSettle();
//
//     // Verifica se entrou no sistema
//     expect(find.text('Página Inicial'), findsOneWidget);
//   });
// }
