import 'package:flutter_test/flutter_test.dart';
import 'package:fsm_editor/models/fsm.dart';
import 'package:fsm_editor/models/fsm_state.dart';
import 'package:fsm_editor/models/transition.dart';

void main() {
  group('FSM Model', () {
    test('should create FSM with required fields', () {
      final fsm = FSM(
        id: '1',
        name: 'Test FSM',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(fsm.id, '1');
      expect(fsm.name, 'Test FSM');
      expect(fsm.createdAt, DateTime(2024, 1, 1));
    });

    test('should convert to map correctly', () {
      final fsm = FSM(
        id: '1',
        name: 'Test FSM',
        createdAt: DateTime(2024, 1, 1),
      );

      final map = fsm.toMap();
      expect(map['id'], '1');
      expect(map['name'], 'Test FSM');
      expect(map['createdAt'], DateTime(2024, 1, 1).millisecondsSinceEpoch);
    });

    test('should create from map correctly', () {
      final map = {
        'id': '1',
        'name': 'Test FSM',
        'createdAt': DateTime(2024, 1, 1).millisecondsSinceEpoch,
      };

      final fsm = FSM.fromMap(map);
      expect(fsm.id, '1');
      expect(fsm.name, 'Test FSM');
      expect(fsm.createdAt, DateTime(2024, 1, 1));
    });

    test('should copy with new name', () {
      final fsm = FSM(
        id: '1',
        name: 'Old Name',
        createdAt: DateTime(2024, 1, 1),
      );

      final updated = fsm.copyWith(name: 'New Name');
      expect(updated.name, 'New Name');
      expect(updated.id, fsm.id);
      expect(updated.createdAt, fsm.createdAt);
    });
  });

  group('FSMState Model', () {
    test('should create state with default values', () {
      final state = FSMState(
        id: '1',
        fsmId: 'fsm1',
        label: 'A',
        x: 100.0,
        y: 200.0,
      );

      expect(state.isInitial, false);
      expect(state.isFinal, false);
    });

    test('should create initial state', () {
      final state = FSMState(
        id: '1',
        fsmId: 'fsm1',
        label: 'A',
        x: 100.0,
        y: 200.0,
        isInitial: true,
      );

      expect(state.isInitial, true);
    });

    test('should create final state', () {
      final state = FSMState(
        id: '1',
        fsmId: 'fsm1',
        label: 'A',
        x: 100.0,
        y: 200.0,
        isFinal: true,
      );

      expect(state.isFinal, true);
    });

    test('should convert to map correctly', () {
      final state = FSMState(
        id: '1',
        fsmId: 'fsm1',
        label: 'A',
        x: 100.0,
        y: 200.0,
        isInitial: true,
        isFinal: false,
      );

      final map = state.toMap();
      expect(map['isInitial'], 1);
      expect(map['isFinal'], 0);
    });

    test('should create from map correctly', () {
      final map = {
        'id': '1',
        'fsmId': 'fsm1',
        'label': 'A',
        'x': 100.0,
        'y': 200.0,
        'isInitial': 1,
        'isFinal': 0,
      };

      final state = FSMState.fromMap(map);
      expect(state.isInitial, true);
      expect(state.isFinal, false);
    });

    test('should create from map with boolean flags correctly', () {
      final map = {
        'id': '2',
        'fsmId': 'fsm1',
        'label': 'B',
        'x': 150.0,
        'y': 250.0,
        'isInitial': true,
        'isFinal': true,
      };

      final state = FSMState.fromMap(map);
      expect(state.isInitial, true);
      expect(state.isFinal, true);
    });

    test('should copy with new values', () {
      final state = FSMState(
        id: '1',
        fsmId: 'fsm1',
        label: 'A',
        x: 100.0,
        y: 200.0,
      );

      final updated = state.copyWith(
        label: 'B',
        x: 150.0,
        isFinal: true,
      );

      expect(updated.label, 'B');
      expect(updated.x, 150.0);
      expect(updated.isFinal, true);
      expect(updated.id, state.id);
    });
  });

  group('Transition Model', () {
    test('should create transition with required fields', () {
      final transition = Transition(
        id: '1',
        fsmId: 'fsm1',
        fromStateId: 'state1',
        toStateId: 'state2',
        label: 'event1',
      );

      expect(transition.id, '1');
      expect(transition.fromStateId, 'state1');
      expect(transition.toStateId, 'state2');
      expect(transition.label, 'event1');
    });

    test('should convert to map correctly', () {
      final transition = Transition(
        id: '1',
        fsmId: 'fsm1',
        fromStateId: 'state1',
        toStateId: 'state2',
        label: 'event1',
      );

      final map = transition.toMap();
      expect(map['id'], '1');
      expect(map['fromStateId'], 'state1');
      expect(map['toStateId'], 'state2');
      expect(map['label'], 'event1');
    });

    test('should create from map correctly', () {
      final map = {
        'id': '1',
        'fsmId': 'fsm1',
        'fromStateId': 'state1',
        'toStateId': 'state2',
        'label': 'event1',
      };

      final transition = Transition.fromMap(map);
      expect(transition.id, '1');
      expect(transition.fromStateId, 'state1');
      expect(transition.toStateId, 'state2');
      expect(transition.label, 'event1');
    });

    test('should copy with new values', () {
      final transition = Transition(
        id: '1',
        fsmId: 'fsm1',
        fromStateId: 'state1',
        toStateId: 'state2',
        label: 'event1',
      );

      final updated = transition.copyWith(
        label: 'event2',
        fromStateId: 'state3',
      );

      expect(updated.label, 'event2');
      expect(updated.fromStateId, 'state3');
      expect(updated.toStateId, 'state2');
      expect(updated.id, transition.id);
    });
  });
}
