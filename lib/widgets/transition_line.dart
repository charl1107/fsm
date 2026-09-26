import 'dart:math';
import 'package:flutter/material.dart';
import '../models/fsm_state.dart' as fsm_model;
import '../models/transition.dart' as t_model;

class TransitionLine extends StatelessWidget {
  final fsm_model.FSMState from;
  final fsm_model.FSMState to;
  final String label;
  final String output;
  final bool isSelfLoop;
  final bool isMealy;
  final bool isMoore;
  final bool isBidirectional;
  final int index;
  final int totalCount;
  final List<fsm_model.FSMState> allStates;
  final List<t_model.Transition> allTransitions;
  final String transitionId;

  const TransitionLine({
    super.key,
    required this.from,
    required this.to,
    required this.label,
    this.output = '',
    this.isSelfLoop = false,
    this.isMealy = true,
    this.isMoore = false,
    this.isBidirectional = false,
    this.index = 0,
    this.totalCount = 1,
    this.allStates = const [],
    this.allTransitions = const [],
    this.transitionId = '',
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: TransitionLinePainter(
        from: from,
        to: to,
        label: label,
        output: output,
        isSelfLoop: isSelfLoop,
        isMealy: isMealy,
        isMoore: isMoore,
        isBidirectional: isBidirectional,
        index: index,
        totalCount: totalCount,
        allStates: allStates,
        allTransitions: allTransitions,
        transitionId: transitionId,
        lineColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        labelTextColor: Theme.of(context).colorScheme.onSurface,
        labelBackgroundColor: Theme.of(context).colorScheme.surface,
      ),
      size: Size.infinite,
    );
  }
}

class TransitionLinePainter extends CustomPainter {
  final fsm_model.FSMState from;
  final fsm_model.FSMState to;
  final String label;
  final String output;
  final bool isSelfLoop;
  final bool isMealy;
  final bool isMoore;
  final bool isBidirectional;
  final int index;
  final int totalCount;
  final List<fsm_model.FSMState> allStates;
  final List<t_model.Transition> allTransitions;
  final String transitionId;
  final Color lineColor;
  final Color labelTextColor;
  final Color labelBackgroundColor;

