import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:fsm_editor/main.dart';
import 'package:fsm_editor/providers/fsm_provider.dart';
import 'package:fsm_editor/screens/editor_screen.dart';
import 'package:fsm_editor/screens/home_screen.dart';
import 'package:fsm_editor/widgets/fsm_canvas.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full FSM flow: create, edit, convert, table, simulate, export',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const FSMEditorApp());
    await tester.pumpAndSettle();

    // --- 1. Home screen ---
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('No FSMs yet'), findsOneWidget);

    // --- 2. Create NFA ---
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Create New FSM'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'QA Test NFA');
    await tester.tap(find.text('NFA'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    expect(find.byType(EditorScreen), findsOneWidget);

    final editorContext = tester.element(find.byType(EditorScreen));
    final provider = Provider.of<FSMProvider>(editorContext, listen: false);
    expect(provider.currentFSM, isNotNull);
    expect(provider.currentFSM!.machineType, 'nfa');
    expect(provider.currentFSM!.name, 'QA Test NFA');

    // --- 3. Tap canvas to add two states ---
    final canvasTopLeft = tester.getTopLeft(find.byType(FSMCanvas));
    final stateAPos = canvasTopLeft + const Offset(300, 200);
    final stateBPos = canvasTopLeft + const Offset(600, 300);

    await tester.tapAt(stateAPos);
    await tester.pumpAndSettle();
    await tester.tapAt(stateBPos);
    await tester.pumpAndSettle();
    expect(provider.states.length, 2, reason: 'tapping empty canvas must add states');

    // --- 4. NFA->DFA without initial state must NOT crash ---
    await tester.tap(find.byTooltip('Convert NFA to DFA'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Set an initial state first'),
      findsOneWidget,
      reason: 'conversion must be blocked with a clear message when no initial state',
    );
    expect(provider.states.length, 2, reason: 'states must be untouched after blocked conversion');
    await tester.pump(const Duration(seconds: 5));

    // --- 5. Long-press state A -> Set as Initial ---
    await tester.longPressAt(stateAPos);
    await tester.pumpAndSettle();
    expect(find.text('Set as Initial'), findsOneWidget);
    await tester.tap(find.text('Set as Initial'));
    await tester.pumpAndSettle();
    expect(provider.states.any((s) => s.isInitial), isTrue);

    // --- 6. Long-press state A -> Add Transition -> Self-loop ---
    await tester.longPressAt(stateAPos);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Transition'));
    await tester.pumpAndSettle();
    expect(find.text('Self-loop'), findsOneWidget);
    await tester.tap(find.text('Self-loop'));
    await tester.pumpAndSettle();

    expect(find.text('Add Transition'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'e.g., 0, 1, a, onToggle'),
      'a',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();
    expect(provider.transitions.length, 1, reason: 'self-loop transition must be added');

    // --- 7. Transition table ---
    await tester.tap(find.byTooltip('Transition Table'));
    await tester.pumpAndSettle();
    expect(find.text('Transition Table'), findsOneWidget);
    expect(find.textContaining('NFA (Non-deterministic'), findsOneWidget);
    expect(find.byType(DataTable), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(EditorScreen), findsOneWidget);

    // --- 8. Simulation ---
    await tester.tap(find.byTooltip('Simulate Input String'));
    await tester.pumpAndSettle();
    expect(find.text('String Simulation'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'e.g., 0101, aab, 10'), 'a');
    await tester.tap(find.widgetWithText(FilledButton, 'Run Simulation'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Result:'), findsOneWidget);
    expect(find.textContaining('Execution Trace'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Close'));
    await tester.pumpAndSettle();

    // --- 9. NFA->DFA conversion with initial state set ---
    await tester.tap(find.byTooltip('Convert NFA to DFA'));
    await tester.pumpAndSettle();
    expect(find.text('NFA to DFA Conversion'), findsOneWidget);
    expect(find.textContaining('Subset Construction'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Apply Conversion'));
    await tester.pumpAndSettle();
    expect(provider.currentFSM!.machineType, 'dfa');
    expect(provider.states.length, greaterThan(0));
    expect(provider.states.any((s) => s.isInitial), isTrue);
    await tester.pump(const Duration(seconds: 3));

    // --- 10. Export diagram (PNG) ---
    await tester.tap(find.byTooltip('Export as Image'));
    await tester.pumpAndSettle();
    expect(find.text('Export Options'), findsOneWidget);
    await tester.tap(find.text('State Diagram Only'));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('Choose Format'), findsOneWidget);
    await tester.tap(find.widgetWithText(ListTile, 'PNG Image'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    final exportSnackBar = find.textContaining(
      RegExp(r'(Saved:|Failed to save)'),
    );
    expect(exportSnackBar, findsOneWidget, reason: 'export must report a result');
    debugPrint('EXPORT RESULT: ${tester.widget<Text>(exportSnackBar).data}');
  });
}
