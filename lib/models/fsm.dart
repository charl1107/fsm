class FSM {
  final String id;
  final String name;
  final DateTime createdAt;
  final String machineType; // 'mealy', 'moore', 'nfa', 'dfa'

  FSM({
    required this.id,
    required this.name,
    required this.createdAt,
    this.machineType = 'mealy',
  });

  bool get isNFA => machineType == 'nfa';
  bool get isDFA => machineType == 'dfa';
  bool get isMealy => machineType == 'mealy';
  bool get isMoore => machineType == 'moore';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'machineType': machineType,
    };
  }

  factory FSM.fromMap(Map<String, dynamic> map) {
    return FSM(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      machineType: map['machineType'] ?? 'mealy',
    );
  }

  FSM copyWith({String? name, String? machineType}) {
    return FSM(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      machineType: machineType ?? this.machineType,
    );
  }
}
