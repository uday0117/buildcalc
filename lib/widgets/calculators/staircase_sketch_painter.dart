import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../models/calculators/staircase_calculation.dart';

class StaircaseSketchWidget extends StatelessWidget {
  final StaircaseInput input;
  final StaircaseResult result;

  const StaircaseSketchWidget({
    super.key,
    required this.input,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 220,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CustomPaint(
          size: Size.infinite,
          painter: _StaircasePainter(
            input: input,
            result: result,
            isDark: isDark,
          ),
        ),
      ),
    );
  }
}

class _StaircasePainter extends CustomPainter {
  final StaircaseInput input;
  final StaircaseResult result;
  final bool isDark;

  _StaircasePainter({
    required this.input,
    required this.result,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!result.isValid || result.totalRisers <= 0) return;

    final concreteColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFCBD5E1);
    final strokeColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF475569);
    final accentColor = const Color(0xFFFF8C00);
    final textColor = isDark ? Colors.white70 : const Color(0xFF1E293B);

    final fillPaint = Paint()
      ..color = concreteColor
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final dimPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Drawing area bounds with padding
    const padLeft = 45.0;
    const padRight = 55.0;
    const padTop = 30.0;
    const padBottom = 40.0;

    final drawWidth = size.width - padLeft - padRight;
    final drawHeight = size.height - padTop - padBottom;

    final stepCount = math.min(
      result.totalTreads,
      8,
    ); // draw 4 to 8 representative steps
    final stepW = (drawWidth * 0.65) / stepCount;
    final stepH = drawHeight / (stepCount + 1);

    final startX = padLeft;
    final startY = size.height - padBottom;

    // 1. Build the stepped staircase profile
    final stepPath = Path();
    stepPath.moveTo(startX, startY);

    var curX = startX;
    var curY = startY;

    for (int i = 0; i < stepCount; i++) {
      curY -= stepH;
      stepPath.lineTo(curX, curY); // Rise
      curX += stepW;
      stepPath.lineTo(curX, curY); // Tread
    }

    // Top landing extension
    final landingEndX = curX + (drawWidth * 0.25);
    stepPath.lineTo(landingEndX, curY);

    // Landing thickness
    final slabThickness = math.max(12.0, drawHeight * 0.12);
    stepPath.lineTo(landingEndX, curY + slabThickness);

    // Waist slab underside back to start
    final waistBottomX = startX + (drawWidth * 0.12);
    final waistBottomY = startY;
    stepPath.lineTo(curX, curY + slabThickness + (drawHeight * 0.08));
    stepPath.lineTo(waistBottomX, waistBottomY);
    stepPath.lineTo(startX, startY);
    stepPath.close();

    // Draw solid concrete staircase
    canvas.drawPath(stepPath, fillPaint);
    canvas.drawPath(stepPath, linePaint);

    // Ground line
    final groundPaint = Paint()
      ..color = isDark ? Colors.white24 : Colors.grey.shade400
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(15, startY),
      Offset(startX + drawWidth * 0.35, startY),
      groundPaint,
    );

    // Dimension: Total Height H on the right
    final dimX = landingEndX + 16.0;
    canvas.drawLine(Offset(dimX, startY), Offset(dimX, curY), dimPaint);
    _drawArrow(canvas, Offset(dimX, startY), const Offset(0, -1), dimPaint);
    _drawArrow(canvas, Offset(dimX, curY), const Offset(0, 1), dimPaint);
    _drawText(
      canvas,
      'H = ${input.totalHeight.toStringAsFixed(2)}m',
      Offset(dimX + 4, (startY + curY) / 2),
      textColor,
      isVertical: false,
    );

    // Dimension: Total Going at bottom
    final dimY = startY + 18.0;
    canvas.drawLine(Offset(startX, dimY), Offset(curX, dimY), dimPaint);
    _drawArrow(canvas, Offset(startX, dimY), const Offset(1, 0), dimPaint);
    _drawArrow(canvas, Offset(curX, dimY), const Offset(-1, 0), dimPaint);
    _drawText(
      canvas,
      'Run = ${result.totalGoingMeters.toStringAsFixed(2)}m',
      Offset((startX + curX) / 2, dimY + 8),
      textColor,
    );

    // Annotations: Riser, Tread, Angle
    final firstStepX = startX + stepW;
    final firstStepY = startY - stepH;
    _drawText(
      canvas,
      'R: ${result.actualRiserMm.toStringAsFixed(0)}mm',
      Offset(startX - 18, startY - (stepH / 2)),
      accentColor,
      fontSize: 10,
    );
    _drawText(
      canvas,
      'T: ${result.actualTreadMm.toStringAsFixed(0)}mm',
      Offset(firstStepX - (stepW / 2), firstStepY - 14),
      accentColor,
      fontSize: 10,
    );

    // Angle indicator
    _drawText(
      canvas,
      'θ = ${result.pitchAngleDegrees.toStringAsFixed(1)}°',
      Offset(startX + 28, startY - 16),
      accentColor,
      fontSize: 11,
      isBold: true,
    );
  }

  void _drawArrow(Canvas canvas, Offset tip, Offset dir, Paint paint) {
    const arrowSize = 5.0;
    final normal = Offset(-dir.dy, dir.dx);
    final p1 = tip + (dir * -arrowSize) + (normal * (arrowSize * 0.6));
    final p2 = tip + (dir * -arrowSize) - (normal * (arrowSize * 0.6));
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();
    canvas.drawPath(path, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke;
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset pos,
    Color color, {
    double fontSize = 11,
    bool isBold = false,
    bool isVertical = false,
  }) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
      ),
    );
    final tp = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(pos.dx - (tp.width / 2), pos.dy - (tp.height / 2)));
  }

  @override
  bool shouldRepaint(covariant _StaircasePainter oldDelegate) {
    return oldDelegate.input != input ||
        oldDelegate.result != result ||
        oldDelegate.isDark != isDark;
  }
}
