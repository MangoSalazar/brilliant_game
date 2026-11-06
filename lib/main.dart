import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_state.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'features/auth/ui/auth_screen.dart';
import 'features/menu/ui/main_menu_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final authRepository = LocalAuthRepository();

  runApp(BrilliantApp(authRepository: authRepository));
}

class BrilliantApp extends StatelessWidget {
  final AuthRepository authRepository;

  const BrilliantApp({
    super.key,
    required this.authRepository,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc(authRepository: authRepository),
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
          builder: (context, state) {
            if (state.isAuthenticated) {
              return MainMenuScreen(usuario: state.usuario!);
            }
            return const AuthScreen();
          },
        ),
      ),
    );
  }
}
