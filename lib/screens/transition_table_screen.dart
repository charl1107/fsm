import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fsm_provider.dart';
import '../models/fsm.dart';
import '../models/fsm_state.dart';
import '../models/transition.dart';

class TransitionTableScreen extends StatelessWidget {
  const TransitionTableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transition Table'), centerTitle: true),
      body: Consumer<FSMProvider>(
        builder: (context, provider, child) {
          final fsm = provider.currentFSM;
          if (fsm == null || provider.states.isEmpty) {
            return const Center(child: Text('No states to display'));
          }

          final isMealy = fsm.machineType == 'mealy';
          final states = provider.states;
          final transitions = provider.transitions;
          final inputs = transitions.map((t) => t.label).toSet().toList()..sort();

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fsm.isNFA
                                  ? 'NFA (Non-deterministic Finite Automaton)'
                                  : fsm.isDFA
                                      ? 'DFA (Deterministic Finite Automaton)'
                                      : isMealy
                                          ? 'Mealy Machine'
                                          : 'Moore Machine',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              fsm.isNFA
                                  ? 'Supports ε-transitions and multiple next states'
                                  : fsm.isDFA
                                      ? 'Deterministic state transitions'
                                      : isMealy
                                          ? 'Outputs on transitions (input/output)'
                                          : 'Outputs on states',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTable(context, fsm, states, transitions, inputs, provider),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTable(
    BuildContext context,
    FSM fsm,
    List<FSMState> states,
    List<Transition> transitions,
    List<String> inputs,
    FSMProvider provider,
  ) {
    final isMealy = fsm.machineType == 'mealy';
    final isMoore = fsm.machineType == 'moore';
    final isNFA = fsm.machineType == 'nfa';

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            const DataColumn(
              label: Text('Present State', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            for (final input in inputs)
              DataColumn(
                label: Text(
                  inputs.length <= 4 ? 'Next State for Input $input' : input,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            if (isMoore)
              const DataColumn(
                label: Text('Output', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
          ],
          rows: states.map((state) {
            return DataRow(cells: [
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.isInitial)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.arrow_right_alt, size: 20, color: Colors.blue),
                    ),
                  Text(
                    state.label,
                    style: TextStyle(
                      fontWeight: state.isInitial ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (state.isFinal)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Text(' (Final)', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                    ),
                ],
              )),
              for (final input in inputs)
                DataCell(_buildCell(state, input, transitions, isMealy, isNFA, provider)),
              if (isMoore)
                DataCell(Text(state.output.isNotEmpty ? state.output : '-')),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCell(
    FSMState state,
    String input,
    List<Transition> transitions,
    bool isMealy,
    bool isNFA,
    FSMProvider provider,
  ) {
    final matching = transitions
        .where((t) => t.fromStateId == state.id && t.label == input)
        .toList();
    if (matching.isEmpty) return const Text('—');

    if (isNFA) {
      // For NFA: can have multiple next states, represented as set {q1, q2}
      final targetLabels = matching.map((t) {
        final targetState = provider.getStateById(t.toStateId);
        return targetState?.label ?? '?';
      }).toSet().toList()..sort();

      if (targetLabels.length == 1) {
        return Text(targetLabels.first);
      }
      return Text('{${targetLabels.join(', ')}}');
    }

    final t = matching.first;
    final targetState = provider.getStateById(t.toStateId);
    final targetLabel = targetState?.label ?? '?';

    if (isMealy) {
      final out = t.output.isNotEmpty ? t.output : '-';
      return Text('$targetLabel / $out');
    }
    return Text(targetLabel);
  }
}
