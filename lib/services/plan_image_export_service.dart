import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

import '../models/plan/plan_models.dart';
import '../models/plan/plan_unit.dart';

/// Service responsible for rendering and exporting 2D floor plans as crisp PNG images.
class PlanImageExportService {
  /// Renders a [FloorPlan] directly to high-resolution PNG bytes using an offscreen canvas.
  /// Works reliably without needing an active UI widget tree or context.
  static Future<Uint8List> renderPlanToPng({
    required FloorPlan plan,
    double imageWidth = 1600,
    double imageHeight = 1200,
    bool showGrid = true,
    bool showDimensions = true,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(imageWidth, imageHeight);

    _paintArchitecturalPlan(
      canvas: canvas,
      size: size,
      plan: plan,
      showGrid: showGrid,
      showDimensions: showDimensions,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      imageWidth.toInt(),
      imageHeight.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception(
        'Failed to encode 2D floor plan image to PNG byte stream.',
      );
    }

    return byteData.buffer.asUint8List();
  }

  /// Captures an image from a [RenderRepaintBoundary] identified by [boundaryKey].
  /// Falls back to offscreen programmatic rendering if the boundary is unavailable.
  static Future<Uint8List> captureBoundaryOrRender({
    GlobalKey? boundaryKey,
    required FloorPlan plan,
    double pixelRatio = 2.5,
  }) async {
    if (boundaryKey?.currentContext != null) {
      try {
        final boundary =
            boundaryKey!.currentContext!.findRenderObject()
                as RenderRepaintBoundary?;
        if (boundary != null) {
          final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
          final byteData = await image.toByteData(
            format: ui.ImageByteFormat.png,
          );
          if (byteData != null) {
            return byteData.buffer.asUint8List();
          }
        }
      } catch (_) {
        // Fall back to offscreen rendering
      }
    }

    return renderPlanToPng(plan: plan);
  }

  /// Saves PNG bytes to the device's application documents or cache directory.
  static Future<File> savePngToFile({
    required Uint8List pngBytes,
    required String planName,
    bool useTemporaryDir = false,
  }) async {
    Directory directory;
    try {
      directory = useTemporaryDir
          ? await getTemporaryDirectory()
          : await getApplicationDocumentsDirectory();
    } catch (_) {
      directory = Directory.systemTemp;
    }

    final safeName = planName
        .trim()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/${safeName}_2D_Plan_$timestamp.png');

    await file.writeAsBytes(pngBytes, flush: true);
    return file;
  }

  /// Internal drawing logic for offscreen architectural rendering
  static void _paintArchitecturalPlan({
    required Canvas canvas,
    required Size size,
    required FloorPlan plan,
    required bool showGrid,
    required bool showDimensions,
  }) {
    // 1. Crisp white background with technical blueprint border
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFF1E3A5F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawRect(
      Rect.fromLTWH(18, 18, size.width - 36, size.height - 36),
      borderPaint,
    );

    // Inner thin border
    final innerBorder = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(
      Rect.fromLTWH(24, 24, size.width - 48, size.height - 48),
      innerBorder,
    );

    // Title Block Header Bar
    _drawHeaderBar(canvas, size, plan);

    // Safe drawing area inside borders and header
    const double padLeft = 48.0;
    const double padRight = 48.0;
    const double padTop = 110.0;
    const double padBottom = 80.0;

    final availW = size.width - (padLeft + padRight);
    final availH = size.height - (padTop + padBottom);

    if (availW <= 0 ||
        availH <= 0 ||
        plan.plotWidthFeet <= 0 ||
        plan.plotLengthFeet <= 0) {
      return;
    }

    final scaleX = availW / plan.plotWidthFeet;
    final scaleY = availH / plan.plotLengthFeet;
    final scale = math.min(scaleX, scaleY);

    final plotPixelW = plan.plotWidthFeet * scale;
    final plotPixelH = plan.plotLengthFeet * scale;

    final originX = padLeft + (availW - plotPixelW) / 2;
    final originY = padTop + (availH - plotPixelH) / 2;

    // 2. Subtle architectural grid
    if (showGrid) {
      final gridPaint = Paint()
        ..color = const Color(0xFFE2E8F0)
        ..strokeWidth = 1.0;

      final stepPixels = scale * 2.0; // Grid line every 2 feet
      if (stepPixels > 10) {
        for (
          double x = originX;
          x <= originX + plotPixelW + 0.1;
          x += stepPixels
        ) {
          canvas.drawLine(
            Offset(x, originY),
            Offset(x, originY + plotPixelH),
            gridPaint,
          );
        }
        for (
          double y = originY;
          y <= originY + plotPixelH + 0.1;
          y += stepPixels
        ) {
          canvas.drawLine(
            Offset(originX, y),
            Offset(originX + plotPixelW, y),
            gridPaint,
          );
        }
      }
    }

    // 3. Plot Boundary
    final plotRect = Rect.fromLTWH(originX, originY, plotPixelW, plotPixelH);
    final plotFill = Paint()..color = const Color(0xFFF8FAFC);
    canvas.drawRect(plotRect, plotFill);

    final plotOutline = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(plotRect, plotOutline);

    // Plot Dimensions Callouts
    if (showDimensions) {
      _drawDimensionLine(
        canvas: canvas,
        p1: Offset(originX, originY - 14),
        p2: Offset(originX + plotPixelW, originY - 14),
        label: 'Plot Width: ${plan.unit.formatLength(plan.plotWidthFeet)}',
        color: const Color(0xFF0F172A),
      );
      _drawDimensionLine(
        canvas: canvas,
        p1: Offset(originX - 14, originY),
        p2: Offset(originX - 14, originY + plotPixelH),
        label: 'Plot Length: ${plan.unit.formatLength(plan.plotLengthFeet)}',
        color: const Color(0xFF0F172A),
        isVertical: true,
      );
    }

    // 4. Draw Rooms (Floor fills, borders, room name & size labels)
    for (final room in plan.rooms) {
      final rx = originX + (room.x * scale);
      final ry = originY + (room.y * scale);
      final rw = room.width * scale;
      final rh = room.length * scale;
      final roomRect = Rect.fromLTWH(rx, ry, rw, rh);

      // Floor fill
      final roomFill = Paint()..color = room.color.withValues(alpha: 0.55);
      canvas.drawRect(roomRect, roomFill);

      // Inner room boundary line
      final roomBorder = Paint()
        ..color = const Color(0xFF64748B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRect(roomRect, roomBorder);

      // Room Name & Dimensions Text
      final titleSpan = TextSpan(
        children: [
          TextSpan(
            text: '${room.name}\n',
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: '${plan.unit.formatDimensions(room.width, room.length)}\n',
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: '(${plan.unit.formatArea(room.areaSqFt)})',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );

      final tp = TextPainter(
        text: titleSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: rw - 8);

      final textOffset = Offset(
        rx + (rw - tp.width) / 2,
        ry + (rh - tp.height) / 2,
      );

      if (tp.width <= rw && tp.height <= rh) {
        tp.paint(canvas, textOffset);
      }
    }

    // 5. Architectural Walls
    final wallPaint = Paint()
      ..color = const Color(0xFF1E3A5F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.5, 0.45 * scale)
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;

    for (final room in plan.rooms) {
      final r = Rect.fromLTWH(
        originX + (room.x * scale),
        originY + (room.y * scale),
        room.width * scale,
        room.length * scale,
      );
      canvas.drawRect(r, wallPaint);
    }

    // 6. Doors & Windows (Openings)
    _drawAllOpenings(
      canvas: canvas,
      plan: plan,
      originX: originX,
      originY: originY,
      scale: scale,
    );

    // 7. Technical Scale Bar and North Arrow at Footer
    _drawNorthArrowAndScale(
      canvas: canvas,
      origin: Offset(size.width - 120, size.height - 65),
      scale: scale,
      unit: plan.unit,
    );
  }

  static void _drawHeaderBar(Canvas canvas, Size size, FloorPlan plan) {
    final headerRect = Rect.fromLTWH(30, 30, size.width - 60, 60);
    final headerBg = Paint()..color = const Color(0xFF1E3A5F);
    canvas.drawRRect(
      RRect.fromRectAndRadius(headerRect, const Radius.circular(8)),
      headerBg,
    );

    // Title Text
    final titleSpan = TextSpan(
      children: [
        const TextSpan(
          text: 'BUILDCALC ARCHITECTURAL DRAWING  •  ',
          style: TextStyle(
            color: Color(0xFFFF8C00),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        TextSpan(
          text: plan.name.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );

    final tp = TextPainter(text: titleSpan, textDirection: TextDirection.ltr)
      ..layout();

    tp.paint(canvas, const Offset(46, 42));

    // Right subtitle info
    final subSpan = TextSpan(
      text:
          'Layout: ${plan.layoutType}  |  Plot: ${plan.unit.formatArea(plan.totalPlotAreaSqFt)}  |  Built-up: ${plan.unit.formatArea(plan.totalBuiltUpAreaSqFt)}',
      style: const TextStyle(
        color: Color(0xFFE2E8F0),
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );

    final subTp = TextPainter(text: subSpan, textDirection: TextDirection.ltr)
      ..layout();

    subTp.paint(canvas, Offset(size.width - 46 - subTp.width, 52));
  }

  static void _drawDimensionLine({
    required Canvas canvas,
    required Offset p1,
    required Offset p2,
    required String label,
    required Color color,
    bool isVertical = false,
  }) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.2;

    canvas.drawLine(p1, p2, linePaint);

    // Ticks at ends
    const tickLen = 5.0;
    if (isVertical) {
      canvas.drawLine(
        Offset(p1.dx - tickLen, p1.dy),
        Offset(p1.dx + tickLen, p1.dy),
        linePaint,
      );
      canvas.drawLine(
        Offset(p2.dx - tickLen, p2.dy),
        Offset(p2.dx + tickLen, p2.dy),
        linePaint,
      );
    } else {
      canvas.drawLine(
        Offset(p1.dx, p1.dy - tickLen),
        Offset(p1.dx, p1.dy + tickLen),
        linePaint,
      );
      canvas.drawLine(
        Offset(p2.dx, p2.dy - tickLen),
        Offset(p2.dx, p2.dy + tickLen),
        linePaint,
      );
    }

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final center = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
    if (isVertical) {
      tp.paint(
        canvas,
        Offset(center.dx - tp.width - 6, center.dy - tp.height / 2),
      );
    } else {
      tp.paint(
        canvas,
        Offset(center.dx - tp.width / 2, center.dy - tp.height - 4),
      );
    }
  }

  static void _drawAllOpenings({
    required Canvas canvas,
    required FloorPlan plan,
    required double originX,
    required double originY,
    required double scale,
  }) {
    final doorPaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final windowPaint = Paint()
      ..color = const Color(0xFF059669)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final arcPaint = Paint()
      ..color = const Color(0xFF0284C7).withValues(alpha: 0.6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (final room in plan.rooms) {
      for (final opening in room.openings) {
        final rx = originX + (room.x * scale);
        final ry = originY + (room.y * scale);
        final rw = room.width * scale;
        final rh = room.length * scale;
        final off = opening.offsetFeet * scale;
        final w = opening.widthFeet * scale;

        Offset start;
        Offset end;

        switch (opening.wallSide) {
          case PlanWallSide.north:
            start = Offset(rx + off, ry);
            end = Offset(rx + off + w, ry);
            break;
          case PlanWallSide.south:
            start = Offset(rx + off, ry + rh);
            end = Offset(rx + off + w, ry + rh);
            break;
          case PlanWallSide.west:
            start = Offset(rx, ry + off);
            end = Offset(rx, ry + off + w);
            break;
          case PlanWallSide.east:
            start = Offset(rx + rw, ry + off);
            end = Offset(rx + rw, ry + off + w);
            break;
        }

        if (opening.type == OpeningType.door ||
            opening.type == OpeningType.doubleDoor ||
            opening.type == OpeningType.slidingDoor) {
          // Cut line / clear frame
          final clearPaint = Paint()
            ..color = Colors.white
            ..strokeWidth = 6.0;
          canvas.drawLine(start, end, clearPaint);
          canvas.drawLine(start, end, doorPaint);

          // Swing arc for single hinged door
          if (opening.type == OpeningType.door) {
            final arcRect = Rect.fromCircle(center: start, radius: w);
            canvas.drawArc(arcRect, 0, math.pi / 2, false, arcPaint);
          }
        } else {
          // Window or Ventilation
          canvas.drawLine(start, end, windowPaint);
        }
      }
    }
  }

  static void _drawNorthArrowAndScale({
    required Canvas canvas,
    required Offset origin,
    required double scale,
    required PlanUnit unit,
  }) {
    // North Arrow
    final arrowPaint = Paint()
      ..color = const Color(0xFF1E3A5F)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(origin.dx, origin.dy - 16)
      ..lineTo(origin.dx - 6, origin.dy + 8)
      ..lineTo(origin.dx, origin.dy + 4)
      ..close();
    canvas.drawPath(path, arrowPaint);

    final pathRight = Path()
      ..moveTo(origin.dx, origin.dy - 16)
      ..lineTo(origin.dx + 6, origin.dy + 8)
      ..lineTo(origin.dx, origin.dy + 4)
      ..close();
    final arrowLight = Paint()
      ..color = const Color(0xFFFF8C00)
      ..style = PaintingStyle.fill;
    canvas.drawPath(pathRight, arrowLight);

    final nText = TextPainter(
      text: const TextSpan(
        text: 'N',
        style: TextStyle(
          color: Color(0xFF1E3A5F),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    nText.paint(canvas, Offset(origin.dx - (nText.width / 2), origin.dy - 28));

    // Scale Bar (5 feet or 2 meters)
    final scaleBarFeet = unit == PlanUnit.meters ? (2.0 / 0.3048) : 5.0;
    final scaleBarPixels = scaleBarFeet * scale;
    final scaleLabel = unit == PlanUnit.meters ? '2 m' : '5 ft';

    final barPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 3.0;

    final barStart = Offset(36, origin.dy);
    final barEnd = Offset(36 + scaleBarPixels, origin.dy);
    canvas.drawLine(barStart, barEnd, barPaint);
    canvas.drawLine(
      Offset(barStart.dx, barStart.dy - 4),
      Offset(barStart.dx, barStart.dy + 4),
      barPaint,
    );
    canvas.drawLine(
      Offset(barEnd.dx, barEnd.dy - 4),
      Offset(barEnd.dx, barEnd.dy + 4),
      barPaint,
    );

    final scaleText = TextPainter(
      text: TextSpan(
        text: 'SCALE: $scaleLabel',
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    scaleText.paint(canvas, Offset(36, origin.dy - 16));
  }
}
