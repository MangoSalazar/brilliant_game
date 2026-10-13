import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../tablero.dart';

// --- Estados ---
abstract class SetupState extends Equatable {
  const SetupState();
  
  @override
  List<Object?> get props => [];
}

class SetupInitial extends SetupState {}

class SetupAwaitingInputs extends SetupState {
  final Tablero tablero;
  final List<Casilla> casillasRequeridas;
  final Map<Casilla, int> valoresIngresados;
  final String? errorMessage;

  const SetupAwaitingInputs({
    required this.tablero,
    required this.casillasRequeridas,
    required this.valoresIngresados,
    this.errorMessage,
  });

  List<int> valoresDisponiblesPara(Casilla casilla) {
    final valoresUsadosPorOtras = valoresIngresados.entries
        .where((entry) => entry.key != casilla)
        .map((entry) => entry.value)
        .toSet();
    return [1, 2, 3, 4, 5, 6]
        .where((n) => !valoresUsadosPorOtras.contains(n))
        .toList();
  }

  @override
  List<Object?> get props => [tablero, casillasRequeridas, valoresIngresados, errorMessage];
}

class SetupCompleted extends SetupState {
  final Tablero tablero;

  const SetupCompleted({required this.tablero});

  @override
  List<Object?> get props => [tablero];
}

// --- Eventos ---
abstract class SetupEvent extends Equatable {
  const SetupEvent();

  @override
  List<Object?> get props => [];
}

class StartSetup extends SetupEvent {
  final Tablero tablero;
  const StartSetup(this.tablero);

  @override
  List<Object?> get props => [tablero];
}

class InputValue extends SetupEvent {
  final Casilla casilla;
  final int value;
  const InputValue(this.casilla, this.value);

  @override
  List<Object?> get props => [casilla, value];
}

class ClearValue extends SetupEvent {
  final Casilla casilla;
  const ClearValue(this.casilla);

  @override
  List<Object?> get props => [casilla];
}

// --- Bloc ---
class SetupBloc extends Bloc<SetupEvent, SetupState> {
  SetupBloc() : super(SetupInitial()) {
    on<StartSetup>(_onStartSetup);
    on<InputValue>(_onInputValue);
    on<ClearValue>(_onClearValue);
  }

  void _onStartSetup(StartSetup event, Emitter<SetupState> emit) {
    final casillas = event.tablero.generarCasillasIniciales();
    emit(SetupAwaitingInputs(
      tablero: event.tablero,
      casillasRequeridas: casillas,
      valoresIngresados: const {},
    ));
  }

  void _onInputValue(InputValue event, Emitter<SetupState> emit) {
    if (state is! SetupAwaitingInputs) return;
    final currentState = state as SetupAwaitingInputs;

    if (!currentState.casillasRequeridas.contains(event.casilla)) {
      emit(SetupAwaitingInputs(
        tablero: currentState.tablero,
        casillasRequeridas: currentState.casillasRequeridas,
        valoresIngresados: currentState.valoresIngresados,
        errorMessage: 'Esta casilla no es una de las 6 requeridas al inicio.',
      ));
      return;
    }

    if (event.value < 1 || event.value > 6) {
      emit(SetupAwaitingInputs(
        tablero: currentState.tablero,
        casillasRequeridas: currentState.casillasRequeridas,
        valoresIngresados: currentState.valoresIngresados,
        errorMessage: 'El valor debe estar entre 1 y 6.',
      ));
      return;
    }

    final newInputs = Map<Casilla, int>.from(currentState.valoresIngresados);
    newInputs[event.casilla] = event.value;

    final valuesList = newInputs.values.toList();
    if (valuesList.toSet().length != valuesList.length) {
      emit(SetupAwaitingInputs(
        tablero: currentState.tablero,
        casillasRequeridas: currentState.casillasRequeridas,
        valoresIngresados: currentState.valoresIngresados, // no guardamos el repetido
        errorMessage: 'Los 6 valores iniciales deben ser todos distintos entre sí.',
      ));
      return;
    }

    event.casilla.valor = event.value;

    if (newInputs.length == 6) {
      emit(SetupCompleted(tablero: currentState.tablero));
    } else {
      emit(SetupAwaitingInputs(
        tablero: currentState.tablero,
        casillasRequeridas: currentState.casillasRequeridas,
        valoresIngresados: newInputs,
        errorMessage: null,
      ));
    }
  }

  void _onClearValue(ClearValue event, Emitter<SetupState> emit) {
    if (state is! SetupAwaitingInputs && state is! SetupCompleted) return;

    final Tablero tablero;
    final List<Casilla> casillasRequeridas;
    final Map<Casilla, int> valoresIngresados;

    if (state is SetupAwaitingInputs) {
      final s = state as SetupAwaitingInputs;
      tablero = s.tablero;
      casillasRequeridas = s.casillasRequeridas;
      valoresIngresados = Map<Casilla, int>.from(s.valoresIngresados);
    } else {
      final s = state as SetupCompleted;
      tablero = s.tablero;
      casillasRequeridas = s.tablero.celdas
          .expand((row) => row)
          .where((c) => c.valor != null)
          .toList();
      valoresIngresados = {for (var c in casillasRequeridas) c: c.valor!};
    }

    valoresIngresados.remove(event.casilla);
    event.casilla.valor = null;

    emit(SetupAwaitingInputs(
      tablero: tablero,
      casillasRequeridas: casillasRequeridas,
      valoresIngresados: valoresIngresados,
      errorMessage: null,
    ));
  }
}