  TransitionLinePainter({
    required this.from,
    required this.to,
    required this.label,
    this.output = '',
    this.isSelfLoop = false,
    this.isMealy = true,
    this.isMoore = false,
    this.isBidirectional = false,
    this.index = 0,
    this.totalCount = 1,
    this.allStates = const [],
    this.allTransitions = const [],
    this.transitionId = '',
    required this.lineColor,
    required this.labelTextColor,
    required this.labelBackgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (isSelfLoop) {
      _drawSelfLoop(canvas);
    } else {
      _drawTransition(canvas);
    }
  }

  void _drawSelfLoop(Canvas canvas) {
    final center = Offset(from.x, from.y);
    const radius = 30.0;
    const loopRadius = 22.0;
    const loopOffset = radius + loopRadius + 4;

    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final loopCenter = Offset(center.dx, center.dy - loopOffset);

    // Draw circular loop
    canvas.drawCircle(loopCenter, loopRadius, paint);

    // Arrow pointing down into top of state circle
    final arrowAngle = pi / 2;
    final arrowPoint = Offset(
      loopCenter.dx + loopRadius * cos(arrowAngle),
      loopCenter.dy + loopRadius * sin(arrowAngle),
    );
    _drawArrowHead(canvas, arrowPoint, arrowAngle);

    // Label on loop
    final labelText = isMealy && output.isNotEmpty ? '$label/$output' : label;
    _drawBadgeText(
      canvas,
      labelText,
      Offset(loopCenter.dx, loopCenter.dy - loopRadius - 8),
    );
  }

  /// Check if a straight line from [a] to [b] passes within [threshold] of any
  /// state that is not the source or destination.
  bool _linePassesThroughState(Offset a, Offset b, {double threshold = 38.0}) {
    for (final state in allStates) {
      if (state.id == from.id || state.id == to.id) continue;
      final statePos = Offset(state.x, state.y);
      final dist = _pointToSegmentDistance(statePos, a, b);
      if (dist < threshold) return true;
    }
    return false;
  }

  /// Perpendicular distance from point [p] to line segment [a]-[b].
  double _pointToSegmentDistance(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final ap = p - a;
    final abLenSq = ab.dx * ab.dx + ab.dy * ab.dy;
    if (abLenSq == 0) return (p - a).distance;
    final t = ((ap.dx * ab.dx + ap.dy * ab.dy) / abLenSq).clamp(0.0, 1.0);
    final projection = Offset(a.dx + t * ab.dx, a.dy + t * ab.dy);
    return (p - projection).distance;
  }

  /// Check if the straight line or the default "above" arc is blocked by
  /// a self-loop on the endpoints or any intermediate state's self loop.
  bool _isAboveBlocked(Offset fromCenter, Offset toCenter) {
    // 1. Endpoints have self-loops?
    for (final t in allTransitions) {
      if (t.fromStateId == t.toStateId) {
        if (t.fromStateId == from.id || t.fromStateId == to.id) {
          return true;
        }
      }
    }

    // 2. Any intermediate state between from and to that has a self-loop above it?
    final minX = min(fromCenter.dx, toCenter.dx);
    final maxX = max(fromCenter.dx, toCenter.dx);
    for (final state in allStates) {
      if (state.id == from.id || state.id == to.id) continue;
      if (state.x >= minX - 10 && state.x <= maxX + 10) {
        final hasSelfLoop = allTransitions.any((t) => t.fromStateId == state.id && t.toStateId == state.id);
        if (hasSelfLoop) return true;
      }
    }

    return false;
  }

  void _drawTransition(Canvas canvas) {
    final fromCenter = Offset(from.x, from.y);
    final toCenter = Offset(to.x, to.y);

    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final angle = atan2(toCenter.dy - fromCenter.dy, toCenter.dx - fromCenter.dx);
    const radius = 30.0;

    final labelText = isMealy && output.isNotEmpty ? '$label/$output' : label;

    final fromEdge = Offset(fromCenter.dx + cos(angle) * radius, fromCenter.dy + sin(angle) * radius);
    final toEdge = Offset(toCenter.dx - cos(angle) * radius, toCenter.dy - sin(angle) * radius);

    // Determine if we need a curve:
    // - multiple transitions between the same states (totalCount > 1)
    // - bidirectional pair (A->B and B->A)
    // - straight line passes through an intermediate state
    final passesThroughState = _linePassesThroughState(fromCenter, toCenter);
    final needsCurve = isBidirectional || totalCount > 1 || passesThroughState;

    if (needsCurve) {
      final midX = (fromEdge.dx + toEdge.dx) / 2;
      final midY = (fromEdge.dy + toEdge.dy) / 2;
      final dist = (toEdge - fromEdge).distance;

      // Base perpendicular vector (points towards negative Y if left-to-right, positive Y if right-to-left)
      final rawPerp = angle - pi / 2;
      // In Flutter screen coordinates, negative Y is UP.
      final pointsUpward = sin(rawPerp) < 0;
      final upwardPerp = pointsUpward ? rawPerp : (rawPerp + pi);
      final downwardPerp = upwardPerp + pi;

      double chosenPerp;
      double curvature;

      if (isBidirectional) {
        // Natural separation for bidirectional (one above, one below)
        chosenPerp = rawPerp;
        curvature = (dist * 0.35 + index * 24.0).clamp(35.0, 110.0);
      } else if (totalCount > 1) {
        // Multiple transitions between the SAME from/to pair!
        // Alternate them: first goes above (or below if above blocked), next goes opposite side,
        // or nest with increasing curvature.
        final aboveBlocked = _isAboveBlocked(fromCenter, toCenter);
        final bool goAbove;

        if (totalCount == 2) {
          // If 2 transitions: index 0 goes on preferred side, index 1 goes on the other side!
          if (aboveBlocked) {
            goAbove = (index % 2 == 1);
          } else {
            goAbove = (index % 2 == 0);
          }
        } else {
          // If more than 2 transitions, distribute between above and below with increasing arc
          if (aboveBlocked) {
            goAbove = (index % 2 == 1);
          } else {
            goAbove = (index % 2 == 0);
          }
        }

        chosenPerp = goAbove ? upwardPerp : downwardPerp;
        final tier = index ~/ 2;
        curvature = (dist * 0.30 + 30.0 + tier * 32.0).clamp(40.0, 150.0);
      } else {
        // Single transition that passes through an intermediate state (e.g. C -> A over B)
        final aboveBlocked = _isAboveBlocked(fromCenter, toCenter);
        chosenPerp = aboveBlocked ? downwardPerp : upwardPerp;
        curvature = (dist * 0.32).clamp(35.0, 95.0);
      }

      final controlPoint = Offset(
        midX + cos(chosenPerp) * curvature,
        midY + sin(chosenPerp) * curvature,
      );

      final path = Path()
        ..moveTo(fromEdge.dx, fromEdge.dy)
        ..quadraticBezierTo(controlPoint.dx, controlPoint.dy, toEdge.dx, toEdge.dy);
      canvas.drawPath(path, paint);

      final arrowAngle = atan2(toEdge.dy - controlPoint.dy, toEdge.dx - controlPoint.dx);
      _drawArrowHead(canvas, toEdge, arrowAngle);

      // Place badge at the peak of the curve
      final labelPos = Offset(
        controlPoint.dx + cos(chosenPerp) * 10,
        controlPoint.dy + sin(chosenPerp) * 10,
      );
      _drawBadgeText(canvas, labelText, labelPos);
    } else {
      // Straight transition
      canvas.drawLine(fromEdge, toEdge, paint);
      _drawArrowHead(canvas, toEdge, angle);

      // Label at midpoint
      final midPoint = Offset((fromEdge.dx + toEdge.dx) / 2, (fromEdge.dy + toEdge.dy) / 2);
      final perpAngle = angle + pi / 2;
      final labelPos = Offset(
        midPoint.dx + cos(perpAngle) * 14,
        midPoint.dy + sin(perpAngle) * 14,
      );
      _drawBadgeText(canvas, labelText, labelPos);
    }
  }

  void _drawArrowHead(Canvas canvas, Offset tip, double angle) {
    const arrowSize = 11.0;
    final p1 = Offset(
      tip.dx - arrowSize * cos(angle - pi / 6),
      tip.dy - arrowSize * sin(angle - pi / 6),
    );
    final p2 = Offset(
      tip.dx - arrowSize * cos(angle + pi / 6),
      tip.dy - arrowSize * sin(angle + pi / 6),
    );

    final arrowPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();

    final fillPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(arrowPath, fillPaint);
  }

  void _drawBadgeText(Canvas canvas, String text, Offset center) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: labelTextColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: textPainter.width + 12,
        height: textPainter.height + 6,
      ),
      const Radius.circular(6),
    );

    // Badge background with subtle border
    final borderPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(badgeRect, borderPaint);

    final bgPaint = Paint()
      ..color = labelBackgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(badgeRect, bgPaint);

    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant TransitionLinePainter oldDelegate) =>
      oldDelegate.from.x != from.x ||
      oldDelegate.from.y != from.y ||
      oldDelegate.to.x != to.x ||
      oldDelegate.to.y != to.y ||
      oldDelegate.label != label ||
      oldDelegate.output != output ||
      oldDelegate.isSelfLoop != isSelfLoop ||
      oldDelegate.isMealy != isMealy ||
      oldDelegate.isMoore != isMoore ||
      oldDelegate.isBidirectional != isBidirectional ||
      oldDelegate.index != index ||
      oldDelegate.totalCount != totalCount ||
      oldDelegate.lineColor != lineColor;
}
