import 'package:flutter/material.dart';
import '../models/fsm.dart';
import '../models/fsm_state.dart';
import '../models/transition.dart';
import '../providers/fsm_provider.dart';
import 'state_node.dart';
import 'transition_line.dart';

class FSMExportSheet extends StatelessWidget {
  final FSM fsm;
  final List<FSMState> states;
  final List<Transition> transitions;
  final FSMProvider provider;

  const FSMExportSheet({
    super.key,
    required this.fsm,
    required this.states,
    required this.transitions,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header
          _buildHeader(context),
          const Divider(height: 32, thickness: 1.5),

          // 2. Formal Definition (5-Tuple or 6-Tuple)
          _buildTupleCard(context),
          const SizedBox(height: 20),

          // 3. Diagram Canvas
          _buildDiagramSection(context),
          const SizedBox(height: 20),

          // 4. Transition Table
          _buildTableSection(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final typeLabel = fsm.isNFA
        ? 'NFA (Non-deterministic Finite Automaton)'
        : fsm.isDFA
            ? 'DFA (Deterministic Finite Automaton)'
            : fsm.isMealy
                ? 'Mealy Machine'
                : 'Moore Machine';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fsm.name.isNotEmpty ? fsm.name : 'Finite State Machine',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                typeLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'States: ${states.length}  |  Transitions: ${transitions.length}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTupleCard(BuildContext context) {
    final isMealy = fsm.isMealy;
    final isMoore = fsm.isMoore;
    final is6Tuple = isMealy || isMoore;

    final qStates = states.map((s) => s.label).toList()..sort();
    final sigmaInputs = transitions.map((t) => t.label).toSet().toList()..sort();

    final initialStates = states.where((s) => s.isInitial).map((s) => s.label).toList();
    final q0 = initialStates.isNotEmpty ? initialStates.first : (qStates.isNotEmpty ? qStates.first : 'q0');

    final finalStates = states.where((s) => s.isFinal).map((s) => s.label).toList()..sort();

    final outputs = isMealy
        ? (transitions.map((t) => t.output).where((o) => o.isNotEmpty).toSet().toList()..sort())
        : (states.map((s) => s.output).where((o) => o.isNotEmpty).toSet().toList()..sort());

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            is6Tuple ? 'Formal Definition (6-Tuple)' : 'Formal Definition (5-Tuple)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            is6Tuple ? 'M = (Q, Σ, Δ, δ, λ, q₀)' : 'M = (Q, Σ, δ, q₀, F)',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo),
          ),
          const SizedBox(height: 10),
          _tupleRow('Q (States)', '{ ${qStates.join(', ')} }'),
          _tupleRow('Σ (Alphabet/Inputs)', '{ ${sigmaInputs.join(', ')} }'),
          if (is6Tuple)
            _tupleRow('Δ (Output Alphabet)', outputs.isNotEmpty ? '{ ${outputs.join(', ')} }' : '{ }'),
          _tupleRow('q₀ (Initial State)', q0),
          if (!is6Tuple)
            _tupleRow('F (Final/Accepting States)', finalStates.isNotEmpty ? '{ ${finalStates.join(', ')} }' : 'Ø'),
          if (isMealy)
            _tupleRow('λ (Output Function)', 'Transition output: λ(q, a) ∈ Δ'),
          if (isMoore)
            _tupleRow('λ (Output Function)', 'State output: λ(q) ∈ Δ'),
          _tupleRow('δ (Transition Function)', fsm.isNFA ? 'δ: Q × (Σ ∪ {ε}) → P(Q)' : 'δ: Q × Σ → Q'),
        ],
      ),
    );
  }

  Widget _tupleRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              title,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12.5, fontFamily: 'monospace', color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagramSection(BuildContext context) {
    if (states.isEmpty) {
      return const SizedBox.shrink();
    }

    // Compute bounding box of states
    double minX = states.first.x;
    double maxX = states.first.x;
    double minY = states.first.y;
    double maxY = states.first.y;

    for (var s in states) {
      if (s.x < minX) minX = s.x;
      if (s.x > maxX) maxX = s.x;
      if (s.y < minY) minY = s.y;
      if (s.y > maxY) maxY = s.y;
    }

    final double width = (maxX - minX + 160).clamp(400.0, 1000.0);
    final double height = (maxY - minY + 160).clamp(240.0, 700.0);
    final double offsetX = 80 - minX;
    final double offsetY = 80 - minY;

    final isMealy = fsm.isMealy;
    final isMoore = fsm.isMoore;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('State Diagram', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Center(
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                children: [
                  for (var t in transitions)
                    if (provider.getStateById(t.fromStateId) != null &&
                        provider.getStateById(t.toStateId) != null)
                      _buildOffsetTransition(t, offsetX, offsetY, isMealy, isMoore),
                  for (var state in states)
                    Positioned(
                      left: state.x + offsetX - 40,
                      top: state.y + offsetY - 40,
                      child: StateNode(state: state, showOutput: isMoore),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOffsetTransition(
    Transition t,
    double offsetX,
    double offsetY,
    bool isMealy,
    bool isMoore,
  ) {
    final fromState = provider.getStateById(t.fromStateId)!;
    final toState = provider.getStateById(t.toStateId)!;

    final shiftedFrom = fromState.copyWith(
      x: fromState.x + offsetX,
      y: fromState.y + offsetY,
    );
    final shiftedTo = toState.copyWith(
      x: toState.x + offsetX,
      y: toState.y + offsetY,
    );

    final isBidirectional = transitions.any((other) =>
        other.id != t.id &&
        other.fromStateId == t.toStateId &&
        other.toStateId == t.fromStateId);

    final samePair = transitions.where((other) =>
        other.fromStateId == t.fromStateId &&
        other.toStateId == t.toStateId).toList();
    final idx = samePair.indexOf(t);

    return TransitionLine(
      from: shiftedFrom,
      to: shiftedTo,
      label: t.label,
      output: t.output,
      isSelfLoop: t.fromStateId == t.toStateId,
      isMealy: isMealy,
      isMoore: isMoore,
      isBidirectional: isBidirectional,
      index: idx,
      totalCount: samePair.length,
      allStates: states.map((s) => s.copyWith(x: s.x + offsetX, y: s.y + offsetY)).toList(),
      allTransitions: transitions,
      transitionId: t.id,
    );
  }

  Widget _buildTableSection(BuildContext context) {
    final isMealy = fsm.isMealy;
    final isMoore = fsm.isMoore;
    final isNFA = fsm.isNFA;
    final inputs = transitions.map((t) => t.label).toSet().toList()..sort();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Transition Table', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
              columns: [
                const DataColumn(
                  label: Text('Present State', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                for (final input in inputs)
                  DataColumn(
                    label: Text(
                      'Next State (Input $input)',
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
                          child: Icon(Icons.arrow_right_alt, size: 18, color: Colors.blue),
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
                          child: Text(' (Final)', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  )),
                  for (final input in inputs)
                    DataCell(_buildCell(state, input, transitions, isMealy, isNFA)),
                  if (isMoore)
                    DataCell(Text(state.output.isNotEmpty ? state.output : '-')),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCell(
    FSMState state,
    String input,
    List<Transition> transitions,
    bool isMealy,
    bool isNFA,
  ) {
    final matching = transitions
        .where((t) => t.fromStateId == state.id && t.label == input)
        .toList();
    if (matching.isEmpty) return const Text('—');

    if (isNFA) {
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
