import 'package:flutter/material.dart';

import '../../models/calculators/excavation_calculation.dart';

class ExcavationSketchWidget extends StatelessWidget {
  final ExcavationInput input;
  final ExcavationResult result;

  const ExcavationSketchWidget({
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
          painter: _ExcavationPainter(
            input: input,
            result: result,
            isDark: isDark,
          ),
        ),
      ),
    );
  }
}

class _ExcavationPainter extends CustomPainter {
  final ExcavationInput input;
  final ExcavationResult result;
  final bool isDark;

  _ExcavationPainter({
    required this.input,
    required this.result,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!result.isValid) return;

    final soilColor = isDark
        ? const Color(0xFF3E2723)
        : const Color(0xFFD7CCC8);
    final backfillColor = isDark
        ? const Color(0xFF5D4037)
        : const Color(0xFFBCAAA4);
    final concreteColor = isDark
        ? const Color(0xFF475569)
        : const Color(0xFF94A3B8);
    final strokeColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF334155);
    final accentColor = const Color(0xFFFF8C00);
    final textColor = isDark ? Colors.white70 : const Color(0xFF1E293B);

    const padLeft = 40.0;
    const padRight = 50.0;
    const padTop = 38.0;
    const padBottom = 38.0;

    final drawWidth = size.width - padLeft - padRight;
    final drawHeight = size.height - padTop - padBottom;

    final groundY = padTop + (drawHeight * 0.15);
    final pitBottomY = groundY + (drawHeight * 0.70);

    final pitLeft = padLeft + (drawWidth * 0.18);
    final pitRight = size.width - padRight - (drawWidth * 0.18);
    final pitWidth = pitRight - pitLeft;

    // Ground surface line (NGL)
    final groundPaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 2.0;

    canvas.drawLine(
      Offset(padLeft - 15, groundY),
      Offset(pitLeft, groundY),
      groundPaint,
    );
    canvas.drawLine(
      Offset(pitRight, groundY),
      Offset(size.width - padRight + 20, groundY),
      groundPaint,
    );

    // Natural ground hatching on the left & right
    final hatchPaint = Paint()
      ..color = strokeColor.withValues(alpha: 0.4)
      ..strokeWidth = 1.0;
    for (double x = padLeft - 10; x < pitLeft - 5; x += 10) {
      canvas.drawLine(
        Offset(x, groundY),
        Offset(x - 6, groundY + 10),
        hatchPaint,
      );
    }
    for (double x = pitRight + 8; x < size.width - padRight + 15; x += 10) {
      canvas.drawLine(
        Offset(x, groundY),
        Offset(x - 6, groundY + 10),
        hatchPaint,
      );
    }

    _drawText(
      canvas,
      'NGL',
      Offset(padLeft + 4, groundY - 10),
      textColor,
      fontSize: 10,
      isBold: true,
    );

    // Trench / Pit excavated contour
    final pitRect = Rect.fromLTRB(pitLeft, groundY, pitRight, pitBottomY);
    final pitPaint = Paint()..color = soilColor;
    canvas.drawRect(pitRect, pitPaint);

    final borderPaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(pitRect, borderPaint);

    // Inner concrete foundation block
    final workingSpaceRatio = input.workingSpace > 0
        ? (input.workingSpace / (input.width + (2 * input.workingSpace))).clamp(
            0.08,
            0.25,
          )
        : 0.12;

    final wsWidthPx = pitWidth * workingSpaceRatio;
    final footingLeft = pitLeft + wsWidthPx;
    final footingRight = pitRight - wsWidthPx;
    final footingHeightPx = (pitBottomY - groundY) * 0.45;
    final footingTop = pitBottomY - footingHeightPx;

