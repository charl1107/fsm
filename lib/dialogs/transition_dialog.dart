import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fsm_provider.dart';
import '../models/transition.dart';

class TransitionDialog extends StatefulWidget {
  final String? fromStateId;
  final String? toStateId;
  final Transition? transition;

  const TransitionDialog({
    super.key,
    this.fromStateId,
    this.toStateId,
    this.transition,
  });

  @override
  State<TransitionDialog> createState() => _TransitionDialogState();
}

class _TransitionDialogState extends State<TransitionDialog> {
  late TextEditingController _labelController;
  late TextEditingController _outputController;
  String? _selectedFromId;
  String? _selectedToId;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.transition?.label ?? '');
    _outputController = TextEditingController(text: widget.transition?.output ?? '');
    _selectedFromId = widget.fromStateId ?? widget.transition?.fromStateId;
    _selectedToId = widget.toStateId ?? widget.transition?.toStateId;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.transition == null;
    final provider = context.watch<FSMProvider>();
    final states = provider.states;
    final isMealy = provider.currentFSM?.machineType == 'mealy';

    return AlertDialog(
      title: Text(isNew ? 'Add Transition' : 'Edit Transition'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedFromId,
              decoration: const InputDecoration(
                labelText: 'From State',
                border: OutlineInputBorder(),
              ),
              items: states.map((state) {
                return DropdownMenuItem(
                  value: state.id,
                  child: Text(state.label),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFromId = value;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedToId,
              decoration: const InputDecoration(
                labelText: 'To State',
                border: OutlineInputBorder(),
              ),
              items: states.map((state) {
                return DropdownMenuItem(
                  value: state.id,
                  child: Text(state.label),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedToId = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _labelController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Event Label (Input)',
                hintText: 'e.g., 0, 1, a, onToggle',
                border: OutlineInputBorder(),
              ),
            ),
            if (isMealy) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _outputController,
                decoration: const InputDecoration(
                  labelText: 'Output (Mealy: Input/Output)',
                  hintText: 'e.g., 0, 1, b',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!isNew)
          TextButton(
            onPressed: () {
              context.read<FSMProvider>().deleteTransition(widget.transition!.id);
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
    if (label.isEmpty || _selectedFromId == null || _selectedToId == null) return;

    final provider = context.read<FSMProvider>();

    if (widget.transition != null) {
      provider.updateTransition(
        widget.transition!.copyWith(
          label: label,
          output: output,
          fromStateId: _selectedFromId,
          toStateId: _selectedToId,
        ),
      );
    } else {
      provider.addTransition(
        _selectedFromId!,
        _selectedToId!,
        label,
        output: output,
      );
    }

    Navigator.pop(context);
  }

}
