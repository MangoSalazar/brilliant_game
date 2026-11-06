import 'package:flutter_test/flutter_test.dart';
import 'package:brilliant_game/main.dart';
import 'package:brilliant_game/features/auth/repositories/auth_repository.dart';

void main() {
  testWidgets('BrilliantApp renderiza AuthScreen con campos de login', (WidgetTester tester) async {
    final authRepository = LocalAuthRepository();
    await tester.pumpWidget(BrilliantApp(authRepository: authRepository));
    await tester.pump();

    // Comprobar título del juego y formulario de login
    expect(find.text('BRILLIANT'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.text('Crear Cuenta'), findsOneWidget);
    expect(find.text('ENTRAR A LA PARTIDA'), findsOneWidget);

    // Cambiar a la pestaña de Crear Cuenta
    await tester.tap(find.text('Crear Cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('CONFIRMAR CONTRASEÑA'), findsOneWidget);
    expect(find.text('REGISTRARSE'), findsOneWidget);
  });
}
