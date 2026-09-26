class Transition {
  final String id;
  final String fsmId;
  final String fromStateId;
  final String toStateId;
  final String label; // Input event
  final String output; // For Mealy machine: output on transition

  Transition({
    required this.id,
    required this.fsmId,
    required this.fromStateId,
    required this.toStateId,
    required this.label,
    this.output = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fsmId': fsmId,
      'fromStateId': fromStateId,
      'toStateId': toStateId,
      'label': label,
      'output': output,
    };
  }

  factory Transition.fromMap(Map<String, dynamic> map) {
    return Transition(
      id: map['id'],
      fsmId: map['fsmId'],
      fromStateId: map['fromStateId'],
      toStateId: map['toStateId'],
      label: map['label'],
      output: map['output'] ?? '',
    );
  }

  Transition copyWith({
    String? label,
    String? fromStateId,
    String? toStateId,
    String? output,
  }) {
    return Transition(
      id: id,
      fsmId: fsmId,
      fromStateId: fromStateId ?? this.fromStateId,
      toStateId: toStateId ?? this.toStateId,
      label: label ?? this.label,
      output: output ?? this.output,
    );
  }
}
