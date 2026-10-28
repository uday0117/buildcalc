import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../models/plan/plan_geometry.dart';
import '../../models/plan/plan_models.dart';
import '../../models/plan/plan_unit.dart';

class PlanCanvasPainter extends CustomPainter {
  final FloorPlan plan;
  final String? selectedRoomId;
  final String? selectedOpeningId;
  final ResizeHandle activeHandle;
  final bool showGrid;
  final PlanUnit unit;
  final bool isDark;
  final double scale; // Screen pixels per foot

  PlanCanvasPainter({
    required this.plan,
    required this.selectedRoomId,
    required this.selectedOpeningId,
    this.activeHandle = ResizeHandle.none,
    this.showGrid = true,
    required this.unit,
    required this.isDark,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Grid
    if (showGrid) {
      _drawGrid(canvas, size);
    }

    // 2. Plot Boundary & Dimensions
    _drawPlotBoundary(canvas, size);

    // 3. Room Floor Fills & Labels
    _drawRooms(canvas);

    // 4. Architectural Walls
    _drawWalls(canvas);

    // 5. Doors & Windows
    _drawOpenings(canvas);

    // 6. Selected Room Highlights & Resize Handles
    _drawSelectionHighlights(canvas);

    // 7. North Arrow & Scale Bar
    _drawNorthArrowAndScale(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final minorPaint = Paint()
      ..color = (isDark ? Colors.white : const Color(0xFF1E3A5F)).withValues(
        alpha: 0.05,
      )
      ..strokeWidth = 1.0;

    final majorPaint = Paint()
      ..color = (isDark ? Colors.white : const Color(0xFF1E3A5F)).withValues(
        alpha: 0.12,
      )
      ..strokeWidth = 1.2;

    // Minor grid every 1 ft, Major grid every 5 ft
    final stepFeet = 1.0;
    final majorStepFeet = 5.0;

    final maxPlotW = plan.plotWidthFeet * scale;
    final maxPlotL = plan.plotLengthFeet * scale;

    // Vertical lines
    for (double f = 0; f <= plan.plotWidthFeet + 0.1; f += stepFeet) {
      final x = f * scale;
      final isMajor = (f % majorStepFeet).abs() < 0.01;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, maxPlotL),
        isMajor ? majorPaint : minorPaint,
      );
    }

    // Horizontal lines
    for (double f = 0; f <= plan.plotLengthFeet + 0.1; f += stepFeet) {
      final y = f * scale;
      final isMajor = (f % majorStepFeet).abs() < 0.01;
      canvas.drawLine(
        Offset(0, y),
        Offset(maxPlotW, y),
        isMajor ? majorPaint : minorPaint,
      );
    }
  }

