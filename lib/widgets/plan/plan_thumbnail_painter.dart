import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../models/plan/plan_models.dart';

/// Renders a structured 2D blueprint thumbnail of a [FloorPlan] from its geometry data.
class PlanThumbnail extends StatelessWidget {
  final FloorPlan plan;
  final double? frontSetbackFeet;
  final double? rearSetbackFeet;
  final double? sideSetbackFeet;
  final String? orientation;
  final bool showLabels;
  final bool isInteractive;

  const PlanThumbnail({
    super.key,
    required this.plan,
    this.frontSetbackFeet,
    this.rearSetbackFeet,
    this.sideSetbackFeet,
    this.orientation,
    this.showLabels = true,
    this.isInteractive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        child: CustomPaint(
          painter: PlanThumbnailPainter(
            plan: plan,
            isDark: isDark,
            frontSetbackFeet: frontSetbackFeet,
            rearSetbackFeet: rearSetbackFeet,
            sideSetbackFeet: sideSetbackFeet,
            orientation: orientation,
            showLabels: showLabels,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class PlanThumbnailPainter extends CustomPainter {
  final FloorPlan plan;
  final bool isDark;
  final double? frontSetbackFeet;
  final double? rearSetbackFeet;
  final double? sideSetbackFeet;
  final String? orientation;
  final bool showLabels;

  PlanThumbnailPainter({
    required this.plan,
    required this.isDark,
    this.frontSetbackFeet,
    this.rearSetbackFeet,
    this.sideSetbackFeet,
    this.orientation,
    this.showLabels = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (plan.plotWidthFeet <= 0 || plan.plotLengthFeet <= 0) return;

    // Outer padding
    const padding = 16.0;
    final availW = size.width - (padding * 2);
    final availH = size.height - (padding * 2);

    final scaleX = availW / plan.plotWidthFeet;
    final scaleY = availH / plan.plotLengthFeet;
    final scale = math.min(scaleX, scaleY);

    final plotPixelW = plan.plotWidthFeet * scale;
    final plotPixelH = plan.plotLengthFeet * scale;

    final originX = (size.width - plotPixelW) / 2;
    final originY = (size.height - plotPixelH) / 2;

    // 1. Draw subtle architectural grid in background
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : const Color(0xFF1E3A5F)).withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    const gridSpacing = 16.0;
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Draw Plot boundary
    final plotRect = Rect.fromLTWH(originX, originY, plotPixelW, plotPixelH);
    final plotPaint = Paint()
      ..color = (isDark ? Colors.white54 : const Color(0xFF64748B))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRect(plotRect, plotPaint);

    // Plot corner ticks
    final tickPaint = Paint()
      ..color = const Color(0xFFFF8C00)
      ..strokeWidth = 2.0;
    const tLen = 6.0;
    // Top-left
    canvas.drawLine(Offset(originX - 2, originY), Offset(originX + tLen, originY), tickPaint);
    canvas.drawLine(Offset(originX, originY - 2), Offset(originX, originY + tLen), tickPaint);
    // Top-right
    canvas.drawLine(Offset(originX + plotPixelW + 2, originY), Offset(originX + plotPixelW - tLen, originY), tickPaint);
    canvas.drawLine(Offset(originX + plotPixelW, originY - 2), Offset(originX + plotPixelW, originY + tLen), tickPaint);
    // Bottom-left
    canvas.drawLine(Offset(originX - 2, originY + plotPixelH), Offset(originX + tLen, originY + plotPixelH), tickPaint);
    canvas.drawLine(Offset(originX, originY + plotPixelH + 2), Offset(originX, originY + plotPixelH - tLen), tickPaint);
    // Bottom-right
    canvas.drawLine(Offset(originX + plotPixelW + 2, originY + plotPixelH), Offset(originX + plotPixelW - tLen, originY + plotPixelH), tickPaint);
    canvas.drawLine(Offset(originX + plotPixelW, originY + plotPixelH + 2), Offset(originX + plotPixelW, originY + plotPixelH - tLen), tickPaint);

    // 3. Draw Setback envelope if specified
    if (sideSetbackFeet != null && frontSetbackFeet != null && rearSetbackFeet != null) {
      final sbLeft = originX + (sideSetbackFeet! * scale);
      final sbTop = originY + (frontSetbackFeet! * scale);
      final sbWidth = (plan.plotWidthFeet - (sideSetbackFeet! * 2)) * scale;
      final sbHeight = (plan.plotLengthFeet - (frontSetbackFeet! + rearSetbackFeet!)) * scale;

      if (sbWidth > 0 && sbHeight > 0) {
        final sbRect = Rect.fromLTWH(sbLeft, sbTop, sbWidth, sbHeight);
        final sbPaint = Paint()
          ..color = const Color(0xFF10B981).withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

        _drawDashedRect(canvas, sbRect, sbPaint, 4.0, 3.0);
      }
    }

    // 4. Draw Rooms
    final wallPaint = Paint()
      ..color = (isDark ? Colors.white.withValues(alpha: 0.87) : const Color(0xFF1E293B))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    for (final room in plan.rooms) {
      final rx = originX + (room.x * scale);
      final ry = originY + (room.y * scale);
      final rw = room.width * scale;
      final rl = room.length * scale;
      final roomRect = Rect.fromLTWH(rx, ry, rw, rl);

      // Fill room
      final fillPaint = Paint()
        ..color = Color(room.colorValue).withValues(alpha: isDark ? 0.35 : 0.45)
        ..style = PaintingStyle.fill;
      canvas.drawRect(roomRect, fillPaint);

      // Draw Room Walls
      canvas.drawRect(roomRect, wallPaint);

      // Draw Openings
      for (final op in room.openings) {
        _drawOpening(canvas, op, rx, ry, rw, rl, scale);
      }

      // Room Text Label
      if (showLabels && rw > 28 && rl > 18) {
        final textStyle = TextStyle(
          color: isDark ? Colors.white70 : const Color(0xFF0F172A),
          fontSize: math.max(7.5, math.min(10.0, rw * 0.14)),
          fontWeight: FontWeight.w600,
        );

        final textSpan = TextSpan(
          text: room.name.length > 12 ? '${room.name.substring(0, 10)}..' : room.name,
          style: textStyle,
        );
        final tp = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout(maxWidth: rw - 4);

        if (tp.width <= rw - 2 && tp.height <= rl - 2) {
          tp.paint(
            canvas,
            Offset(rx + (rw - tp.width) / 2, ry + (rl - tp.height) / 2),
          );
        }
      }
    }

    // 5. Draw Compass Rose / Orientation indicator
    _drawCompass(canvas, size);
  }

  void _drawOpening(
    Canvas canvas,
    PlanOpening op,
    double rx,
    double ry,
    double rw,
    double rl,
    double scale,
  ) {
    final opOffset = op.offsetFeet * scale;
    final opWidth = op.widthFeet * scale;

    final openingPaint = Paint()
      ..color = op.type.isDoor ? const Color(0xFFFF8C00) : const Color(0xFF0284C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    double x1 = rx;
    double y1 = ry;
    double x2 = rx;
    double y2 = ry;

    switch (op.wallSide) {
      case PlanWallSide.north:
        x1 = rx + opOffset;
        y1 = ry;
        x2 = x1 + opWidth;
        y2 = ry;
        break;
      case PlanWallSide.south:
        x1 = rx + opOffset;
        y1 = ry + rl;
        x2 = x1 + opWidth;
        y2 = ry + rl;
        break;
      case PlanWallSide.west:
        x1 = rx;
        y1 = ry + opOffset;
        x2 = rx;
        y2 = y1 + opWidth;
        break;
      case PlanWallSide.east:
        x1 = rx + rw;
        y1 = ry + opOffset;
        x2 = rx + rw;
        y2 = y1 + opWidth;
        break;
    }

    // Clear opening wall gap by drawing line with accent color
    canvas.drawLine(Offset(x1, y1), Offset(x2, y2), openingPaint);
  }

  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint, double dashW, double gapW) {
    // Top
    _drawDashedLine(canvas, rect.topLeft, rect.topRight, paint, dashW, gapW);
    // Right
    _drawDashedLine(canvas, rect.topRight, rect.bottomRight, paint, dashW, gapW);
    // Bottom
    _drawDashedLine(canvas, rect.bottomRight, rect.bottomLeft, paint, dashW, gapW);
    // Left
    _drawDashedLine(canvas, rect.bottomLeft, rect.topLeft, paint, dashW, gapW);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint, double dash, double gap) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final totalLen = math.sqrt(dx * dx + dy * dy);
    if (totalLen <= 0) return;

    final unitX = dx / totalLen;
    final unitY = dy / totalLen;

    double current = 0.0;
    while (current < totalLen) {
      final start = Offset(p1.dx + unitX * current, p1.dy + unitY * current);
      final step = math.min(dash, totalLen - current);
      final end = Offset(start.dx + unitX * step, start.dy + unitY * step);
      canvas.drawLine(start, end, paint);
      current += dash + gap;
    }
  }

  void _drawCompass(Canvas canvas, Size size) {
    final cx = size.width - 20.0;
    final cy = 20.0;

    // Small compass circle
    final bgPaint = Paint()
      ..color = (isDark ? Colors.black54 : Colors.white).withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 12.0, bgPaint);

    final borderPaint = Paint()
      ..color = (isDark ? Colors.white30 : Colors.black26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(Offset(cx, cy), 12.0, borderPaint);

    // North arrow
    final arrowPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(cx, cy - 9.0)
      ..lineTo(cx - 3.5, cy + 1.0)
      ..lineTo(cx + 3.5, cy + 1.0)
      ..close();
    canvas.drawPath(path, arrowPaint);

    // N letter
    final tp = TextPainter(
      text: const TextSpan(
        text: 'N',
        style: TextStyle(
          color: Color(0xFFEF4444),
          fontSize: 7.5,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - (tp.width / 2), cy + 2.0));
  }

  @override
  bool shouldRepaint(covariant PlanThumbnailPainter oldDelegate) {
    return oldDelegate.plan != plan ||
        oldDelegate.isDark != isDark ||
        oldDelegate.frontSetbackFeet != frontSetbackFeet;
  }
}
