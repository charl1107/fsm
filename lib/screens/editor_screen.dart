import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import '../providers/fsm_provider.dart';
import '../widgets/fsm_canvas.dart';
import '../widgets/fsm_export_sheet.dart';
import '../utils/export_helper.dart';
import '../utils/nfa_dfa_converter.dart';
import '../models/fsm_state.dart';
import '../models/transition.dart';
import 'transition_table_screen.dart';

class EditorScreen extends StatefulWidget {
  final String fsmId;

  const EditorScreen({super.key, required this.fsmId});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final ScreenshotController screenshotController = ScreenshotController();
  final ScreenshotController _offscreenScreenshotController = ScreenshotController();
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FSMCanvasState> _canvasKey = GlobalKey<FSMCanvasState>();
  bool _isViewMode = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FSMProvider>().openFSM(widget.fsmId);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<FSMProvider>(
          builder: (context, provider, child) {
            final fsm = provider.currentFSM;
            if (fsm != null) {
              return GestureDetector(
                onTap: () => _showRenameDialog(fsm.name),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(fsm.name),
                    const Icon(Icons.edit, size: 16),
                  ],
                ),
              );
            }
            return const Text('FSM Editor');
          },
        ),
        centerTitle: true,
        actions: [
          Consumer<FSMProvider>(
            builder: (context, provider, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.undo),
                  onPressed: provider.canUndo ? () => provider.undo() : null,
                  tooltip: 'Undo',
                ),
                IconButton(
                  icon: const Icon(Icons.redo),
                  onPressed: provider.canRedo ? () => provider.redo() : null,
                  tooltip: 'Redo',
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            onPressed: _showSimulationDialog,
            tooltip: 'Simulate Input String',
          ),
          IconButton(
            icon: Icon(_isViewMode ? Icons.edit : Icons.pan_tool),
            onPressed: () => setState(() => _isViewMode = !_isViewMode),
            tooltip: _isViewMode ? 'Switch to Edit Mode' : 'Switch to View Mode',
          ),
          if (context.watch<FSMProvider>().currentFSM?.isNFA == true)
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              onPressed: _convertNFAToDFA,
              tooltip: 'Convert NFA to DFA',
            ),
          IconButton(
            icon: const Icon(Icons.table_chart),
            onPressed: _openTransitionTable,
            tooltip: 'Transition Table',
          ),
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: _exportDiagram,
            tooltip: 'Export as Image',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Canvas
          SizedBox.expand(
            child: Screenshot(
              controller: screenshotController,
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                child: FSMCanvas(
                  key: _canvasKey,
                  isViewMode: _isViewMode,
                ),
              ),
            ),
          ),
          // Mode indicator chip
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Container(
                  key: ValueKey(_isViewMode),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isViewMode
                        ? Colors.blue.withValues(alpha: 0.9)
                        : Colors.green.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isViewMode ? Icons.pan_tool : Icons.edit,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isViewMode ? 'View Mode' : 'Edit Mode',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Zoom controls (right side)
          Positioned(
            right: 12,
            bottom: 80,
            child: Column(
              children: [
                _buildZoomButton(Icons.add, 'Zoom in', () {
                  _canvasKey.currentState?.zoomIn();
                }),
                const SizedBox(height: 4),
                _buildZoomButton(Icons.remove, 'Zoom out', () {
                  _canvasKey.currentState?.zoomOut();
                }),
                const SizedBox(height: 4),
                _buildZoomButton(Icons.fit_screen, 'Fit to screen', () {
                  _canvasKey.currentState?.resetView();
                }),
              ],
            ),
          ),
          // Bottom action bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBottomAction(Icons.table_chart_outlined, 'Table', _openTransitionTable),
                    _buildBottomAction(Icons.save_alt, 'Export', _exportDiagram),
                    _buildBottomAction(Icons.help_outline, 'Help', _showHelpOverlay),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openTransitionTable() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TransitionTableScreen(),
      ),
    );
  }

  void _convertNFAToDFA() {
    final provider = context.read<FSMProvider>();
    final nfaStates = provider.states;
    final nfaTransitions = provider.transitions;

    if (nfaStates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No states to convert'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (!nfaStates.any((s) => s.isInitial)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Set an initial state first (long-press a state → Set as Initial)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Map<String, dynamic> result;
    String formattedResult;
    try {
      result = NFADFAConverter.convertNFAToDFA(
        nfaStates: nfaStates,
        nfaTransitions: nfaTransitions,
        fsmId: provider.currentFSM!.id,
      );

      formattedResult = NFADFAConverter.formatConversionResult(
        nfaStates: nfaStates,
        nfaTransitions: nfaTransitions,
        result: result,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Conversion failed: $e'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('NFA to DFA Conversion'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Text(
              formattedResult,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _applyDFAConversion(result);
            },
            child: const Text('Apply Conversion'),
          ),
        ],
      ),
    );
  }

  void _applyDFAConversion(Map<String, dynamic> result) async {
    if (!mounted) return;
    final provider = context.read<FSMProvider>();

    await provider.updateMachineType('dfa');
    if (!mounted) return;

    for (var state in provider.states.toList()) {
      await provider.deleteState(state.id);
      if (!mounted) return;
    }

    final dfaStates = result['states'] as List<FSMState>;
    final dfaTransitions = result['transitions'] as List<Transition>;
    final idMap = <String, String>{}; // old id -> new created id

    for (var s in dfaStates) {
      final newState = await provider.addState(
        s.x,
        s.y,
        customLabel: s.label,
        isFinal: s.isFinal,
        output: s.output,
      );
      if (!mounted) return;
      idMap[s.id] = newState.id;
    }

    for (var t in dfaTransitions) {
      final newFrom = idMap[t.fromStateId];
      final newTo = idMap[t.toStateId];
      if (newFrom != null && newTo != null) {
        await provider.addTransition(newFrom, newTo, t.label);
        if (!mounted) return;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NFA converted to DFA!'), backgroundColor: Colors.green),
      );
    }
  }

  void _showRenameDialog(String currentName) {
    _nameController.text = currentName;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename FSM'),
        content: TextField(
          controller: _nameController,
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
              if (_nameController.text.trim().isNotEmpty) {
                context.read<FSMProvider>().updateFSMName(_nameController.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _exportDiagram() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Options'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose what you would like to download:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.dashboard_customize, size: 20),
                ),
                title: const Text('All-in-One Sheet (Full)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Diagram + Transition Table + Formal 5/6-Tuple in one image'),
                onTap: () {
                  Navigator.pop(context);
                  _exportAllInOne();
                },
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('Download Separately:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schema, color: Colors.indigo),
                title: const Text('State Diagram Only'),
                subtitle: const Text('Current canvas drawing'),
                onTap: () {
                  Navigator.pop(context);
                  _exportSingle('diagram');
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.table_chart, color: Colors.teal),
                title: const Text('Transition Table Only'),
                subtitle: const Text('State transition matrix table'),
                onTap: () {
                  Navigator.pop(context);
                  _exportSingle('table');
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.menu_book, color: Colors.deepOrange),
                title: const Text('Formal Definition (Tuple) Only'),
                subtitle: const Text('5-Tuple (DFA/NFA) or 6-Tuple (Mealy/Moore)'),
                onTap: () {
                  Navigator.pop(context);
                  _exportSingle('tuple');
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _exportAllInOne() async {
    final provider = context.read<FSMProvider>();
    final fsm = provider.currentFSM;
    if (fsm == null) return;

    try {
      final exportWidget = MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.light(useMaterial3: true),
        home: Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            child: FSMExportSheet(
              fsm: fsm,
              states: provider.states,
              transitions: provider.transitions,
              provider: provider,
            ),
          ),
        ),
      );

      final imageBytes = await _offscreenScreenshotController.captureFromWidget(
        exportWidget,
        delay: const Duration(milliseconds: 250),
        pixelRatio: 2.0,
      );

      _showSaveFormatDialog(imageBytes, '${fsm.name}_full_sheet');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _exportSingle(String type) async {
    final provider = context.read<FSMProvider>();
    final fsm = provider.currentFSM;
    if (fsm == null) return;

    try {
      Uint8List? imageBytes;

      if (type == 'diagram') {
        imageBytes = await screenshotController.capture();
      } else {
        Widget targetWidget;
        if (type == 'table') {
          targetWidget = Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${fsm.name} - Transition Table', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                FSMExportSheet(
                  fsm: fsm,
                  states: provider.states,
                  transitions: provider.transitions,
                  provider: provider,
                ),
              ],
            ),
          );
        } else {
          // Tuple only
          targetWidget = Container(
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${fsm.name} - Formal Definition', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                FSMExportSheet(
                  fsm: fsm,
                  states: provider.states,
                  transitions: provider.transitions,
                  provider: provider,
                ),
              ],
            ),
          );
        }

        imageBytes = await _offscreenScreenshotController.captureFromWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData.light(useMaterial3: true),
            home: Scaffold(
              backgroundColor: Colors.white,
              body: SingleChildScrollView(child: targetWidget),
            ),
          ),
          delay: const Duration(milliseconds: 200),
          pixelRatio: 2.0,
        );
      }

      if (imageBytes != null && mounted) {
        _showSaveFormatDialog(imageBytes, '${fsm.name}_$type');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSaveFormatDialog(Uint8List imageBytes, String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: Colors.blue),
              title: const Text('PNG Image'),
              subtitle: const Text('High-resolution lossless'),
              onTap: () => _executeSave(imageBytes, fileName, 'png'),
            ),
            ListTile(
              leading: const Icon(Icons.photo, color: Colors.amber),
              title: const Text('JPG Image'),
              subtitle: const Text('Compressed size'),
              onTap: () => _executeSave(imageBytes, fileName, 'jpg'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ],
      ),
    );
  }

  void _executeSave(Uint8List imageBytes, String fileName, String format) async {
    Navigator.pop(context);
    final path = await ExportHelper.saveImageToFile(imageBytes, fileName, format: format);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(path != null ? 'Saved: $path' : 'Failed to save file'),
          backgroundColor: path != null ? Colors.green : Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
  Widget _buildZoomButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction(IconData icon, String label, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpOverlay() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, size: 22),
            SizedBox(width: 8),
            Text('Gesture Guide'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              _helpRow(Icons.touch_app, 'Tap canvas', 'Add a new state'),
              _helpRow(Icons.touch_app, 'Double-tap canvas', 'Add a final state'),
              _helpRow(Icons.touch_app, 'Tap a state', 'Open context menu'),
              _helpRow(Icons.pan_tool, 'Drag a state', 'Move it'),
              _helpRow(Icons.touch_app, 'Long-press a state', 'Context menu'),
              const Divider(height: 24),
              const Text('View Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              _helpRow(Icons.pan_tool, 'Drag', 'Pan the canvas'),
              _helpRow(Icons.pinch, 'Pinch', 'Zoom in/out'),
              const Divider(height: 24),
              const Text('State Context Menu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              _helpRow(Icons.play_arrow, 'Set as Initial', 'Starting state'),
              _helpRow(Icons.edit, 'Edit State', 'Change label'),
              _helpRow(Icons.arrow_forward, 'Add Transition', 'Connect states'),
              _helpRow(Icons.loop, 'Add Self-Loop', 'Transition to self'),
              _helpRow(Icons.circle_outlined, 'Toggle Final', 'Double circle'),
              _helpRow(Icons.delete, 'Delete', 'Remove state'),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _helpRow(IconData icon, String gesture, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Text(gesture, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(width: 6),
          Text('— $action', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  void _showSimulationDialog() {
    final provider = context.read<FSMProvider>();
    final states = provider.states;
    final transitions = provider.transitions;

    if (states.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add states first'), backgroundColor: Colors.orange),
      );
      return;
    }

    final initialStates = states.where((s) => s.isInitial).toList();
    if (initialStates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please mark an initial state first'), backgroundColor: Colors.orange),
      );
      return;
    }

    final controller = TextEditingController();
    List<Map<String, dynamic>>? simulationSteps;
    bool isAccepted = false;
    String mealyOutput = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.play_circle_fill, color: Colors.blue),
              SizedBox(width: 8),
              Text('String Simulation'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Input String',
                      hintText: 'e.g., 0101, aab, 10',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.directions_run),
                      label: const Text('Run Simulation'),
                      onPressed: () {
                        final input = controller.text.trim();
                        final isMealy = provider.currentFSM?.isMealy == true;
                        var current = initialStates.first;
                        final steps = <Map<String, dynamic>>[];
                        final outBuf = StringBuffer();
                        bool valid = true;

                        steps.add({
                          'state': current.label,
                          'input': '-',
                          'output': current.output,
                          'desc': 'Start at initial state ${current.label}',
                        });

                        for (int i = 0; i < input.length; i++) {
                          final symbol = input[i];
                          final matching = transitions.where((t) =>
                              t.fromStateId == current.id && t.label == symbol).toList();

                          if (matching.isEmpty) {
                            valid = false;
                            steps.add({
                              'state': current.label,
                              'input': symbol,
                              'output': '-',
                              'desc': 'Rejected: No transition from ${current.label} on "$symbol"',
                            });
                            break;
                          }

                          final t = matching.first;
                          final next = provider.getStateById(t.toStateId);
                          if (next == null) {
                            valid = false;
                            break;
                          }

                          if (isMealy && t.output.isNotEmpty) {
                            outBuf.write(t.output);
                          } else if (next.output.isNotEmpty) {
                            outBuf.write(next.output);
                          }

                          steps.add({
                            'state': next.label,
                            'input': symbol,
                            'output': isMealy ? t.output : next.output,
                            'desc': 'δ(${current.label}, $symbol) → ${next.label}'
                                '${(isMealy && t.output.isNotEmpty) ? ' (out: ${t.output})' : ''}',
                          });
                          current = next;
                        }

                        setDialogState(() {
                          simulationSteps = steps;
                          isAccepted = valid && (current.isFinal || provider.currentFSM?.isMealy == true || provider.currentFSM?.isMoore == true);
                          mealyOutput = outBuf.toString();
                        });
                      },
                    ),
                  ),
                  if (simulationSteps != null) ...[
                    const Divider(height: 24),
                    Row(
                      children: [
                        Icon(
                          isAccepted ? Icons.check_circle : Icons.cancel,
                          color: isAccepted ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isAccepted ? 'Result: ACCEPTED' : 'Result: REJECTED',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isAccepted ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    if (mealyOutput.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Total Output: $mealyOutput',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Text('Execution Trace:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < simulationSteps!.length; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                '${i + 1}. ${simulationSteps![i]['desc']}',
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