  void _drawPlotBoundary(Canvas canvas, Size size) {
    final plotW = plan.plotWidthFeet * scale;
    final plotL = plan.plotLengthFeet * scale;
    final plotRect = Rect.fromLTWH(0, 0, plotW, plotL);

    // Plot ground fill
    final groundPaint = Paint()
      ..color = isDark ? const Color(0xFF0F172A) : const Color(0xFFFBFDFF)
      ..style = PaintingStyle.fill;
    canvas.drawRect(plotRect, groundPaint);

    // Setback guide line (3ft from boundary)
    final setbackFeet = 2.0;
    if (plan.plotWidthFeet > setbackFeet * 3 &&
        plan.plotLengthFeet > setbackFeet * 3) {
      final setbackRect = Rect.fromLTWH(
        setbackFeet * scale,
        setbackFeet * scale,
        (plan.plotWidthFeet - setbackFeet * 2) * scale,
        (plan.plotLengthFeet - setbackFeet * 2) * scale,
      );

      final setbackPaint = Paint()
        ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      _drawDashedRect(canvas, setbackRect, setbackPaint);
    }

    // Plot boundary line
    final borderPaint = Paint()
      ..color = isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E3A5F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRect(plotRect, borderPaint);

    // Corner boundary markers (L shapes)
    final markerPaint = Paint()
      ..color = const Color(0xFFFF8C00)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.square;

    final mLen = 12.0;
    // Top-left
    canvas.drawLine(Offset(0, 0), Offset(mLen, 0), markerPaint);
    canvas.drawLine(Offset(0, 0), Offset(0, mLen), markerPaint);
    // Top-right
    canvas.drawLine(Offset(plotW, 0), Offset(plotW - mLen, 0), markerPaint);
    canvas.drawLine(Offset(plotW, 0), Offset(plotW, mLen), markerPaint);
    // Bottom-left
    canvas.drawLine(Offset(0, plotL), Offset(mLen, plotL), markerPaint);
    canvas.drawLine(Offset(0, plotL), Offset(0, plotL - mLen), markerPaint);
    // Bottom-right
    canvas.drawLine(
      Offset(plotW, plotL),
      Offset(plotW - mLen, plotL),
      markerPaint,
    );
    canvas.drawLine(
      Offset(plotW, plotL),
      Offset(plotW, plotL - mLen),
      markerPaint,
    );

    // Plot width annotation (top)
    _drawDimensionLine(
      canvas,
      Offset(0, -14),
      Offset(plotW, -14),
      unit.formatLength(plan.plotWidthFeet),
      isDark ? Colors.white70 : const Color(0xFF1E3A5F),
    );

    // Plot length annotation (left)
    _drawDimensionLine(
      canvas,
      Offset(-14, 0),
      Offset(-14, plotL),
      unit.formatLength(plan.plotLengthFeet),
      isDark ? Colors.white70 : const Color(0xFF1E3A5F),
      isVertical: true,
    );
  }

  void _drawRooms(Canvas canvas) {
    for (final room in plan.rooms) {
      final r = Rect.fromLTWH(
        room.x * scale,
        room.y * scale,
        room.width * scale,
        room.length * scale,
      );

      // Floor Fill
      final fillPaint = Paint()
        ..color = Color(room.colorValue).withValues(alpha: isDark ? 0.28 : 0.45)
        ..style = PaintingStyle.fill;
      canvas.drawRect(r, fillPaint);

      // Room Center Label
      _drawRoomLabel(canvas, room, r);
    }
  }

  void _drawRoomLabel(Canvas canvas, PlanRoom room, Rect r) {
    if (r.width < 30 || r.height < 25) return;

    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white70 : const Color(0xFF475569);

    final nameSpan = TextSpan(
      text: room.name,
      style: TextStyle(
        color: textColor,
        fontSize: math.min(13.0, math.max(9.0, r.width / 14)),
        fontWeight: FontWeight.bold,
        letterSpacing: 0.2,
      ),
    );

    final dimText = unit.formatDimensions(room.width, room.length);
    final areaText = unit.formatArea(room.areaSqFt);

    final detailSpan = TextSpan(
      text: '\n$dimText\n$areaText',
      style: TextStyle(
        color: subColor,
        fontSize: math.min(11.0, math.max(8.0, r.width / 18)),
        fontWeight: FontWeight.w500,
        height: 1.25,
      ),
    );

    final fullSpan = TextSpan(
      children: [nameSpan, if (r.height >= 45 && r.width >= 50) detailSpan],
    );

    final tp = TextPainter(
      text: fullSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    tp.layout(maxWidth: r.width - 8);

    final pos = Offset(r.center.dx - tp.width / 2, r.center.dy - tp.height / 2);

    // Pill background for readability over grid/walls
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: r.center,
        width: tp.width + 10,
        height: tp.height + 6,
      ),
      const Radius.circular(6),
    );

    final labelBgPaint = Paint()
      ..color = (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(
        alpha: 0.88,
      )
      ..style = PaintingStyle.fill;
    canvas.drawRRect(bgRect, labelBgPaint);

    tp.paint(canvas, pos);
  }

