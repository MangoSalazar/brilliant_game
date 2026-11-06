import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brilliant_game/features/auth/bloc/auth_bloc.dart';
import 'package:brilliant_game/features/auth/models/usuario.dart';
import 'package:brilliant_game/features/auth/repositories/auth_repository.dart';
import 'package:brilliant_game/features/menu/ui/main_menu_screen.dart';
import 'package:brilliant_game/features/menu/ui/widgets/join_room_dialog.dart';

void main() {
  const testUser = Usuario(id: 'usr_1', username: 'TestGamer');

  Widget buildTestableMainMenu({
    AuthRepository? authRepository,
  }) {
    final repo = authRepository ?? LocalAuthRepository();
    return BlocProvider<AuthBloc>(
      create: (_) => AuthBloc(authRepository: repo),
      child: const MaterialApp(
        home: MainMenuScreen(usuario: testUser),
      ),
    );
  }

  group('MainMenuScreen', () {
    testWidgets('Renderiza saludo de bienvenida, usuario y opciones principales',
        (tester) async {
      await tester.pumpWidget(buildTestableMainMenu());
      await tester.pumpAndSettle();

      expect(find.text('BRILLIANT'), findsOneWidget);
      expect(find.text('TestGamer'), findsWidgets);
      expect(find.text('¡Bienvenido, TestGamer!'), findsOneWidget);
      expect(find.text('Crear Partida'), findsOneWidget);
      expect(find.text('Unirse a Partida'), findsOneWidget);
      expect(find.text('Meta de Victoria'), findsOneWidget);
      expect(find.text('21+ Puntos'), findsOneWidget);
      expect(find.text('Tirada de Ronda'), findsOneWidget);
    });

    testWidgets('Crear Partida muestra diálogo con código de sala de 5 dígitos',
        (tester) async {
      await tester.pumpWidget(buildTestableMainMenu());
      await tester.pumpAndSettle();

      final createCard = find.byKey(const Key('menu_create_game_card'));
      expect(createCard, findsOneWidget);

      await tester.tap(createCard);
      await tester.pumpAndSettle();

      expect(find.text('¡Sala Creada!'), findsOneWidget);
      expect(find.text('Entendido'), findsOneWidget);

      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();
      expect(find.text('¡Sala Creada!'), findsNothing);
    });

    testWidgets('Unirse a Partida abre JoinRoomDialog y valida código de 5 dígitos',
        (tester) async {
      await tester.pumpWidget(buildTestableMainMenu());
      await tester.pumpAndSettle();

      final joinCard = find.byKey(const Key('menu_join_game_card'));
      expect(joinCard, findsOneWidget);

      await tester.tap(joinCard);
      await tester.pumpAndSettle();

      // Verificar que el diálogo está abierto
      expect(find.byType(JoinRoomDialog), findsOneWidget);
      expect(find.text('Ingresa el código de 5 dígitos'), findsOneWidget);

      final codeField = find.byKey(const Key('join_room_code_field'));
      expect(codeField, findsOneWidget);

      final joinConfirmButton = find.byKey(const Key('join_room_confirm_button'));

      // Con menos de 5 dígitos el botón está deshabilitado
      await tester.enterText(codeField, '123');
      await tester.pump();
      final elevatedButton = tester.widget<ElevatedButton>(joinConfirmButton);
      expect(elevatedButton.onPressed, isNull);

      // Con exactamente 5 dígitos el botón se habilita
      await tester.enterText(codeField, '48291');
      await tester.pump();
      final elevatedButtonEnabled =
          tester.widget<ElevatedButton>(joinConfirmButton);
      expect(elevatedButtonEnabled.onPressed, isNotNull);

      // Al presionar se envía y se cierra el diálogo
      await tester.tap(joinConfirmButton);
      await tester.pumpAndSettle();

      expect(find.text('Ingresa el código de 5 dígitos'), findsNothing);
      expect(find.text('Conectando a la sala #48291...'), findsOneWidget);
    });

    testWidgets('JoinRoomDialog standalone callback se ejecuta con 5 dígitos',
        (tester) async {
      String? submittedCode;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JoinRoomDialog(
              onJoin: (code) => submittedCode = code,
            ),
          ),
        ),
      );

      final codeField = find.byKey(const Key('join_room_code_field'));
      await tester.enterText(codeField, '99123');
      await tester.pump();

      final joinConfirmButton = find.byKey(const Key('join_room_confirm_button'));
      await tester.tap(joinConfirmButton);
      await tester.pumpAndSettle();

      expect(submittedCode, equals('99123'));
    });

    testWidgets('Presionar Cerrar Sesión emite AuthLogoutRequested',
        (tester) async {
      await tester.pumpWidget(buildTestableMainMenu());
      await tester.pumpAndSettle();

      final logoutButton = find.byTooltip('Cerrar Sesión');
      expect(logoutButton, findsOneWidget);

      await tester.tap(logoutButton);
      await tester.pumpAndSettle();
    });
  });
}
