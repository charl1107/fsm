import 'dart:math';
import 'package:flutter/material.dart';
import '../models/fsm_state.dart' as fsm_model;

class StateNode extends StatelessWidget {
  final fsm_model.FSMState state;
  final double radius;
  final bool showOutput;

  const StateNode({
    super.key,
    required this.state,
    this.radius = 30,
    this.showOutput = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: radius * 2 + 20,
      height: radius * 2 + 20 + (showOutput && state.output.isNotEmpty ? 20 : 0),
      child: CustomPaint(
        painter: StateNodePainter(
          state: state,
          radius: radius,
          showOutput: showOutput,
          primaryColor: Theme.of(context).colorScheme.primary,
          surfaceColor: Theme.of(context).colorScheme.surface,
          onSurfaceColor: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class StateNodePainter extends CustomPainter {
  final fsm_model.FSMState state;
  final double radius;
  final bool showOutput;
  final Color primaryColor;
  final Color surfaceColor;
  final Color onSurfaceColor;

  StateNodePainter({
    required this.state,
    required this.radius,
    this.showOutput = false,
    required this.primaryColor,
    required this.surfaceColor,
    required this.onSurfaceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center + const Offset(0, 2), radius, shadowPaint);

    // Fill with custom color or surfaceColor
    Color nodeBgColor = surfaceColor;
    if (state.color != null && state.color!.isNotEmpty) {
      try {
        final hexStr = state.color!.replaceAll('#', '');
        final val = int.parse(hexStr, radix: 16);
        nodeBgColor = Color(val.bitLength <= 24 ? val | 0xFF000000 : val);
      } catch (_) {}
    }

    final fillPaint = Paint()
      ..color = nodeBgColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, fillPaint);

    // Stroke
    final strokePaint = Paint()
      ..color = onSurfaceColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, strokePaint);

    // Initial state arrow
    if (state.isInitial) {
      final arrowPaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      
      final startPoint = Offset(center.dx - radius - 20, center.dy);
      final endPoint = Offset(center.dx - radius - 2, center.dy);
      canvas.drawLine(startPoint, endPoint, arrowPaint);

      // Arrow head
      final arrowHeadPaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.fill;
      final tipArrow = Path()
        ..moveTo(endPoint.dx + 2, endPoint.dy)
        ..lineTo(endPoint.dx - 6, endPoint.dy - 5)
        ..lineTo(endPoint.dx - 6, endPoint.dy + 5)
        ..close();
      canvas.drawPath(tipArrow, arrowHeadPaint);
    }

    // Final state: double circle
    if (state.isFinal) {
      final innerStrokePaint = Paint()
        ..color = onSurfaceColor.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, radius - 6, innerStrokePaint);
    }

    // Display text with adaptive font size
    final displayText = (showOutput && state.output.isNotEmpty)
        ? '${state.label}/${state.output}'
        : state.label;

    final fontSize = min(
      14.0,
      radius * 1.6 / max(displayText.length * 0.65, 1),
    ).clamp(8.0, 14.0);

    final textPainter = TextPainter(
      text: TextSpan(
        text: displayText,
        style: TextStyle(
          color: onSurfaceColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: radius * 1.8);
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant StateNodePainter oldDelegate) =>
      oldDelegate.state.label != state.label ||
      oldDelegate.state.isInitial != state.isInitial ||
      oldDelegate.state.isFinal != state.isFinal ||
      oldDelegate.state.output != state.output ||
      oldDelegate.state.color != state.color ||
      oldDelegate.showOutput != showOutput ||
      oldDelegate.radius != radius ||
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.surfaceColor != surfaceColor ||
      oldDelegate.onSurfaceColor != onSurfaceColor;
}
