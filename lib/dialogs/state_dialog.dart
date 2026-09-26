import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fsm_provider.dart';
import '../models/fsm_state.dart' as fsm_model;

class StateDialog extends StatefulWidget {
  final fsm_model.FSMState? state;

  const StateDialog({super.key, this.state});

  @override
  State<StateDialog> createState() => _StateDialogState();
}

class _StateDialogState extends State<StateDialog> {
  late TextEditingController _labelController;
  late TextEditingController _outputController;
  bool _isInitial = false;
  bool _isFinal = false;
  String? _selectedColor;

  static const List<Map<String, dynamic>> _presetColors = [
    {'name': 'Default', 'color': null, 'hex': null},
    {'name': 'Red', 'color': Color(0xFFFFCDD2), 'hex': '#FFCDD2'},
    {'name': 'Green', 'color': Color(0xFFC8E6C9), 'hex': '#C8E6C9'},
    {'name': 'Blue', 'color': Color(0xFFBBDEFB), 'hex': '#BBDEFB'},
    {'name': 'Amber', 'color': Color(0xFFFFECB3), 'hex': '#FFECB3'},
    {'name': 'Purple', 'color': Color(0xFFE1BEE7), 'hex': '#E1BEE7'},
    {'name': 'Teal', 'color': Color(0xFFB2DFDB), 'hex': '#B2DFDB'},
  ];

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.state?.label ?? '');
    _outputController = TextEditingController(text: widget.state?.output ?? '');
    _isInitial = widget.state?.isInitial ?? false;
    _isFinal = widget.state?.isFinal ?? false;
    _selectedColor = widget.state?.color;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.state == null;
    final isMoore = context.watch<FSMProvider>().currentFSM?.machineType == 'moore';

    return AlertDialog(
      title: Text(isNew ? 'Add State' : 'Edit State'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _labelController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'State Label',
                hintText: 'e.g., A, Idle, Running',
                border: OutlineInputBorder(),
              ),
            ),
            if (isMoore) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _outputController,
                decoration: const InputDecoration(
                  labelText: 'State Output',
                  hintText: 'e.g., 0, 1, b',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Color Tag',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presetColors.map((preset) {
                final hex = preset['hex'] as String?;
                final isSelected = _selectedColor == hex;
                final color = preset['color'] as Color?;
                return ChoiceChip(
                  label: Text(preset['name'] as String),
                  selected: isSelected,
                  avatar: color != null
                      ? CircleAvatar(backgroundColor: color, radius: 8)
                      : null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedColor = selected ? hex : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Initial State'),
              subtitle: const Text('Starting state of the FSM'),
              value: _isInitial,
              onChanged: (value) {
                setState(() {
                  _isInitial = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Final State'),
              subtitle: const Text('Accepting state'),
              value: _isFinal,
              onChanged: (value) {
                setState(() {
                  _isFinal = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        if (!isNew)
          TextButton(
            onPressed: () {
              context.read<FSMProvider>().deleteState(widget.state!.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(isNew ? 'Add' : 'Save'),
        ),
      ],
    );
  }

  void _save() {
    final label = _labelController.text.trim();
    final output = _outputController.text.trim();
    if (label.isEmpty) return;

    final provider = context.read<FSMProvider>();

    if (widget.state != null) {
      provider.updateState(
        widget.state!.copyWith(
          label: label,
          isInitial: _isInitial,
          isFinal: _isFinal,
          output: output,
          color: _selectedColor,
          clearColor: _selectedColor == null,
        ),
      );
    } else {
      provider.addState(
        200,
        200,
        customLabel: label,
        isFinal: _isFinal,
        output: output,
        color: _selectedColor,
      );
    }

    Navigator.pop(context);
  }

}
