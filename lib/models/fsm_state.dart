class FSMState {
  final String id;
  final String fsmId;
  final String label;
  final double x;
  final double y;
  final bool isInitial;
  final bool isFinal;
  final String output; // For Moore machine: output on state
  final String? color; // Hex string e.g. '#E57373'

  FSMState({
    required this.id,
    required this.fsmId,
    required this.label,
    required this.x,
    required this.y,
    this.isInitial = false,
    this.isFinal = false,
    this.output = '',
    this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fsmId': fsmId,
      'label': label,
      'x': x,
      'y': y,
      'isInitial': isInitial ? 1 : 0,
      'isFinal': isFinal ? 1 : 0,
      'output': output,
      'color': color,
    };
  }

  factory FSMState.fromMap(Map<String, dynamic> map) {
    return FSMState(
      id: map['id'],
      fsmId: map['fsmId'],
      label: map['label'],
      x: map['x'],
      y: map['y'],
      isInitial: map['isInitial'] == 1 || map['isInitial'] == true,
      isFinal: map['isFinal'] == 1 || map['isFinal'] == true,
      output: map['output'] ?? '',
      color: map['color'],
    );
  }

  FSMState copyWith({
    String? label,
    double? x,
    double? y,
    bool? isInitial,
    bool? isFinal,
    String? output,
    String? color,
    bool clearColor = false,
  }) {
    return FSMState(
      id: id,
      fsmId: fsmId,
      label: label ?? this.label,
      x: x ?? this.x,
      y: y ?? this.y,
      isInitial: isInitial ?? this.isInitial,
      isFinal: isFinal ?? this.isFinal,
      output: output ?? this.output,
      color: clearColor ? null : (color ?? this.color),
    );
  }
}
