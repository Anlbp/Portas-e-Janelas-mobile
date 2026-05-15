// navegacao_test.dart

// import 'package:flutter_test/flutter_test.dart';
// import 'package:integration_test/integration_test.dart';
// import 'package:app_fluxolivre/main.dart' as app;
//
// void main() {
//   IntegrationTestWidgetsFlutterBinding.ensureInitialized();
//
//   testWidgets('Teste de navegação entre telas', (tester) async {
//     app.main();
//     await tester.pumpAndSettle();
//
//     // Vai para perfil
//     await tester.tap(find.text('Perfil'));
//     await tester.pumpAndSettle();
//
//     // Verifica tela perfil
//     expect(find.text('Meu Perfil'), findsOneWidget);
//
//     // Volta para home
//     await tester.pageBack();
//     await tester.pumpAndSettle();
//
//     // Verifica home
//     expect(find.text('Página Inicial'), findsOneWidget);
//   });
// }
