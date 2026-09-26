import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/fsm.dart';
import '../providers/fsm_provider.dart';
import 'editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FSMProvider>().loadFSMs();
    });
  }

  void _showCreateDialog() {
    final controller = TextEditingController();
    String selectedType = 'mealy';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New FSM'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'FSM Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Machine Type',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                RadioGroup<String>(
                  groupValue: selectedType,
                  onChanged: (value) => setState(() => selectedType = value!),
                  child: Column(
                    children: const [
                      RadioListTile<String>(
                        title: Text('Mealy Machine'),
                        subtitle: Text('Output on transitions'),
                        value: 'mealy',
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<String>(
                        title: Text('Moore Machine'),
                        subtitle: Text('Output on states'),
                        value: 'moore',
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<String>(
                        title: Text('NFA'),
                        subtitle: Text('Non-deterministic, ε-transitions'),
                        value: 'nfa',
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<String>(
                        title: Text('DFA'),
                        subtitle: Text('Deterministic, single transition per input'),
                        value: 'dfa',
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => _createFSM(controller.text, selectedType),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _createFSM(String name, String machineType) {
    if (name.trim().isEmpty) return;
    Navigator.pop(context);
    context.read<FSMProvider>().createFSM(name.trim(), machineType: machineType).then((fsm) {
      _openEditor(fsm.id);
    });
  }

  void _openEditor(String fsmId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditorScreen(fsmId: fsmId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FSM Editor'),
        centerTitle: true,
      ),
      body: Consumer<FSMProvider>(
        builder: (context, provider, child) {
          if (provider.fsms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_tree_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No FSMs yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create your first finite state machine',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: provider.fsms.length,
            itemBuilder: (context, index) {
              final fsm = provider.fsms[index];
              final isMealy = fsm.machineType == 'mealy';
              final isNFA = fsm.machineType == 'nfa';
              final isDFA = fsm.machineType == 'dfa';
              final typeLabel = isNFA ? 'NFA' : isDFA ? 'DFA' : isMealy ? 'Mealy' : 'Moore';
              final typeColor = isNFA 
                  ? const Color(0xFFE65100) 
                  : isDFA 
                      ? const Color(0xFF6A1B9A) 
                      : isMealy 
                          ? const Color(0xFF1565C0) 
                          : const Color(0xFF2E7D32);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _openEditor(fsm.id),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isNFA 
                                ? Icons.account_tree 
                                : isDFA 
                                    ? Icons.check_circle 
                                    : isMealy 
                                        ? Icons.swap_horiz 
                                        : Icons.circle_outlined,
                            color: typeColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fsm.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: typeColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      typeLabel,
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: typeColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${fsm.createdAt.day}/${fsm.createdAt.month}/${fsm.createdAt.year}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showRenameDialog(fsm),
                          tooltip: 'Rename',
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                          onPressed: () => _confirmDelete(fsm.id, fsm.name),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        tooltip: 'Create FSM',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showRenameDialog(FSM fsm) {
    final controller = TextEditingController(text: fsm.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename FSM'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'FSM Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<FSMProvider>().updateFSMNameById(fsm.id, controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete FSM'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<FSMProvider>().deleteFSM(id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
