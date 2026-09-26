import 'package:flutter_test/flutter_test.dart';
import 'package:fsm_editor/models/fsm.dart';
import 'package:fsm_editor/models/fsm_state.dart';
import 'package:fsm_editor/models/transition.dart';

void main() {
  test('FSM model should work correctly', () {
    final fsm = FSM(
      id: '1',
      name: 'Test',
      createdAt: DateTime.now(),
    );
    expect(fsm.name, 'Test');
  });

  test('FSMState model should work correctly', () {
    final state = FSMState(
      id: '1',
      fsmId: 'fsm1',
      label: 'A',
      x: 100,
      y: 100,
    );
    expect(state.label, 'A');
  });

  test('Transition model should work correctly', () {
    final transition = Transition(
      id: '1',
      fsmId: 'fsm1',
      fromStateId: 'state1',
      toStateId: 'state2',
      label: 'event',
    );
    expect(transition.label, 'event');
  });
}
