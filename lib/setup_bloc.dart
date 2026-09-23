import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'tablero.dart';

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

// --- Bloc ---
class SetupBloc extends Bloc<SetupEvent, SetupState> {
  SetupBloc() : super(SetupInitial()) {
    on<StartSetup>(_onStartSetup);
    on<InputValue>(_onInputValue);
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
}
