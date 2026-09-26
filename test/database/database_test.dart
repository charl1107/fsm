import 'package:flutter_test/flutter_test.dart';
import 'package:fsm_editor/models/fsm.dart';
import 'package:fsm_editor/models/fsm_state.dart';
import 'package:fsm_editor/models/transition.dart';

void main() {
  group('Database Operations Simulation', () {
    late List<FSM> fsms;
    late List<FSMState> states;
    late List<Transition> transitions;

    setUp(() {
      fsms = [];
      states = [];
      transitions = [];
    });

    test('should add FSM to collection', () {
      final fsm = FSM(
        id: '1',
        name: 'Test FSM',
        createdAt: DateTime.now(),
      );

      fsms.add(fsm);
      expect(fsms.length, 1);
      expect(fsms.first.name, 'Test FSM');
    });

    test('should update FSM name', () {
      final fsm = FSM(
        id: '1',
        name: 'Old Name',
        createdAt: DateTime.now(),
      );

      fsms.add(fsm);
      final index = fsms.indexWhere((f) => f.id == fsm.id);
      fsms[index] = fsm.copyWith(name: 'New Name');

      expect(fsms.first.name, 'New Name');
    });

    test('should remove FSM and related data', () {
      final fsm = FSM(
        id: 'fsm1',
        name: 'Test FSM',
        createdAt: DateTime.now(),
      );

      final state1 = FSMState(
        id: 'state1',
        fsmId: 'fsm1',
        label: 'A',
        x: 100,
        y: 100,
      );

      final state2 = FSMState(
        id: 'state2',
        fsmId: 'fsm1',
        label: 'B',
        x: 200,
        y: 200,
      );

      final transition = Transition(
        id: 'trans1',
        fsmId: 'fsm1',
        fromStateId: 'state1',
        toStateId: 'state2',
        label: 'event1',
      );

      fsms.add(fsm);
      states.addAll([state1, state2]);
      transitions.add(transition);

      // Remove FSM
      fsms.removeWhere((f) => f.id == fsm.id);
      transitions.removeWhere((t) => t.fsmId == fsm.id);
      states.removeWhere((s) => s.fsmId == fsm.id);

      expect(fsms.length, 0);
      expect(states.length, 0);
      expect(transitions.length, 0);
    });

    test('should add state to FSM', () {
      final state = FSMState(
        id: 'state1',
        fsmId: 'fsm1',
        label: 'A',
        x: 100,
        y: 100,
      );

      states.add(state);
      expect(states.length, 1);
      expect(states.first.label, 'A');
    });

    test('should update state properties', () {
      final state = FSMState(
        id: 'state1',
        fsmId: 'fsm1',
        label: 'A',
        x: 100,
        y: 100,
      );

      states.add(state);
      final index = states.indexWhere((s) => s.id == state.id);
      states[index] = state.copyWith(isInitial: true, label: 'B');

      expect(states.first.isInitial, true);
      expect(states.first.label, 'B');
    });

    test('should remove state and related transitions', () {
      final state1 = FSMState(
        id: 'state1',
        fsmId: 'fsm1',
        label: 'A',
        x: 100,
        y: 100,
      );

      final state2 = FSMState(
        id: 'state2',
        fsmId: 'fsm1',
        label: 'B',
        x: 200,
        y: 200,
      );

      final state3 = FSMState(
        id: 'state3',
        fsmId: 'fsm1',
        label: 'C',
        x: 300,
        y: 300,
      );

      final transition1 = Transition(
        id: 'trans1',
        fsmId: 'fsm1',
        fromStateId: 'state1',
        toStateId: 'state2',
        label: 'event1',
      );

      final transition2 = Transition(
        id: 'trans2',
        fsmId: 'fsm1',
        fromStateId: 'state2',
        toStateId: 'state3',
        label: 'event2',
      );

      states.addAll([state1, state2, state3]);
      transitions.addAll([transition1, transition2]);

      // Remove state1 - should remove transition1 (fromState), keep transition2
      states.removeWhere((s) => s.id == state1.id);
      transitions.removeWhere((t) => t.fromStateId == state1.id || t.toStateId == state1.id);

      expect(states.length, 2);
      expect(transitions.length, 1);
      expect(transitions.first.fromStateId, 'state2');
      expect(transitions.first.toStateId, 'state3');
    });

    test('should add transition between states', () {
      final transition = Transition(
        id: 'trans1',
        fsmId: 'fsm1',
        fromStateId: 'state1',
        toStateId: 'state2',
        label: 'event1',
      );

      transitions.add(transition);
      expect(transitions.length, 1);
      expect(transitions.first.label, 'event1');
    });

    test('should update transition label', () {
      final transition = Transition(
        id: 'trans1',
        fsmId: 'fsm1',
        fromStateId: 'state1',
        toStateId: 'state2',
        label: 'old_event',
      );

      transitions.add(transition);
      final index = transitions.indexWhere((t) => t.id == transition.id);
      transitions[index] = transition.copyWith(label: 'new_event');

      expect(transitions.first.label, 'new_event');
    });

    test('should get next label correctly', () {
      final existingStates = ['A', 'B', 'C'];
      String nextLabel = 'A';
      while (existingStates.contains(nextLabel)) {
        nextLabel = String.fromCharCode(nextLabel.codeUnitAt(0) + 1);
      }

      expect(nextLabel, 'D');
    });

    test('should get states for FSM', () {
      final state1 = FSMState(
        id: 'state1',
        fsmId: 'fsm1',
        label: 'A',
        x: 100,
        y: 100,
      );

      final state2 = FSMState(
        id: 'state2',
        fsmId: 'fsm2',
        label: 'B',
        x: 200,
        y: 200,
      );

      states.addAll([state1, state2]);

      final fsm1States = states.where((s) => s.fsmId == 'fsm1').toList();
      expect(fsm1States.length, 1);
      expect(fsm1States.first.id, 'state1');
    });

    test('should get transitions for FSM', () {
      final transition1 = Transition(
        id: 'trans1',
        fsmId: 'fsm1',
        fromStateId: 'state1',
        toStateId: 'state2',
        label: 'event1',
      );

      final transition2 = Transition(
        id: 'trans2',
        fsmId: 'fsm2',
        fromStateId: 'state3',
        toStateId: 'state4',
        label: 'event2',
      );

      transitions.addAll([transition1, transition2]);

      final fsm1Transitions = transitions.where((t) => t.fsmId == 'fsm1').toList();
      expect(fsm1Transitions.length, 1);
      expect(fsm1Transitions.first.id, 'trans1');
    });
  });
}
