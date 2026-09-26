import 'dart:collection';
import '../models/fsm_state.dart';
import '../models/transition.dart';

class NFADFAConverter {
  static const String epsilon = 'ε';

  static Map<String, dynamic> convertNFAToDFA({
    required List<FSMState> nfaStates,
    required List<Transition> nfaTransitions,
    required String fsmId,
  }) {
    final startState = nfaStates.firstWhere((s) => s.isInitial);
    final finalStateIds = nfaStates.where((s) => s.isFinal).map((s) => s.id).toSet();

    final allInputs = nfaTransitions
        .where((t) => t.label != epsilon)
        .map((t) => t.label)
        .toSet()
        .toList()
      ..sort();

    final epsilonClosures = <String, Set<String>>{};
    for (var state in nfaStates) {
      epsilonClosures[state.id] = computeEpsilonClosure(state.id, nfaStates, nfaTransitions);
    }

    final dfaStates = <Set<String>>[];
    final dfaTransitionsList = <Map<String, Set<String>>>[];
    final visited = <Set<String>>{};
    final queue = Queue<Set<String>>();

    final startClosure = epsilonClosures[startState.id]!;
    queue.add(startClosure);
    dfaStates.add(startClosure);

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (visited.contains(current)) continue;
      visited.add(current);

      final transitionMap = <String, Set<String>>{};
      for (var input in allInputs) {
        final nextState = move(current, input, nfaStates, nfaTransitions);
        if (nextState.isNotEmpty) {
          final closure = <String>{};
          for (var s in nextState) {
            closure.addAll(epsilonClosures[s] ?? {});
          }
          transitionMap[input] = closure;

          if (!visited.contains(closure) && !queue.contains(closure)) {
            queue.add(closure);
            dfaStates.add(closure);
          }
        }
      }
      dfaTransitionsList.add(transitionMap);
    }

    final dfaFinalStates = <int>[];
    for (int i = 0; i < dfaStates.length; i++) {
      if (dfaStates[i].any((s) => finalStateIds.contains(s))) {
        dfaFinalStates.add(i);
      }
    }

    final resultStates = <FSMState>[];
    final resultTransitions = <Transition>[];

    final labelMap = <int, String>{};
    for (int i = 0; i < dfaStates.length; i++) {
      labelMap[i] = String.fromCharCode(65 + i);
    }

    final spacing = 150.0;
    final startX = 100.0;
    final startY = 150.0;

    for (int i = 0; i < dfaStates.length; i++) {
      final isInitial = i == 0;
      final isFinal = dfaFinalStates.contains(i);

      final stateLabel = dfaStates[i]
          .map((id) => nfaStates.firstWhere((s) => s.id == id).label)
          .join(',');

      resultStates.add(FSMState(
        id: 'dfa_state_$i',
        fsmId: fsmId,
        label: labelMap[i]!,
        x: startX + (i % 4) * spacing,
        y: startY + (i ~/ 4) * 120.0,
        isInitial: isInitial,
        isFinal: isFinal,
        output: '{$stateLabel}',
      ));
    }

    for (int i = 0; i < dfaTransitionsList.length; i++) {
      final transitionMap = dfaTransitionsList[i];
      for (var entry in transitionMap.entries) {
        final targetIndex = dfaStates.indexOf(entry.value);
        if (targetIndex != -1) {
          resultTransitions.add(Transition(
            id: 'dfa_trans_${i}_${entry.key}',
            fsmId: fsmId,
            fromStateId: 'dfa_state_$i',
            toStateId: 'dfa_state_$targetIndex',
            label: entry.key,
          ));
        }
      }
    }

    return {
      'states': resultStates,
      'transitions': resultTransitions,
      'labelMap': labelMap,
      'dfaStates': dfaStates,
      'dfaFinalStates': dfaFinalStates,
    };
  }

  static Set<String> computeEpsilonClosure(
    String stateId,
    List<FSMState> states,
    List<Transition> transitions,
  ) {
    final closure = <String>{stateId};
    final stack = [stateId];

    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      final epsilonTransitions = transitions
          .where((t) => t.fromStateId == current && t.label == epsilon);

      for (var t in epsilonTransitions) {
        if (!closure.contains(t.toStateId)) {
          closure.add(t.toStateId);
          stack.add(t.toStateId);
        }
      }
    }

    return closure;
  }

  static Set<String> move(
    Set<String> states,
    String input,
    List<FSMState> allStates,
    List<Transition> transitions,
  ) {
    final result = <String>{};
    for (var stateId in states) {
      final nextStates = transitions
          .where((t) => t.fromStateId == stateId && t.label == input)
          .map((t) => t.toStateId);
      result.addAll(nextStates);
    }
    return result;
  }

  static bool validateDFA({
    required List<FSMState> states,
    required List<Transition> transitions,
  }) {
    final startStates = states.where((s) => s.isInitial).toList();
    if (startStates.length != 1) return false;

    final inputs = transitions.map((t) => t.label).toSet();
    for (var state in states) {
      for (var input in inputs) {
        final count = transitions
            .where((t) => t.fromStateId == state.id && t.label == input)
            .length;
        if (count > 1) return false;
      }
    }

    for (var t in transitions) {
      if (t.label == epsilon) return false;
    }

    return true;
  }

  static String formatConversionResult({
    required List<FSMState> nfaStates,
    required List<Transition> nfaTransitions,
    required Map<String, dynamic> result,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('=== NFA to DFA Conversion ===\n');

    buffer.writeln('NFA States: ${nfaStates.map((s) => s.label).join(', ')}');
    buffer.writeln('NFA Transitions:');
    for (var t in nfaTransitions) {
      final from = nfaStates.firstWhere((s) => s.id == t.fromStateId).label;
      final to = nfaStates.firstWhere((s) => s.id == t.toStateId).label;
      buffer.writeln('  δ($from, ${t.label}) = $to');
    }

    buffer.writeln('\n--- Subset Construction ---\n');

    final dfaStates = result['dfaStates'] as List<Set<String>>;
    final labelMap = result['labelMap'] as Map<int, String>;
    final dfaFinalStates = result['dfaFinalStates'] as List<int>;

    buffer.writeln('DFA States:');
    for (int i = 0; i < dfaStates.length; i++) {
      final stateLabels = dfaStates[i]
          .map((id) => nfaStates.firstWhere((s) => s.id == id).label)
          .join(',');
      final marker = dfaFinalStates.contains(i) ? ' (final)' : '';
      buffer.writeln('  ${labelMap[i]} = {$stateLabels}$marker');
    }

    buffer.writeln('\nDFA Transitions:');
    final dfaTransitions = result['transitions'] as List<Transition>;
    for (var t in dfaTransitions) {
      final fromLabel = labelMap[int.parse(t.fromStateId.split('_').last)] ?? '?';
      final toLabel = labelMap[int.parse(t.toStateId.split('_').last)] ?? '?';
      buffer.writeln('  δ($fromLabel, ${t.label}) = $toLabel');
    }

    return buffer.toString();
  }
}
