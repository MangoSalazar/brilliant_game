import 'package:test/test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:brilliant_game/features/board/bloc/setup_bloc.dart';
import 'package:brilliant_game/tablero.dart';

void main() {
  group('SetupBloc', () {
    late Tablero tablero;

    setUp(() {
      tablero = Tablero();
    });

    blocTest<SetupBloc, SetupState>(
      'Emite SetupAwaitingInputs al enviar StartSetup',
      build: () => SetupBloc(),
      act: (bloc) => bloc.add(StartSetup(tablero)),
      expect: () => [
        isA<SetupAwaitingInputs>()
            .having((state) => state.casillasRequeridas.length, 'casillasRequeridas.length', 6)
      ],
    );

    blocTest<SetupBloc, SetupState>(
      'No permite valores fuera del rango 1-6',
      build: () => SetupBloc(),
      seed: () {
        final casillas = tablero.generarCasillasIniciales();
        return SetupAwaitingInputs(
          tablero: tablero,
          casillasRequeridas: casillas,
          valoresIngresados: const {},
        );
      },
      act: (bloc) {
        final state = bloc.state as SetupAwaitingInputs;
        bloc.add(InputValue(state.casillasRequeridas.first, 7));
      },
      expect: () => [
        isA<SetupAwaitingInputs>()
            .having((state) => state.errorMessage, 'errorMessage', 'El valor debe estar entre 1 y 6.')
      ],
    );

    blocTest<SetupBloc, SetupState>(
      'No permite valores duplicados',
      build: () => SetupBloc(),
      seed: () {
        final casillas = tablero.generarCasillasIniciales();
        return SetupAwaitingInputs(
          tablero: tablero,
          casillasRequeridas: casillas,
          valoresIngresados: {casillas[0]: 3},
        );
      },
      act: (bloc) {
        final state = bloc.state as SetupAwaitingInputs;
        bloc.add(InputValue(state.casillasRequeridas[1], 3)); // Intenta agregar el mismo valor 3
      },
      expect: () => [
        isA<SetupAwaitingInputs>()
            .having((state) => state.errorMessage, 'errorMessage', 'Los 6 valores iniciales deben ser todos distintos entre sí.')
      ],
    );

    blocTest<SetupBloc, SetupState>(
      'Emite SetupCompleted al llenar correctamente las 6 casillas',
      build: () => SetupBloc(),
      seed: () {
        final casillas = tablero.generarCasillasIniciales();
        return SetupAwaitingInputs(
          tablero: tablero,
          casillasRequeridas: casillas,
          valoresIngresados: {
            casillas[0]: 1,
            casillas[1]: 2,
            casillas[2]: 3,
            casillas[3]: 4,
            casillas[4]: 5,
          },
        );
      },
      act: (bloc) {
        final state = bloc.state as SetupAwaitingInputs;
        bloc.add(InputValue(state.casillasRequeridas[5], 6));
      },
      expect: () => [
        isA<SetupCompleted>()
            .having((state) => state.tablero, 'tablero', tablero)
      ],
    );

    blocTest<SetupBloc, SetupState>(
      'Permite limpiar un valor con ClearValue',
      build: () => SetupBloc(),
      seed: () {
        final casillas = tablero.generarCasillasIniciales();
        return SetupAwaitingInputs(
          tablero: tablero,
          casillasRequeridas: casillas,
          valoresIngresados: {casillas[0]: 4},
        );
      },
      act: (bloc) {
        final state = bloc.state as SetupAwaitingInputs;
        bloc.add(ClearValue(state.casillasRequeridas[0]));
      },
      expect: () => [
        isA<SetupAwaitingInputs>()
            .having((state) => state.valoresIngresados.containsKey(state.casillasRequeridas[0]), 'contiene clave', false)
            .having((state) => state.casillasRequeridas[0].valor, 'valor de casilla', isNull)
      ],
    );

    test('valoresDisponiblesPara devuelve solo los números no usados en otras casillas', () {
      final casillas = tablero.generarCasillasIniciales();
      final state = SetupAwaitingInputs(
        tablero: tablero,
        casillasRequeridas: casillas,
        valoresIngresados: {
          casillas[0]: 1,
          casillas[1]: 3,
          casillas[2]: 5,
        },
      );

      // Para casillas[0], su propio valor (1) y los no usados (2, 4, 6) están disponibles
      expect(state.valoresDisponiblesPara(casillas[0]), [1, 2, 4, 6]);
      // Para una casilla vacía casillas[3], solo los no usados (2, 4, 6) están disponibles
      expect(state.valoresDisponiblesPara(casillas[3]), [2, 4, 6]);
    });
  });
}