    // Backfill zones on the sides
    final leftBackfill = Rect.fromLTRB(
      pitLeft,
      footingTop,
      footingLeft,
      pitBottomY,
    );
    final rightBackfill = Rect.fromLTRB(
      footingRight,
      footingTop,
      pitRight,
      pitBottomY,
    );
    final backfillPaint = Paint()..color = backfillColor;
    canvas.drawRect(leftBackfill, backfillPaint);
    canvas.drawRect(rightBackfill, backfillPaint);

    // Draw concrete footing
    final footingRect = Rect.fromLTRB(
      footingLeft,
      footingTop,
      footingRight,
      pitBottomY,
    );
    final concretePaint = Paint()..color = concreteColor;
    canvas.drawRect(footingRect, concretePaint);
    canvas.drawRect(footingRect, borderPaint);

    // Column stem rising up from footing
    final colW = (footingRight - footingLeft) * 0.35;
    final colLeft = ((footingLeft + footingRight) / 2) - (colW / 2);
    final colRight = colLeft + colW;
    final colRect = Rect.fromLTRB(colLeft, groundY - 6, colRight, footingTop);
    canvas.drawRect(colRect, concretePaint);
    canvas.drawRect(colRect, borderPaint);

    // Text labels on structure
    _drawText(
      canvas,
      'Footing',
      Offset(
        (footingLeft + footingRight) / 2,
        footingTop + (footingHeightPx / 2),
      ),
      Colors.white,
      fontSize: 10,
      isBold: true,
    );
    _drawText(
      canvas,
      'Backfill',
      Offset(pitLeft + (wsWidthPx / 2), footingTop + (footingHeightPx / 2)),
      textColor,
      fontSize: 8,
    );
    _drawText(
      canvas,
      'Backfill',
      Offset(pitRight - (wsWidthPx / 2), footingTop + (footingHeightPx / 2)),
      textColor,
      fontSize: 8,
    );

    // Dimension: Depth D on right
    final dimDepthX = pitRight + 14.0;
    final dimPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(dimDepthX, groundY),
      Offset(dimDepthX, pitBottomY),
      dimPaint,
    );
    _drawArrow(
      canvas,
      Offset(dimDepthX, groundY),
      const Offset(0, 1),
      dimPaint,
    );
    _drawArrow(
      canvas,
      Offset(dimDepthX, pitBottomY),
      const Offset(0, -1),
      dimPaint,
    );
    _drawText(
      canvas,
      'D = ${input.depth.toStringAsFixed(2)}m',
      Offset(dimDepthX + 6, (groundY + pitBottomY) / 2),
      textColor,
      fontSize: 10,
    );

    // Dimension: Width at bottom
    final dimWidthY = pitBottomY + 14.0;
    canvas.drawLine(
      Offset(pitLeft, dimWidthY),
      Offset(pitRight, dimWidthY),
      dimPaint,
    );
    _drawArrow(
      canvas,
      Offset(pitLeft, dimWidthY),
      const Offset(1, 0),
      dimPaint,
    );
    _drawArrow(
      canvas,
      Offset(pitRight, dimWidthY),
      const Offset(-1, 0),
      dimPaint,
    );
    _drawText(
      canvas,
      'Total Width = ${result.effectiveWidthMeters.toStringAsFixed(2)}m',
      Offset((pitLeft + pitRight) / 2, dimWidthY + 8),
      textColor,
      fontSize: 10,
    );

    // Dimension: Working space offset annotation
    _drawText(
      canvas,
      'Space: +${input.workingSpace.toStringAsFixed(2)}m',
      Offset(pitLeft + (wsWidthPx / 2), groundY + 12),
      accentColor,
      fontSize: 9,
      isBold: true,
    );
  }

  void _drawArrow(Canvas canvas, Offset tip, Offset dir, Paint paint) {
    const arrowSize = 4.5;
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
  bool shouldRepaint(covariant _ExcavationPainter oldDelegate) {
    return oldDelegate.input != input ||
        oldDelegate.result != result ||
        oldDelegate.isDark != isDark;
  }
}
