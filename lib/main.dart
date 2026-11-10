import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_state.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'features/auth/ui/auth_screen.dart';
import 'features/lobby/bloc/lobby_bloc.dart';
import 'features/lobby/bloc/lobby_event.dart';
import 'features/lobby/bloc/lobby_state.dart';
import 'features/lobby/repositories/lobby_repository.dart';
import 'features/lobby/ui/lobby_screen.dart';
import 'features/menu/ui/main_menu_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final authRepository = RemoteAuthRepository();
  final lobbyRepository = WebSocketLobbyRepository();

  runApp(
    BrilliantApp(
      authRepository: authRepository,
      lobbyRepository: lobbyRepository,
    ),
  );
}

class BrilliantApp extends StatelessWidget {
  final AuthRepository authRepository;
  final LobbyRepository? lobbyRepository;

  const BrilliantApp({
    super.key,
    required this.authRepository,
    this.lobbyRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(authRepository: authRepository),
        ),
        BlocProvider<LobbyBloc>(
          create: (_) => LobbyBloc(
            lobbyRepository: lobbyRepository ?? WebSocketLobbyRepository(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Brilliant Game',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0C0E1A),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF2563EB),
            secondary: Color(0xFF7C3AED),
            surface: Color(0xFF141728),
          ),
          fontFamily: 'Roboto',
        ),
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            if (!authState.isAuthenticated) {
              return const AuthScreen();
            }

            final usuario = authState.usuario!;

            return BlocConsumer<LobbyBloc, LobbyState>(
              listener: (context, lobbyState) {
                if ((lobbyState.status == LobbyStatus.error ||
                        lobbyState.status == LobbyStatus.kicked) &&
                    lobbyState.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF7F1D1D),
                      behavior: SnackBarBehavior.floating,
                      content: Row(
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.circleExclamation,
                            color: Color(0xFFFCA5A5),
                            size: 16,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              lobbyState.errorMessage!,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                  context
                      .read<LobbyBloc>()
                      .add(const LobbyClearErrorRequested());
                }
              },
              builder: (context, lobbyState) {
                if (lobbyState.status == LobbyStatus.connecting ||
                    lobbyState.isInLobby ||
                    lobbyState.isInGame) {
                  return LobbyScreen(usuarioActual: usuario);
                }

                return MainMenuScreen(usuario: usuario);
              },
            );
          },
        ),
      ),
    );
  }
}