  void _drawWalls(Canvas canvas) {
    // Draw thick architectural walls along room boundaries
    final wallPaint = Paint()
      ..color = isDark ? const Color(0xFF64748B) : const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math
          .max(2.5, 0.45 * scale) // ~5.5 inches scaled
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;

    for (final room in plan.rooms) {
      final r = Rect.fromLTWH(
        room.x * scale,
        room.y * scale,
        room.width * scale,
        room.length * scale,
      );
      canvas.drawRect(r, wallPaint);
    }
  }

  void _drawOpenings(Canvas canvas) {
    for (final room in plan.rooms) {
      for (final op in room.openings) {
        final isSelected = op.id == selectedOpeningId;
        if (op.type.isDoor) {
          _drawDoor(canvas, room, op, isSelected);
        } else {
          _drawWindow(canvas, room, op, isSelected);
        }
      }
    }
  }

  void _drawDoor(
    Canvas canvas,
    PlanRoom room,
    PlanOpening op,
    bool isSelected,
  ) {
    final r = Rect.fromLTWH(
      room.x * scale,
      room.y * scale,
      room.width * scale,
      room.length * scale,
    );

    final opOffset = op.offsetFeet * scale;
    final opW = op.widthFeet * scale;

    Offset hinge;
    Offset latch;
    double startAngle;
    double sweepAngle;

    final clearPaint = Paint()
      ..color = isDark ? const Color(0xFF0F172A) : const Color(0xFFFBFDFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(3.0, 0.5 * scale);

    final doorLinePaint = Paint()
      ..color = isSelected
          ? const Color(0xFFFF8C00)
          : (isDark ? Colors.amberAccent : const Color(0xFF8B4513))
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3.0 : 2.2;

    final arcPaint = Paint()
      ..color = isSelected
          ? const Color(0xFFFF8C00)
          : (isDark
                ? Colors.amber.withValues(alpha: 0.6)
                : const Color(0xFF8B4513).withValues(alpha: 0.6))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    switch (op.wallSide) {
      case PlanWallSide.north:
        hinge = Offset(r.left + opOffset, r.top);
        latch = Offset(hinge.dx + opW, hinge.dy);
        // Clear wall gap
        canvas.drawLine(hinge, latch, clearPaint);
        // Swing inward vs outward
        final swingY = op.swingInward ? (hinge.dy + opW) : (hinge.dy - opW);
        canvas.drawLine(hinge, Offset(hinge.dx, swingY), doorLinePaint);
        startAngle = op.swingInward ? 0 : -math.pi / 2;
        sweepAngle = op.swingInward ? math.pi / 2 : -math.pi / 2;
        canvas.drawArc(
          Rect.fromCircle(center: hinge, radius: opW),
          startAngle,
          sweepAngle,
          false,
          arcPaint,
        );
        break;

      case PlanWallSide.south:
        hinge = Offset(r.left + opOffset, r.bottom);
        latch = Offset(hinge.dx + opW, hinge.dy);
        canvas.drawLine(hinge, latch, clearPaint);
        final swingY = op.swingInward ? (hinge.dy - opW) : (hinge.dy + opW);
        canvas.drawLine(hinge, Offset(hinge.dx, swingY), doorLinePaint);
        startAngle = op.swingInward ? -math.pi / 2 : 0;
        sweepAngle = op.swingInward ? math.pi / 2 : -math.pi / 2;
        canvas.drawArc(
          Rect.fromCircle(center: hinge, radius: opW),
          startAngle,
          sweepAngle,
          false,
          arcPaint,
        );
        break;

      case PlanWallSide.west:
        hinge = Offset(r.left, r.top + opOffset);
        latch = Offset(hinge.dx, hinge.dy + opW);
        canvas.drawLine(hinge, latch, clearPaint);
        final swingX = op.swingInward ? (hinge.dx + opW) : (hinge.dx - opW);
        canvas.drawLine(hinge, Offset(swingX, hinge.dy), doorLinePaint);
        startAngle = op.swingInward ? 0 : math.pi;
        sweepAngle = op.swingInward ? math.pi / 2 : -math.pi / 2;
        canvas.drawArc(
          Rect.fromCircle(center: hinge, radius: opW),
          startAngle,
          sweepAngle,
          false,
          arcPaint,
        );
        break;

      case PlanWallSide.east:
        hinge = Offset(r.right, r.top + opOffset);
        latch = Offset(hinge.dx, hinge.dy + opW);
        canvas.drawLine(hinge, latch, clearPaint);
        final swingX = op.swingInward ? (hinge.dx - opW) : (hinge.dx + opW);
        canvas.drawLine(hinge, Offset(swingX, hinge.dy), doorLinePaint);
        startAngle = op.swingInward ? math.pi / 2 : 0;
        sweepAngle = op.swingInward ? math.pi / 2 : -math.pi / 2;
        canvas.drawArc(
          Rect.fromCircle(center: hinge, radius: opW),
          startAngle,
          sweepAngle,
          false,
          arcPaint,
        );
        break;
    }
  }

  void _drawWindow(
    Canvas canvas,
    PlanRoom room,
    PlanOpening op,
    bool isSelected,
  ) {
    final r = Rect.fromLTWH(
      room.x * scale,
      room.y * scale,
      room.width * scale,
      room.length * scale,
    );

    final opOffset = op.offsetFeet * scale;
    final opW = op.widthFeet * scale;

    final clearPaint = Paint()
      ..color = isDark ? const Color(0xFF0F172A) : const Color(0xFFFBFDFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(3.0, 0.5 * scale);

    final windowPaint = Paint()
      ..color = isSelected ? const Color(0xFFFF8C00) : const Color(0xFF0288D1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.5 : 1.8;

    final glassPaint = Paint()
      ..color = const Color(0xFF4FC3F7).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final wallThick = math.max(2.5, 0.45 * scale);
    final halfThick = wallThick / 2;

    if (op.wallSide == PlanWallSide.north ||
        op.wallSide == PlanWallSide.south) {
      final y = op.wallSide == PlanWallSide.north ? r.top : r.bottom;
      final p1 = Offset(r.left + opOffset, y);
      final p2 = Offset(p1.dx + opW, y);

      // Clear wall gap
      canvas.drawLine(p1, p2, clearPaint);

      // Outer line, inner line, glass center line
      canvas.drawLine(
        Offset(p1.dx, y - halfThick),
        Offset(p2.dx, y - halfThick),
        windowPaint,
      );
      canvas.drawLine(
        Offset(p1.dx, y + halfThick),
        Offset(p2.dx, y + halfThick),
        windowPaint,
      );
      canvas.drawLine(p1, p2, glassPaint);

      // End caps
      canvas.drawLine(
        Offset(p1.dx, y - halfThick),
        Offset(p1.dx, y + halfThick),
        windowPaint,
      );
      canvas.drawLine(
        Offset(p2.dx, y - halfThick),
        Offset(p2.dx, y + halfThick),
        windowPaint,
      );
    } else {
      final x = op.wallSide == PlanWallSide.west ? r.left : r.right;
      final p1 = Offset(x, r.top + opOffset);
      final p2 = Offset(x, p1.dy + opW);

      canvas.drawLine(p1, p2, clearPaint);

      canvas.drawLine(
        Offset(x - halfThick, p1.dy),
        Offset(x - halfThick, p2.dy),
        windowPaint,
      );
      canvas.drawLine(
        Offset(x + halfThick, p1.dy),
        Offset(x + halfThick, p2.dy),
        windowPaint,
      );
      canvas.drawLine(p1, p2, glassPaint);

      canvas.drawLine(
        Offset(x - halfThick, p1.dy),
        Offset(x + halfThick, p1.dy),
        windowPaint,
      );
      canvas.drawLine(
        Offset(x - halfThick, p2.dy),
        Offset(x + halfThick, p2.dy),
        windowPaint,
      );
    }
  }

  void _drawSelectionHighlights(Canvas canvas) {
    if (selectedRoomId == null) return;
    final room = plan.findRoom(selectedRoomId!);
    if (room == null) return;

    final r = Rect.fromLTWH(
      room.x * scale,
      room.y * scale,
      room.width * scale,
      room.length * scale,
    );

    // Glowing selection outline
    final selectPaint = Paint()
      ..color = const Color(0xFFFF8C00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRect(r.inflate(2.0), selectPaint);

    // Draw handles (4 corners + 4 edge centers)
    final handleFillPaint = Paint()
      ..color = const Color(0xFFFF8C00)
      ..style = PaintingStyle.fill;

    final handleBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final cornerRadius = 6.0;

    void drawCorner(Offset pos, ResizeHandle h) {
      final isHActive = activeHandle == h;
      final rad = isHActive ? cornerRadius + 2 : cornerRadius;
      canvas.drawCircle(pos, rad, handleFillPaint);
      canvas.drawCircle(pos, rad, handleBorderPaint);
    }

    drawCorner(r.topLeft, ResizeHandle.nw);
    drawCorner(r.topRight, ResizeHandle.ne);
    drawCorner(r.bottomLeft, ResizeHandle.sw);
    drawCorner(r.bottomRight, ResizeHandle.se);

    // Edge handles (pill shape)
    void drawEdgePill(Offset center, bool isHorizontal, ResizeHandle h) {
      final isHActive = activeHandle == h;
      final w = isHorizontal
          ? (isHActive ? 18.0 : 14.0)
          : (isHActive ? 8.0 : 6.0);
      final l = isHorizontal
          ? (isHActive ? 8.0 : 6.0)
          : (isHActive ? 18.0 : 14.0);
      final pillRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: w, height: l),
        const Radius.circular(3),
      );
      canvas.drawRRect(pillRect, handleFillPaint);
      canvas.drawRRect(pillRect, handleBorderPaint);
    }

    drawEdgePill(Offset(r.center.dx, r.top), true, ResizeHandle.n);
    drawEdgePill(Offset(r.center.dx, r.bottom), true, ResizeHandle.s);
    drawEdgePill(Offset(r.left, r.center.dy), false, ResizeHandle.w);
    drawEdgePill(Offset(r.right, r.center.dy), false, ResizeHandle.e);
  }

  void _drawDimensionLine(
    Canvas canvas,
    Offset start,
    Offset end,
    String text,
    Color color, {
    bool isVertical = false,
  }) {
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 1.0;

    canvas.drawLine(start, end, linePaint);

    // End ticks
    final tickLen = 4.0;
    if (isVertical) {
      canvas.drawLine(
        Offset(start.dx - tickLen, start.dy),
        Offset(start.dx + tickLen, start.dy),
        linePaint,
      );
      canvas.drawLine(
        Offset(end.dx - tickLen, end.dy),
        Offset(end.dx + tickLen, end.dy),
        linePaint,
      );
    } else {
      canvas.drawLine(
        Offset(start.dx, start.dy - tickLen),
        Offset(start.dx, start.dy + tickLen),
        linePaint,
      );
      canvas.drawLine(
        Offset(end.dx, end.dy - tickLen),
        Offset(end.dx, end.dy + tickLen),
        linePaint,
      );
    }

    // Text
    final span = TextSpan(
      text: text,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
    );
    final tp = TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    tp.layout();

    final center = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);

    if (isVertical) {
      canvas.save();
      canvas.translate(center.dx - 12, center.dy);
      canvas.rotate(-math.pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    } else {
      tp.paint(
        canvas,
        Offset(center.dx - tp.width / 2, center.dy - tp.height - 2),
      );
    }
  }

  void _drawNorthArrowAndScale(Canvas canvas, Size size) {
    final plotW = plan.plotWidthFeet * scale;
    final plotL = plan.plotLengthFeet * scale;

    // North Compass (Top Right of plot)
    final compassCenter = Offset(plotW + 28, 20);
    final compassRad = 12.0;

    final nPaint = Paint()
      ..color = const Color(0xFFD32F2F)
      ..style = PaintingStyle.fill;
    final sPaint = Paint()
      ..color = isDark ? Colors.white60 : const Color(0xFF1E3A5F)
      ..style = PaintingStyle.fill;

    // North pointer triangle
    final nPath = Path()
      ..moveTo(compassCenter.dx, compassCenter.dy - compassRad)
      ..lineTo(compassCenter.dx + 4, compassCenter.dy)
      ..lineTo(compassCenter.dx - 4, compassCenter.dy)
      ..close();
    canvas.drawPath(nPath, nPaint);

    // South pointer triangle
    final sPath = Path()
      ..moveTo(compassCenter.dx, compassCenter.dy + compassRad)
      ..lineTo(compassCenter.dx + 4, compassCenter.dy)
      ..lineTo(compassCenter.dx - 4, compassCenter.dy)
      ..close();
    canvas.drawPath(sPath, sPaint);

    final nSpan = TextSpan(
      text: 'N',
      style: TextStyle(
        color: const Color(0xFFD32F2F),
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );
    final nTp = TextPainter(text: nSpan, textDirection: TextDirection.ltr)
      ..layout();
    nTp.paint(
      canvas,
      Offset(
        compassCenter.dx - nTp.width / 2,
        compassCenter.dy - compassRad - 12,
      ),
    );

    // Scale Bar (Bottom of plot)
    final scaleBarFeet = 10.0;
    final barW = scaleBarFeet * scale;
    final barStart = Offset(0, plotL + 20);

    final scalePaint = Paint()
      ..color = isDark ? Colors.white70 : const Color(0xFF1E3A5F)
      ..strokeWidth = 2.0;
    canvas.drawLine(
      barStart,
      Offset(barStart.dx + barW, barStart.dy),
      scalePaint,
    );
    canvas.drawLine(
      Offset(barStart.dx, barStart.dy - 3),
      Offset(barStart.dx, barStart.dy + 3),
      scalePaint,
    );
    canvas.drawLine(
      Offset(barStart.dx + barW, barStart.dy - 3),
      Offset(barStart.dx + barW, barStart.dy + 3),
      scalePaint,
    );

    final scaleSpan = TextSpan(
      text: unit.formatLength(scaleBarFeet),
      style: TextStyle(
        color: isDark ? Colors.white70 : const Color(0xFF1E3A5F),
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    );
    final sTp = TextPainter(text: scaleSpan, textDirection: TextDirection.ltr)
      ..layout();
    sTp.paint(
      canvas,
      Offset(barStart.dx + barW / 2 - sTp.width / 2, barStart.dy + 4),
    );
  }

  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint) {
    _drawDashedLine(canvas, rect.topLeft, rect.topRight, paint);
    _drawDashedLine(canvas, rect.topRight, rect.bottomRight, paint);
    _drawDashedLine(canvas, rect.bottomRight, rect.bottomLeft, paint);
    _drawDashedLine(canvas, rect.bottomLeft, rect.topLeft, paint);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    final dashLen = 5.0;
    final gapLen = 4.0;
    double current = 0.0;

    final unitX = dx / dist;
    final unitY = dy / dist;

    while (current < dist) {
      final start = Offset(p1.dx + unitX * current, p1.dy + unitY * current);
      final segEnd = math.min(current + dashLen, dist);
      final end = Offset(p1.dx + unitX * segEnd, p1.dy + unitY * segEnd);
      canvas.drawLine(start, end, paint);
      current += dashLen + gapLen;
    }
  }

  @override
  bool shouldRepaint(covariant PlanCanvasPainter oldDelegate) {
    return oldDelegate.plan != plan ||
        oldDelegate.selectedRoomId != selectedRoomId ||
        oldDelegate.selectedOpeningId != selectedOpeningId ||
        oldDelegate.activeHandle != activeHandle ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.unit != unit ||
        oldDelegate.isDark != isDark ||
        oldDelegate.scale != scale;
  }
}
