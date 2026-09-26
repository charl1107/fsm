import '../models/fsm.dart';
import '../models/fsm_state.dart';
import '../models/transition.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static final Map<String, Map<String, dynamic>> _fsmStore = {};
  static final Map<String, Map<String, dynamic>> _stateStore = {};
  static final Map<String, Map<String, dynamic>> _transitionStore = {};

  DatabaseHelper._init();

  Future<void> insertFSM(FSM fsm) async {
    _fsmStore[fsm.id] = fsm.toMap();
  }

  Future<List<FSM>> getAllFSMs() async {
    return _fsmStore.values.map((map) => FSM.fromMap(map)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<FSM?> getFSM(String id) async {
    final map = _fsmStore[id];
    if (map == null) return null;
    return FSM.fromMap(map);
  }

  Future<void> updateFSM(FSM fsm) async {
    _fsmStore[fsm.id] = fsm.toMap();
  }

  Future<void> deleteFSM(String id) async {
    _fsmStore.remove(id);
    _stateStore.removeWhere((key, value) => value['fsmId'] == id);
    _transitionStore.removeWhere((key, value) => value['fsmId'] == id);
  }

  Future<void> insertState(FSMState state) async {
    _stateStore[state.id] = state.toMap();
  }

  Future<List<FSMState>> getStatesForFSM(String fsmId) async {
    return _stateStore.values
        .where((map) => map['fsmId'] == fsmId)
        .map((map) => FSMState.fromMap(map))
        .toList();
  }

  Future<void> updateState(FSMState state) async {
    _stateStore[state.id] = state.toMap();
  }

  Future<void> deleteState(String id) async {
    _stateStore.remove(id);
    _transitionStore.removeWhere((key, value) =>
        value['fromStateId'] == id || value['toStateId'] == id);
  }

  Future<void> insertTransition(Transition transition) async {
    _transitionStore[transition.id] = transition.toMap();
  }

  Future<List<Transition>> getTransitionsForFSM(String fsmId) async {
    return _transitionStore.values
        .where((map) => map['fsmId'] == fsmId)
        .map((map) => Transition.fromMap(map))
        .toList();
  }

  Future<void> updateTransition(Transition transition) async {
    _transitionStore[transition.id] = transition.toMap();
  }

  Future<void> deleteTransition(String id) async {
    _transitionStore.remove(id);
  }

  Future<String> getNextLabel(String fsmId) async {
    final states = await getStatesForFSM(fsmId);
    if (states.isEmpty) return 'A';
    final labels = states.map((s) => s.label).toSet();
    int index = 0;
    while (labels.contains(_indexToLabel(index))) {
      index++;
    }
    return _indexToLabel(index);
  }

  String _indexToLabel(int index) {
    String label = '';
    int n = index;
    while (n >= 0) {
      label = String.fromCharCode(65 + (n % 26)) + label;
      n = (n ~/ 26) - 1;
    }
    return label;
  }
}
