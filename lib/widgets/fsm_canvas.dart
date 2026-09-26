import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fsm_provider.dart';
import '../models/fsm_state.dart' as fsm_model;
import '../models/transition.dart';
import '../dialogs/state_dialog.dart';
import '../dialogs/transition_dialog.dart';
import 'state_node.dart';
import 'transition_line.dart';

class FSMCanvas extends StatefulWidget {
  final bool isViewMode;

  const FSMCanvas({super.key, this.isViewMode = false});

  @override
  State<FSMCanvas> createState() => FSMCanvasState();
}

class FSMCanvasState extends State<FSMCanvas> with SingleTickerProviderStateMixin {
  String? _movingStateId;
  String? _dragStartStateId;
  Offset? _previewEnd;
  bool _isCreatingTransition = false;

  // View mode: pan and zoom
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  Offset? _lastPanPosition;
  double? _lastScale;

  // Snap-to-grid
  static const double _gridSize = 30.0;
  bool _snapToGrid = true;
  bool get snapToGrid => _snapToGrid;

  // Canvas tap feedback animation
  AnimationController? _tapFeedbackController;
  Offset? _tapFeedbackPos;

  @override
  void initState() {
    super.initState();
    _tapFeedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _tapFeedbackPos = null;
          });
        }
      });
  }

  @override
  void dispose() {
    _tapFeedbackController?.dispose();
    super.dispose();
  }

  void _triggerTapFeedback(Offset pos) {
    setState(() {
      _tapFeedbackPos = pos;
    });
    _tapFeedbackController?.forward(from: 0.0);
  }

  void toggleSnapToGrid() {
    setState(() {
      _snapToGrid = !_snapToGrid;
    });
  }

  // Public zoom/reset methods for external controls
  void zoomIn() {
    setState(() {
      _scale = (_scale * 1.2).clamp(0.3, 3.0);
    });
  }

  void zoomOut() {
    setState(() {
      _scale = (_scale / 1.2).clamp(0.3, 3.0);
    });
  }

  void resetView() {
    setState(() {
      _offset = Offset.zero;
      _scale = 1.0;
    });
  }

  double _snap(double value) {
    if (!_snapToGrid) return value;
    return (value / _gridSize).round() * _gridSize;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FSMProvider>(
      builder: (context, provider, child) {
        final isMealy = provider.currentFSM?.machineType == 'mealy';
        final isMoore = provider.currentFSM?.machineType == 'moore';

        return LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            return GestureDetector(
              onScaleStart: widget.isViewMode ? _onScaleStart : null,
              onScaleUpdate: widget.isViewMode ? _onScaleUpdate : null,
              child: Stack(
                children: [
                  // Grid layer: paints in screen space, always covers the full viewport
                  Positioned.fill(
                    child: CustomPaint(painter: GridPainter(offset: _offset, scale: _scale)),
                  ),
                  // Content layer: transformed by pan/zoom
                  Transform(
                    transform: Matrix4.identity()
                      ..translateByDouble(_offset.dx, _offset.dy, 0.0, 1.0)
                      ..scaleByDouble(_scale, _scale, 1.0, 1.0),
                    child: SizedBox(
                      width: size.width,
                      height: size.height,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp: widget.isViewMode ? null : _handleTap,
                        onDoubleTapDown: widget.isViewMode ? null : _handleDoubleTap,
                        onLongPressStart: widget.isViewMode ? null : _handleLongPress,
                        onPanStart: widget.isViewMode ? null : _handlePanStart,
                        onPanUpdate: widget.isViewMode ? null : _handlePanUpdate,
                        onPanEnd: widget.isViewMode ? null : _handlePanEnd,
                        child: Stack(
                          clipBehavior: Clip.none,
                          fit: StackFit.expand,
                          children: [
                            for (var t in provider.transitions)
                              if (provider.getStateById(t.fromStateId) != null &&
                                  provider.getStateById(t.toStateId) != null)
                                () {
                                  // Compute index among transitions with same from/to pair
                                  final samePair = provider.transitions.where((other) =>
                                      other.fromStateId == t.fromStateId &&
                                      other.toStateId == t.toStateId).toList();
                                  final idx = samePair.indexOf(t);
                                  return TransitionLine(
                                    from: provider.getStateById(t.fromStateId)!,
                                    to: provider.getStateById(t.toStateId)!,
                                    label: t.label,
                                    output: t.output,
                                    isSelfLoop: provider.isSelfLoop(t),
                                    isMealy: isMealy,
                                    isMoore: isMoore,
                                    isBidirectional: provider.transitions.any((other) =>
                                        other.id != t.id &&
                                        other.fromStateId == t.toStateId &&
                                        other.toStateId == t.fromStateId),
                                    index: idx,
                                    totalCount: samePair.length,
                                    allStates: provider.states,
                                    allTransitions: provider.transitions,
                                    transitionId: t.id,
                                  );
                                }(),
                            if (_previewEnd != null && _isCreatingTransition && _dragStartStateId != null)
                              CustomPaint(
                                painter: PreviewLinePainter(
                                  start: _getPreviewStart(provider),
                                  end: _previewEnd!,
                                ),
                              ),
                            for (var state in provider.states)
                              Positioned(
                                left: state.x - 40,
                                top: state.y - 40,
                                child: StateNode(state: state, showOutput: isMoore),
                              ),
                            if (_tapFeedbackPos != null && _tapFeedbackController != null)
                              Positioned(
                                left: _tapFeedbackPos!.dx - 25,
                                top: _tapFeedbackPos!.dy - 25,
                                child: IgnorePointer(
                                  child: AnimatedBuilder(
                                    animation: _tapFeedbackController!,
                                    builder: (context, child) {
                                      final progress = _tapFeedbackController!.value;
                                      return Opacity(
                                        opacity: (1.0 - progress).clamp(0.0, 1.0),
                                        child: Container(
                                          width: 50 * (0.5 + progress * 0.5),
                                          height: 50 * (0.5 + progress * 0.5),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Theme.of(context).colorScheme.primary,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Convert screen coordinates to world coordinates
  Offset _screenToWorld(Offset screenPos) {
    return Offset(
      (screenPos.dx - _offset.dx) / _scale,
      (screenPos.dy - _offset.dy) / _scale,
    );
  }

  // View mode: pan and zoom handlers
  void _onScaleStart(ScaleStartDetails details) {
    _lastPanPosition = details.focalPoint;
    _lastScale = _scale;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      // Pan
      final dx = details.focalPoint.dx - (_lastPanPosition?.dx ?? details.focalPoint.dx);
      final dy = details.focalPoint.dy - (_lastPanPosition?.dy ?? details.focalPoint.dy);
      _offset += Offset(dx, dy);
      _lastPanPosition = details.focalPoint;

      // Zoom
      if (_lastScale != null) {
        _scale = (_lastScale! * details.scale).clamp(0.3, 3.0);
      }
    });
  }

  void _handleTap(TapUpDetails details) {
    final provider = context.read<FSMProvider>();
    final pos = _screenToWorld(details.localPosition);

    // 1. Check if tap is on a state
    for (var state in provider.states) {
      if ((pos - Offset(state.x, state.y)).distance < 30) {
        _showStateContextMenu(state, pos);
        return;
      }
    }

    // 2. Check if tap is on a transition
    for (var t in provider.transitions) {
      final from = provider.getStateById(t.fromStateId);
      final to = provider.getStateById(t.toStateId);
      if (from == null || to == null) continue;

      if (t.fromStateId == t.toStateId) {
        final loopCenter = Offset(from.x, from.y - 56);
        if ((pos - loopCenter).distance < 28) {
          _showTransitionContextMenu(t, pos);
          return;
        }
      } else {
        final midX = (from.x + to.x) / 2;
        final midY = (from.y + to.y) / 2;
        if ((pos - Offset(midX, midY)).distance < 32) {
          _showTransitionContextMenu(t, pos);
          return;
        }
      }
    }

    // 3. Tap is on empty canvas: add state with feedback ripple
    _triggerTapFeedback(details.localPosition);
    provider.addState(pos.dx, pos.dy);
  }

  void _handleDoubleTap(TapDownDetails details) {
    final provider = context.read<FSMProvider>();
    final pos = _screenToWorld(details.localPosition);
    for (var state in provider.states) {
      if ((pos - Offset(state.x, state.y)).distance < 30) {
        provider.updateState(state.copyWith(isFinal: !state.isFinal));
        return;
      }
    }
    _triggerTapFeedback(details.localPosition);
    provider.addState(pos.dx, pos.dy, isFinal: true);
  }

  void _handleLongPress(LongPressStartDetails details) {
    final pos = _screenToWorld(details.localPosition);
    for (var state in context.read<FSMProvider>().states) {
      if ((pos - Offset(state.x, state.y)).distance < 30) {
        _showStateContextMenu(state, pos);
        return;
      }
    }
  }

  void _handlePanStart(DragStartDetails details) {
    final pos = _screenToWorld(details.localPosition);
    for (var state in context.read<FSMProvider>().states) {
      if ((pos - Offset(state.x, state.y)).distance < 30) {
        context.read<FSMProvider>().recordUndoPoint();
        setState(() {
          _movingStateId = state.id;
          _isCreatingTransition = false;
        });
        return;
      }
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_movingStateId != null) {
      final provider = context.read<FSMProvider>();
      final state = provider.getStateById(_movingStateId!);
      if (state != null) {
        final pos = _screenToWorld(details.localPosition);
        provider.updateState(
          state.copyWith(
            x: _snap(pos.dx),
            y: _snap(pos.dy),
          ),
          recordUndo: false,
        );
      }
    } else if (_dragStartStateId != null) {
      setState(() { _previewEnd = _screenToWorld(details.localPosition); });
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_movingStateId != null) {
      setState(() { _movingStateId = null; });
      return;
    }
    setState(() { _dragStartStateId = null; _previewEnd = null; _isCreatingTransition = false; });
  }

  Offset _getPreviewStart(FSMProvider provider) {
    if (_dragStartStateId != null) {
      final state = provider.getStateById(_dragStartStateId!);
      if (state != null) return Offset(state.x, state.y);
    }
    return Offset.zero;
  }

  void _showStateContextMenu(fsm_model.FSMState state, Offset position) {
    final provider = context.read<FSMProvider>();
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 1, position.dy + 1),
      items: [
        if (!state.isInitial)
          const PopupMenuItem(value: 'set_initial', child: ListTile(leading: Icon(Icons.play_arrow), title: Text('Set as Initial'), dense: true)),
        const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit State'), dense: true)),
        const PopupMenuItem(value: 'add_transition', child: ListTile(leading: Icon(Icons.arrow_forward), title: Text('Add Transition'), dense: true)),
        const PopupMenuItem(value: 'add_self_loop', child: ListTile(leading: Icon(Icons.loop), title: Text('Add Self-Loop'), dense: true)),
        const PopupMenuItem(value: 'toggle_final', child: ListTile(leading: Icon(Icons.circle_outlined), title: Text('Toggle Final State'), dense: true)),
        const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Delete', style: TextStyle(color: Colors.red)), dense: true)),
      ],
    ).then((value) {
      if (value == null || !mounted) return;
      switch (value) {
        case 'set_initial': provider.setInitialState(state.id); break;
        case 'edit':
          showDialog(
            context: context,
            builder: (_) => StateDialog(state: state),
          );
          break;
        case 'add_transition': _showAddTransitionPicker(state); break;
        case 'add_self_loop':
          showDialog(
            context: context,
            builder: (_) => TransitionDialog(
              fromStateId: state.id,
              toStateId: state.id,
            ),
          );
          break;
        case 'toggle_final': provider.updateState(state.copyWith(isFinal: !state.isFinal)); break;
        case 'delete': provider.deleteState(state.id); break;
      }
    });
  }

  void _showTransitionContextMenu(Transition transition, Offset position) {
    final provider = context.read<FSMProvider>();
    final fromState = provider.getStateById(transition.fromStateId);
    final toState = provider.getStateById(transition.toStateId);
    final label = '${fromState?.label ?? '?'} → ${toState?.label ?? '?'}: "${transition.label}"';

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 1, position.dy + 1),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          enabled: false,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'edit',
          child: ListTile(leading: Icon(Icons.edit), title: Text('Edit Transition'), dense: true),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Delete', style: TextStyle(color: Colors.red)), dense: true),
        ),
      ],
    ).then((value) {
      if (value == null || !mounted) return;
      switch (value) {
        case 'edit':
          showDialog(
            context: context,
            builder: (_) => TransitionDialog(transition: transition),
          );
          break;
        case 'delete':
          provider.deleteTransition(transition.id);
          break;
      }
    });
  }

  void _showAddTransitionPicker(fsm_model.FSMState fromState) {
    final provider = context.read<FSMProvider>();
    final otherStates = provider.states.where((s) => s.id != fromState.id).toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Transition from ${fromState.label}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.loop),
                title: const Text('Self-loop'),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (_) => TransitionDialog(
                      fromStateId: fromState.id,
                      toStateId: fromState.id,
                    ),
                  );
                },
              ),
              for (var target in otherStates)
                ListTile(
                  leading: const Icon(Icons.arrow_forward),
                  title: Text('To ${target.label}'),
                  onTap: () {
                    Navigator.pop(ctx);
                    showDialog(
                      context: context,
                      builder: (_) => TransitionDialog(
                        fromStateId: fromState.id,
                        toStateId: target.id,
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final Offset offset;
  final double scale;

  GridPainter({this.offset = Offset.zero, this.scale = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.grey.withValues(alpha: 0.2)..strokeWidth = 1;
    const gridSize = 30.0;
    final scaledGrid = gridSize * scale;

    // Calculate the offset of the first grid line in screen space
    final firstX = offset.dx % scaledGrid;
    final firstY = offset.dy % scaledGrid;

    // Draw vertical lines across the full viewport
    for (double x = firstX; x <= size.width; x += scaledGrid) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Draw horizontal lines across the full viewport
    for (double y = firstY; y <= size.height; y += scaledGrid) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) =>
      oldDelegate.offset != offset || oldDelegate.scale != scale;
}

class PreviewLinePainter extends CustomPainter {
  final Offset start;
  final Offset end;
  PreviewLinePainter({required this.start, required this.end});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.blue.withValues(alpha: 0.5)..strokeWidth = 2..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
