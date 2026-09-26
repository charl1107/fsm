import '../models/fsm.dart';
import '../models/fsm_state.dart';
import '../models/transition.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  Future<void> insertFSM(FSM fsm) async => throw UnsupportedError('Unsupported platform');
  Future<List<FSM>> getAllFSMs() async => throw UnsupportedError('Unsupported platform');
  Future<FSM?> getFSM(String id) async => throw UnsupportedError('Unsupported platform');
  Future<void> updateFSM(FSM fsm) async => throw UnsupportedError('Unsupported platform');
  Future<void> deleteFSM(String id) async => throw UnsupportedError('Unsupported platform');
  Future<void> insertState(FSMState state) async => throw UnsupportedError('Unsupported platform');
  Future<List<FSMState>> getStatesForFSM(String fsmId) async => throw UnsupportedError('Unsupported platform');
  Future<void> updateState(FSMState state) async => throw UnsupportedError('Unsupported platform');
  Future<void> deleteState(String id) async => throw UnsupportedError('Unsupported platform');
  Future<void> insertTransition(Transition transition) async => throw UnsupportedError('Unsupported platform');
  Future<List<Transition>> getTransitionsForFSM(String fsmId) async => throw UnsupportedError('Unsupported platform');
  Future<void> updateTransition(Transition transition) async => throw UnsupportedError('Unsupported platform');
  Future<void> deleteTransition(String id) async => throw UnsupportedError('Unsupported platform');
  Future<String> getNextLabel(String fsmId) async => throw UnsupportedError('Unsupported platform');
}
