import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/fsm.dart';
import '../models/fsm_state.dart';
import '../models/transition.dart';

class FSMProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  List<FSM> _fsms = [];
  FSM? _currentFSM;
  List<FSMState> _states = [];
  List<Transition> _transitions = [];

  // Undo / Redo history
  final List<Map<String, dynamic>> _undoStack = [];
  final List<Map<String, dynamic>> _redoStack = [];
  static const int _maxHistory = 30;

  List<FSM> get fsms => _fsms;
  FSM? get currentFSM => _currentFSM;
  List<FSMState> get states => _states;
  List<Transition> get transitions => _transitions;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void _pushUndo() {
    _undoStack.add({
      'states': _states.map((s) => s.copyWith()).toList(),
      'transitions': _transitions.map((t) => t.copyWith()).toList(),
    });
    if (_undoStack.length > _maxHistory) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  Future<void> undo() async {
    if (!canUndo || _currentFSM == null) return;
    _redoStack.add({
      'states': _states.map((s) => s.copyWith()).toList(),
      'transitions': _transitions.map((t) => t.copyWith()).toList(),
    });
    final snapshot = _undoStack.removeLast();
    await _restoreSnapshot(snapshot);
  }

  Future<void> redo() async {
    if (!canRedo || _currentFSM == null) return;
    _undoStack.add({
      'states': _states.map((s) => s.copyWith()).toList(),
      'transitions': _transitions.map((t) => t.copyWith()).toList(),
    });
    final snapshot = _redoStack.removeLast();
    await _restoreSnapshot(snapshot);
  }

  Future<void> _restoreSnapshot(Map<String, dynamic> snapshot) async {
    if (_currentFSM == null) return;
    final fsmId = _currentFSM!.id;
    // Clear and restore states & transitions in DB
    final existingStates = await _db.getStatesForFSM(fsmId);
    for (var s in existingStates) {
      await _db.deleteState(s.id);
    }
    final targetStates = snapshot['states'] as List<FSMState>;
    final targetTransitions = snapshot['transitions'] as List<Transition>;
    for (var s in targetStates) {
      await _db.insertState(s);
    }
    for (var t in targetTransitions) {
      await _db.insertTransition(t);
    }
    _states = List.from(targetStates);
    _transitions = List.from(targetTransitions);
    notifyListeners();
  }

  // Load all FSMs
  Future<void> loadFSMs() async {
    _fsms = await _db.getAllFSMs();
    notifyListeners();
  }

  // Create new FSM
  Future<FSM> createFSM(String name, {String machineType = 'mealy'}) async {
    final fsm = FSM(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
      machineType: machineType,
    );
    await _db.insertFSM(fsm);
    await loadFSMs();
    return fsm;
  }

  // Open FSM
  Future<void> openFSM(String id) async {
    _currentFSM = await _db.getFSM(id);
    _undoStack.clear();
    _redoStack.clear();
    if (_currentFSM != null) {
      _states = await _db.getStatesForFSM(id);
      _transitions = await _db.getTransitionsForFSM(id);
    }
    notifyListeners();
  }

  // Update FSM name
  Future<void> updateFSMName(String name) async {
    if (_currentFSM == null) return;
    _currentFSM = _currentFSM!.copyWith(name: name);
    await _db.updateFSM(_currentFSM!);
    await loadFSMs();
  }

  // Update FSM name by ID (for renaming from HomeScreen without opening)
  Future<void> updateFSMNameById(String id, String name) async {
    final fsm = await _db.getFSM(id);
    if (fsm == null) return;
    final updated = fsm.copyWith(name: name);
    await _db.updateFSM(updated);
    if (_currentFSM?.id == id) {
      _currentFSM = updated;
    }
    await loadFSMs();
  }

  // Update FSM machine type
  Future<void> updateMachineType(String machineType) async {
    if (_currentFSM == null) return;
    _currentFSM = _currentFSM!.copyWith(machineType: machineType);
    await _db.updateFSM(_currentFSM!);
    notifyListeners();
  }

  // Delete FSM
  Future<void> deleteFSM(String id) async {
    await _db.deleteFSM(id);
    if (_currentFSM?.id == id) {
      _currentFSM = null;
      _states = [];
      _transitions = [];
    }
    await loadFSMs();
  }

  // Add state
  Future<FSMState> addState(
    double x,
    double y, {
    String? customLabel,
    bool isFinal = false,
    String output = '',
    String? color,
  }) async {
    if (_currentFSM == null) throw Exception('No FSM open');
    _pushUndo();

    final label = (customLabel != null && customLabel.trim().isNotEmpty)
        ? customLabel.trim()
        : await _db.getNextLabel(_currentFSM!.id);
    final isInitial = _states.isEmpty;

    final state = FSMState(
      id: _uuid.v4(),
      fsmId: _currentFSM!.id,
      label: label,
      x: x,
      y: y,
      isInitial: isInitial,
      isFinal: isFinal,
      output: output,
      color: color,
    );

    await _db.insertState(state);
    _states.add(state);
    notifyListeners();
    return state;
  }

  // Update state (recordUndo parameter controls if dragging records undo every frame or not)
  Future<void> updateState(FSMState state, {bool recordUndo = true}) async {
    if (recordUndo) _pushUndo();
    await _db.updateState(state);
    final index = _states.indexWhere((s) => s.id == state.id);
    if (index != -1) {
      _states[index] = state;
    }
    notifyListeners();
  }

  // Update state color
  Future<void> updateStateColor(String stateId, String? color) async {
    final state = getStateById(stateId);
    if (state == null) return;
    _pushUndo();
    final updated = color == null
        ? state.copyWith(clearColor: true)
        : state.copyWith(color: color);
    await _db.updateState(updated);
    final index = _states.indexWhere((s) => s.id == stateId);
    if (index != -1) {
      _states[index] = updated;
    }
    notifyListeners();
  }

  // Record undo before dragging begins
  void recordUndoPoint() {
    _pushUndo();
  }

  // Set initial state
  Future<void> setInitialState(String stateId) async {
    _pushUndo();
    for (var state in _states) {
      if (state.id == stateId) {
        final updated = state.copyWith(isInitial: true);
        await _db.updateState(updated);
      } else if (state.isInitial) {
        final updated = state.copyWith(isInitial: false);
        await _db.updateState(updated);
      }
    }
    _states = await _db.getStatesForFSM(_currentFSM!.id);
    notifyListeners();
  }

  // Delete state
  Future<void> deleteState(String stateId) async {
    _pushUndo();
    await _db.deleteState(stateId);
    _states.removeWhere((s) => s.id == stateId);
    _transitions.removeWhere((t) => t.fromStateId == stateId || t.toStateId == stateId);
    notifyListeners();
  }

  // Add transition (supports self-loops)
  Future<Transition> addTransition(String fromStateId, String toStateId, String label, {String output = ''}) async {
    if (_currentFSM == null) throw Exception('No FSM open');
    _pushUndo();

    final transition = Transition(
      id: _uuid.v4(),
      fsmId: _currentFSM!.id,
      fromStateId: fromStateId,
      toStateId: toStateId,
      label: label,
      output: output,
    );

    await _db.insertTransition(transition);
    _transitions.add(transition);
    notifyListeners();
    return transition;
  }

  // Update transition
  Future<void> updateTransition(Transition transition) async {
    _pushUndo();
    await _db.updateTransition(transition);
    final index = _transitions.indexWhere((t) => t.id == transition.id);
    if (index != -1) {
      _transitions[index] = transition;
    }
    notifyListeners();
  }

  // Delete transition
  Future<void> deleteTransition(String transitionId) async {
    _pushUndo();
    await _db.deleteTransition(transitionId);
    _transitions.removeWhere((t) => t.id == transitionId);
    notifyListeners();
  }

  // Get state by ID
  FSMState? getStateById(String id) {
    try {
      return _states.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  // Check if transition is self-loop
  bool isSelfLoop(Transition transition) {
    return transition.fromStateId == transition.toStateId;
  }
}
