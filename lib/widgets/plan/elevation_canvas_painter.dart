import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../models/plan/elevation_models.dart';

class ElevationCanvasPainter extends CustomPainter {
  final ElevationConfig config;
  final ElevationViewMode mode;
  final bool isDark;

  ElevationCanvasPainter({
    required this.config,
    required this.mode,
    this.isDark = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final width = size.width;
    final height = size.height;

    // 1. Establish drawing scale and coordinates
    // We want the building centered horizontally, with Ground Level near bottom (approx 80% down)
    final double groundY = height * 0.76;
    final double totalHeightFt = config.totalHeightFeet;
    final double facadeWidthFt = config.facadeWidthFeet;

    // Available drawing box
    final double availWidth = width * 0.70;
    final double availHeight = height * 0.65;

    // Scale pixels per foot
    final double scaleX = availWidth / facadeWidthFt;
    final double scaleY = availHeight / totalHeightFt;
    final double scale = math.min(scaleX, scaleY).clamp(4.0, 40.0);

    final double bldgWidthPx = facadeWidthFt * scale;
    final double bldgLeftPx = (width - bldgWidthPx) / 2;
    final double bldgRightPx = bldgLeftPx + bldgWidthPx;

    final double plinthHeightPx = config.plinthHeightFeet * scale;
    final double plinthY = groundY - plinthHeightPx;

    if (mode == ElevationViewMode.illustrative) {
      _paintIllustrativeBackground(canvas, size, groundY);
      _paintIllustrativeBuilding(
        canvas,
        bldgLeftPx,
        bldgRightPx,
        bldgWidthPx,
        groundY,
        plinthY,
        scale,
      );
      _paintIllustrativeForeground(canvas, size, bldgLeftPx, bldgRightPx, groundY);
      _paintWatermark(canvas, size, 'ILLUSTRATIVE DESIGN CONCEPT • NOT CONSTRUCTION-READY');
    } else {
      _paintDimensionedDraft(
        canvas,
        size,
        bldgLeftPx,
        bldgRightPx,
        bldgWidthPx,
        groundY,
        plinthY,
        scale,
      );
      _paintWatermark(canvas, size, 'DIMENSIONED SCHEMATIC • FOR PRELIMINARY PLANNING ONLY');
    }
  }

  void _paintIllustrativeBackground(Canvas canvas, Size size, double groundY) {
    // Sky gradient
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
            : [const Color(0xFFE0F2FE), const Color(0xFFF8FAFC)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, groundY));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, groundY), skyPaint);

    // Ground lawn and earth
    final groundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [const Color(0xFF1B4332), const Color(0xFF081C15)]
            : [const Color(0xFF86EFAC), const Color(0xFF4ADE80)],
      ).createShader(Rect.fromLTWH(0, groundY, size.width, size.height - groundY));
    canvas.drawRect(Rect.fromLTWH(0, groundY, size.width, size.height - groundY), groundPaint);

    // Ground curb line
    final curbPaint = Paint()
      ..color = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)
      ..strokeWidth = 3.0;
    canvas.drawLine(Offset(0, groundY), Offset(size.width, groundY), curbPaint);
  }

  void _paintIllustrativeBuilding(
    Canvas canvas,
    double bldgLeft,
    double bldgRight,
    double bldgWidth,
    double groundY,
    double plinthY,
    double scale,
  ) {
    final floorCount = config.floorCount;
    final floorHeightPx = config.floorHeightFeet * scale;

    // 1. Plinth / Foundation Base
    final plinthPaint = Paint()..color = const Color(0xFF64748B);
    final plinthRect = Rect.fromLTRB(bldgLeft - 8, plinthY, bldgRight + 8, groundY);
    canvas.drawRect(plinthRect, plinthPaint);

    // Plinth stone lines
    final plinthDetailPaint = Paint()
      ..color = const Color(0xFF475569)
      ..strokeWidth = 1.0;
    canvas.drawRect(plinthRect, Paint()..style = PaintingStyle.stroke..color = const Color(0xFF334155)..strokeWidth = 1.5);
    final plinthMidY = (plinthY + groundY) / 2;
    canvas.drawLine(Offset(bldgLeft - 8, plinthMidY), Offset(bldgRight + 8, plinthMidY), plinthDetailPaint);

    // 2. Main Wall Body for all floors
    final topOfUpperFloorY = plinthY - (floorCount * floorHeightPx);
    final bodyRect = Rect.fromLTRB(bldgLeft, topOfUpperFloorY, bldgRight, plinthY);

    // Wall Paint with primary color
    final wallPaint = Paint()..color = config.primaryColor;
    canvas.drawRect(bodyRect, wallPaint);

    // Texture overlay based on finishPreset
    _paintFinishTexture(canvas, bodyRect, config.finishPreset);

    // Subtle drop shadow behind wall edges
    final wallOutline = Paint()
      ..style = PaintingStyle.stroke
      ..color = config.trimColor.withValues(alpha: 0.7)
      ..strokeWidth = 2.0;
    canvas.drawRect(bodyRect, wallOutline);

    // 3. Draw Floor Dividers & Slabs
    final slabPaint = Paint()..color = config.trimColor;
    for (int i = 1; i <= floorCount; i++) {
      final floorBottomY = plinthY - ((i - 1) * floorHeightPx);
      final floorTopY = plinthY - (i * floorHeightPx);

      // Floor slab line / cornice
      if (i < floorCount) {
        final slabRect = Rect.fromLTRB(bldgLeft - 4, floorTopY - 4, bldgRight + 4, floorTopY + 2);
        canvas.drawRect(slabRect, slabPaint);
      }

      // Draw Floor Facade Elements (Windows, Doors, Balconies)
      _paintFloorFacade(
        canvas,
        floorIndex: i - 1,
        floorCount: floorCount,
        floorBottomY: floorBottomY,
        floorTopY: floorTopY,
        bldgLeft: bldgLeft,
        bldgRight: bldgRight,
        bldgWidth: bldgWidth,
        scale: scale,
      );
    }

    // 4. Roof Silhouettes
    _paintRoof(
      canvas,
      bldgLeft: bldgLeft,
      bldgRight: bldgRight,
      bldgWidth: bldgWidth,
      topY: topOfUpperFloorY,
      scale: scale,
    );

    // 5. Car Porch if enabled on Ground Floor
    if (config.hasCarPorch && bldgWidth > 120) {
      _paintCarPorch(
        canvas,
        bldgLeft: bldgLeft,
        groundY: groundY,
        plinthY: plinthY,
        floorHeightPx: floorHeightPx,
        scale: scale,
      );
    }
  }

  void _paintFinishTexture(Canvas canvas, Rect rect, FinishPreset preset) {
    switch (preset) {
      case FinishPreset.exposedBrick:
        final brickPaint = Paint()
          ..color = const Color(0xFF7C2D12).withValues(alpha: 0.35)
          ..strokeWidth = 1.0;
        final rowHeight = 6.0;
        for (double y = rect.top + rowHeight; y < rect.bottom; y += rowHeight) {
          canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), brickPaint);
        }
        break;
      case FinishPreset.teakWoodSlat:
        final slatPaint = Paint()
          ..color = const Color(0xFF713F12).withValues(alpha: 0.45)
          ..strokeWidth = 2.0;
        final rowHeight = 7.0;
        for (double y = rect.top + rowHeight; y < rect.bottom; y += rowHeight) {
          canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), slatPaint);
        }
        break;
      case FinishPreset.stoneVeneer:
        final stonePaint = Paint()
          ..color = const Color(0xFF334155).withValues(alpha: 0.3)
          ..strokeWidth = 1.0;
        for (double y = rect.top + 10.0; y < rect.bottom; y += 12.0) {
          canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), stonePaint);
        }
        break;
      case FinishPreset.exposedConcrete:
        // Concrete tie rod holes
        final dotPaint = Paint()..color = const Color(0xFF475569).withValues(alpha: 0.4);
        for (double y = rect.top + 20.0; y < rect.bottom; y += 35.0) {
          for (double x = rect.left + 25.0; x < rect.right; x += 40.0) {
            canvas.drawCircle(Offset(x, y), 2.0, dotPaint);
          }
        }
        break;
      case FinishPreset.smoothPlaster:
      case FinishPreset.travertineMarble:
        // Clean subtle horizontal accent grooves
        final groovePaint = Paint()
          ..color = config.trimColor.withValues(alpha: 0.15)
          ..strokeWidth = 1.0;
        for (double y = rect.top + 25.0; y < rect.bottom; y += 30.0) {
          canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), groovePaint);
        }
        break;
    }
  }

  void _paintFloorFacade(
    Canvas canvas, {
    required int floorIndex,
    required int floorCount,
    required double floorBottomY,
    required double floorTopY,
    required double bldgLeft,
    required double bldgRight,
    required double bldgWidth,
    required double scale,
  }) {
    final floorH = (floorBottomY - floorTopY).abs();

    if (floorIndex == 0) {
      // GROUND FLOOR: Main Entrance Door & Front Window(s)
      final doorWidth = math.min(36.0, bldgWidth * 0.22);
      final doorHeight = floorH * 0.72;
      final doorLeft = bldgLeft + bldgWidth * 0.58;
      final doorTop = floorBottomY - doorHeight;
      final doorRect = Rect.fromLTWH(doorLeft, doorTop, doorWidth, doorHeight);

      // Entrance Portico / Canopy
      if (config.hasEntrancePortico) {
        final canopyRect = Rect.fromLTWH(doorLeft - 8, doorTop - 6, doorWidth + 16, 6);
        canvas.drawRect(canopyRect, Paint()..color = config.accentColor);
        canvas.drawRect(canopyRect, Paint()..style = PaintingStyle.stroke..color = config.trimColor..strokeWidth = 1.5);
      }

      // Main Door Body
      canvas.drawRect(doorRect, Paint()..color = config.accentColor);
      canvas.drawRect(doorRect, Paint()..style = PaintingStyle.stroke..color = config.trimColor..strokeWidth = 2.0);

      // Door Handle & Paneling
      final handlePaint = Paint()..color = Colors.amber.shade200..strokeWidth = 2.5;
      canvas.drawLine(Offset(doorLeft + doorWidth * 0.85, doorTop + doorHeight * 0.5), Offset(doorLeft + doorWidth * 0.85, doorTop + doorHeight * 0.62), handlePaint);

      // Accent wall panel behind / beside entrance
      final featureRect = Rect.fromLTWH(doorLeft - 18, floorTopY + 10, 14, floorH - 10);
      canvas.drawRect(featureRect, Paint()..color = config.accentColor.withValues(alpha: 0.85));

      // Ground Floor Windows
      final winWidth = math.min(50.0, bldgWidth * 0.26);
      final winHeight = floorH * 0.55;
      final winTop = floorTopY + floorH * 0.22;
      final winLeft = bldgLeft + bldgWidth * 0.16;
      _paintWindow(canvas, Rect.fromLTWH(winLeft, winTop, winWidth, winHeight));
    } else {
      // UPPER FLOORS: Windows & Balconies
      final winWidth = math.min(46.0, bldgWidth * 0.24);
      final winHeight = floorH * 0.55;
      final winTop = floorTopY + floorH * 0.22;

      // Left Window
      _paintWindow(canvas, Rect.fromLTWH(bldgLeft + bldgWidth * 0.12, winTop, winWidth, winHeight));

      // Right Window or Balcony Door
      final rightWinLeft = bldgLeft + bldgWidth * 0.56;
      if (config.balconyOption != BalconyOption.none) {
        // Balcony French Glass Door
        final balDoorWidth = math.min(42.0, bldgWidth * 0.28);
        final balDoorHeight = floorH * 0.72;
        final balDoorTop = floorBottomY - balDoorHeight;
        final balDoorRect = Rect.fromLTWH(rightWinLeft, balDoorTop, balDoorWidth, balDoorHeight);
        _paintWindow(canvas, balDoorRect);

        // Balcony Slab Protrusion
        final balSlabRect = Rect.fromLTWH(rightWinLeft - 6, floorBottomY - 4, balDoorWidth + 12, 6);
        canvas.drawRect(balSlabRect, Paint()..color = config.trimColor);

        // Balcony Railing
        final balRailingHeight = floorH * 0.35;
        final balRailingRect = Rect.fromLTWH(rightWinLeft - 6, floorBottomY - balRailingHeight, balDoorWidth + 12, balRailingHeight);
        _paintBalcony(canvas, balRailingRect, config.balconyOption);
      } else {
        _paintWindow(canvas, Rect.fromLTWH(rightWinLeft, winTop, winWidth, winHeight));
      }

      // Modern Architectural Box Cantilever Frame Accent
      if (config.style == ElevationStyle.modern || config.style == ElevationStyle.contemporary) {
        final boxFrameRect = Rect.fromLTWH(bldgLeft + bldgWidth * 0.08, floorTopY + 8, bldgWidth * 0.40, floorH - 12);
        canvas.drawRect(
          boxFrameRect,
          Paint()
            ..style = PaintingStyle.stroke
            ..color = config.accentColor
            ..strokeWidth = 3.5,
        );
      }
    }
  }

  void _paintWindow(Canvas canvas, Rect rect) {
    // Window Glazing
    final glassPaint = Paint()..color = config.glassColor;
    canvas.drawRect(rect, glassPaint);

    // Window Glazing Diagonal Reflection Highlights
    final reflectPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(rect.left + 4, rect.bottom - 4), Offset(rect.left + rect.width * 0.6, rect.top + 4), reflectPaint);
    canvas.drawLine(Offset(rect.left + 14, rect.bottom - 4), Offset(rect.left + rect.width * 0.8, rect.top + 4), reflectPaint);

    // Window Frame
    final framePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = config.trimColor
      ..strokeWidth = 2.0;
    canvas.drawRect(rect, framePaint);

    // Mullions based on WindowStyle
    switch (config.windowStyle) {
      case WindowStyle.modernPicture:
      case WindowStyle.minimalistFrameless:
        // Single vertical mullion
        final midX = rect.left + rect.width * 0.5;
        canvas.drawLine(Offset(midX, rect.top), Offset(midX, rect.bottom), framePaint);
        break;
      case WindowStyle.traditionalMullion:
        // 2x2 grid mullions
        final midX = rect.left + rect.width * 0.5;
        final midY = rect.top + rect.height * 0.5;
        canvas.drawLine(Offset(midX, rect.top), Offset(midX, rect.bottom), framePaint);
        canvas.drawLine(Offset(rect.left, midY), Offset(rect.right, midY), framePaint);
        break;
      case WindowStyle.traditionalArched:
        // Arched top header
        final archPath = Path()
          ..moveTo(rect.left, rect.top + rect.height * 0.3)
          ..quadraticBezierTo(rect.center.dx, rect.top - 8, rect.right, rect.top + rect.height * 0.3);
        canvas.drawPath(archPath, framePaint);
        canvas.drawLine(Offset(rect.center.dx, rect.top - 8), Offset(rect.center.dx, rect.bottom), framePaint);
        break;
      case WindowStyle.ribbonHorizontal:
        // Horizontal intermediate mullion
        final midY = rect.top + rect.height * 0.5;
        canvas.drawLine(Offset(rect.left, midY), Offset(rect.right, midY), framePaint);
        break;
    }

    // Window Sill
    final sillRect = Rect.fromLTWH(rect.left - 3, rect.bottom, rect.width + 6, 3.5);
    canvas.drawRect(sillRect, Paint()..color = config.trimColor);
  }

  void _paintBalcony(Canvas canvas, Rect rect, BalconyOption option) {
    switch (option) {
      case BalconyOption.glassRailing:
        // Tempered glass panel with reflections
        final glassPaint = Paint()..color = config.glassColor.withValues(alpha: 0.6);
        canvas.drawRect(rect, glassPaint);

        // Stainless steel top rail
        final railPaint = Paint()
          ..color = const Color(0xFFCBD5E1)
          ..strokeWidth = 3.0;
        canvas.drawLine(Offset(rect.left, rect.top), Offset(rect.right, rect.top), railPaint);

        // Posts
        final postPaint = Paint()
          ..color = const Color(0xFF94A3B8)
          ..strokeWidth = 2.0;
        canvas.drawLine(Offset(rect.left + 4, rect.top), Offset(rect.left + 4, rect.bottom), postPaint);
        canvas.drawLine(Offset(rect.center.dx, rect.top), Offset(rect.center.dx, rect.bottom), postPaint);
        canvas.drawLine(Offset(rect.right - 4, rect.top), Offset(rect.right - 4, rect.bottom), postPaint);
        break;

      case BalconyOption.metalLouver:
        // Vertical louvers
        final louverPaint = Paint()
          ..color = config.trimColor
          ..strokeWidth = 2.0;
        canvas.drawLine(Offset(rect.left, rect.top), Offset(rect.right, rect.top), louverPaint..strokeWidth = 3.0);
        for (double x = rect.left + 4; x <= rect.right - 4; x += 5.5) {
          canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), louverPaint..strokeWidth = 1.5);
        }
        break;

      case BalconyOption.masonryParapet:
        // Solid wall
        canvas.drawRect(rect, Paint()..color = config.primaryColor);
        canvas.drawRect(rect, Paint()..style = PaintingStyle.stroke..color = config.trimColor..strokeWidth = 1.5);
        // Architectural groove line
        canvas.drawLine(Offset(rect.left, rect.center.dy), Offset(rect.right, rect.center.dy), Paint()..color = config.accentColor..strokeWidth = 2.0);
        break;

      case BalconyOption.ornateTraditional:
        // Traditional turned balusters
        final topRail = Paint()..color = config.accentColor..strokeWidth = 3.5;
        canvas.drawLine(Offset(rect.left, rect.top), Offset(rect.right, rect.top), topRail);
        final balusterPaint = Paint()..color = config.accentColor..strokeWidth = 2.5;
        for (double x = rect.left + 6; x <= rect.right - 6; x += 9.0) {
          canvas.drawLine(Offset(x, rect.top + 2), Offset(x, rect.bottom), balusterPaint);
          canvas.drawCircle(Offset(x, rect.center.dy), 2.5, Paint()..color = config.accentColor);
        }
        break;

      case BalconyOption.none:
        break;
    }
  }

  void _paintRoof(
    Canvas canvas, {
    required double bldgLeft,
    required double bldgRight,
    required double bldgWidth,
    required double topY,
    required double scale,
  }) {
    switch (config.roofStyle) {
      case RoofStyle.flatParapet:
        // 3 ft Parapet wall
        final parapetH = config.parapetHeightFeet * scale;
        final parapetRect = Rect.fromLTRB(bldgLeft, topY - parapetH, bldgRight, topY);
        canvas.drawRect(parapetRect, Paint()..color = config.primaryColor);
        canvas.drawRect(parapetRect, Paint()..style = PaintingStyle.stroke..color = config.trimColor..strokeWidth = 1.5);

        // Coping stone band
        final copingRect = Rect.fromLTRB(bldgLeft - 4, topY - parapetH - 4, bldgRight + 4, topY - parapetH);
        canvas.drawRect(copingRect, Paint()..color = config.accentColor);
        canvas.drawRect(copingRect, Paint()..style = PaintingStyle.stroke..color = config.trimColor..strokeWidth = 1.0);
        break;

      case RoofStyle.pitchedTile:
        // Pitched triangular / sloped roof with eaves
        final ridgeH = 7.0 * scale;
        final eaveOverhang = 12.0;
        final roofPath = Path()
          ..moveTo(bldgLeft - eaveOverhang, topY)
          ..lineTo((bldgLeft + bldgRight) / 2, topY - ridgeH)
          ..lineTo(bldgRight + eaveOverhang, topY)
          ..close();

        // Shingle terracotta color
        canvas.drawPath(roofPath, Paint()..color = const Color(0xFFC2410C));
        canvas.drawPath(roofPath, Paint()..style = PaintingStyle.stroke..color = config.trimColor..strokeWidth = 2.0);

        // Shingle lines
        final shinglePaint = Paint()
          ..color = const Color(0xFF7C2D12).withValues(alpha: 0.5)
          ..strokeWidth = 1.5;
        for (double dy = topY - ridgeH + 8; dy < topY; dy += 7.0) {
          final frac = (dy - (topY - ridgeH)) / ridgeH;
          final xSpan = (bldgWidth / 2 + eaveOverhang) * frac;
          final midX = (bldgLeft + bldgRight) / 2;
          canvas.drawLine(Offset(midX - xSpan, dy), Offset(midX + xSpan, dy), shinglePaint);
        }
        break;

      case RoofStyle.terracePergola:
        // Flat parapet plus open pergola rafters
        final parapetH = config.parapetHeightFeet * scale * 0.7;
        final parapetRect = Rect.fromLTRB(bldgLeft, topY - parapetH, bldgRight, topY);
        canvas.drawRect(parapetRect, Paint()..color = config.primaryColor);

        // Pergola posts and cross rafters
        final pergolaH = 6.0 * scale;
        final postPaint = Paint()..color = config.accentColor..strokeWidth = 3.5;
        canvas.drawLine(Offset(bldgLeft + bldgWidth * 0.15, topY), Offset(bldgLeft + bldgWidth * 0.15, topY - pergolaH), postPaint);
        canvas.drawLine(Offset(bldgLeft + bldgWidth * 0.85, topY), Offset(bldgLeft + bldgWidth * 0.85, topY - pergolaH), postPaint);

        // Horizontal beam
        final beamPaint = Paint()..color = config.accentColor..strokeWidth = 4.0;
        canvas.drawLine(Offset(bldgLeft + bldgWidth * 0.10, topY - pergolaH), Offset(bldgLeft + bldgWidth * 0.90, topY - pergolaH), beamPaint);

        // Cross slats
        final slatPaint = Paint()..color = config.trimColor..strokeWidth = 2.0;
        for (double x = bldgLeft + bldgWidth * 0.12; x <= bldgLeft + bldgWidth * 0.88; x += 12.0) {
          canvas.drawLine(Offset(x, topY - pergolaH - 3), Offset(x, topY - pergolaH + 3), slatPaint);
        }
        break;

      case RoofStyle.mansardHip:
        // Mansard trapezoid silhouette
        final roofH = 6.0 * scale;
        final roofPath = Path()
          ..moveTo(bldgLeft - 8, topY)
          ..lineTo(bldgLeft + bldgWidth * 0.2, topY - roofH)
          ..lineTo(bldgRight - bldgWidth * 0.2, topY - roofH)
          ..lineTo(bldgRight + 8, topY)
          ..close();

        canvas.drawPath(roofPath, Paint()..color = const Color(0xFF475569));
        canvas.drawPath(roofPath, Paint()..style = PaintingStyle.stroke..color = config.trimColor..strokeWidth = 2.0);
        break;
    }
  }

  void _paintCarPorch(
    Canvas canvas, {
    required double bldgLeft,
    required double groundY,
    required double plinthY,
    required double floorHeightPx,
    required double scale,
  }) {
    final porchWidth = math.min(54.0, (bldgLeft).abs() + 45.0);
    final porchLeft = bldgLeft - porchWidth * 0.55;
    final porchTop = plinthY - floorHeightPx * 0.82;

    // Porch Slab
    final slabRect = Rect.fromLTWH(porchLeft, porchTop, porchWidth, 5.0);
    canvas.drawRect(slabRect, Paint()..color = config.accentColor);
    canvas.drawRect(slabRect, Paint()..style = PaintingStyle.stroke..color = config.trimColor..strokeWidth = 1.5);

    // Structural Pillars
    final pillarPaint = Paint()..color = config.trimColor;
    final colLeft = porchLeft + 4.0;
    canvas.drawRect(Rect.fromLTWH(colLeft, porchTop + 5.0, 5.0, groundY - (porchTop + 5.0)), pillarPaint);

    // Car silhouette outline under porch
    final carPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 1.5;
    final carY = groundY - 14.0;
    final carPath = Path()
      ..moveTo(porchLeft + 8, groundY - 2)
      ..lineTo(porchLeft + 8, carY + 4)
      ..lineTo(porchLeft + 16, carY)
      ..lineTo(porchLeft + 28, carY)
      ..lineTo(porchLeft + 36, carY + 5)
      ..lineTo(porchLeft + 42, groundY - 2);
    canvas.drawPath(carPath, carPaint);
  }

  void _paintIllustrativeForeground(
    Canvas canvas,
    Size size,
    double bldgLeft,
    double bldgRight,
    double groundY,
  ) {
    // Driveway / Entrance Path
    final pathPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [const Color(0xFF334155), const Color(0xFF1E293B)]
            : [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)],
      ).createShader(Rect.fromLTWH(bldgLeft + 20, groundY, 40, size.height - groundY));

    final pathPoly = Path()
      ..moveTo(bldgLeft + 25, groundY)
      ..lineTo(bldgLeft + 65, groundY)
      ..lineTo(bldgLeft + 85, size.height)
      ..lineTo(bldgLeft + 5, size.height)
      ..close();
    canvas.drawPath(pathPoly, pathPaint);

    // Ornamental shrub / plant flanking entrance
    _paintPlant(canvas, Offset(bldgLeft - 10, groundY - 12), 14.0);
    _paintPlant(canvas, Offset(bldgRight + 10, groundY - 12), 14.0);
  }

  void _paintPlant(Canvas canvas, Offset center, double radius) {
    final plantPaint = Paint()..color = isDark ? const Color(0xFF15803D) : const Color(0xFF22C55E);
    canvas.drawCircle(center, radius, plantPaint);
    canvas.drawCircle(Offset(center.dx - 4, center.dy + 3), radius * 0.7, plantPaint);
    canvas.drawCircle(Offset(center.dx + 4, center.dy + 3), radius * 0.7, plantPaint);
    // Pot
    final potPaint = Paint()..color = const Color(0xFF9A3412);
    final potRect = Rect.fromLTWH(center.dx - 6, center.dy + radius * 0.6, 12, 10);
    canvas.drawRect(potRect, potPaint);
  }

  // =========================================================================
  // MODE 2: DIMENSIONED CONSTRUCTION DRAFT (CAD Orthographic View)
  // =========================================================================

  void _paintDimensionedDraft(
    Canvas canvas,
    Size size,
    double bldgLeft,
    double bldgRight,
    double bldgWidth,
    double groundY,
    double plinthY,
    double scale,
  ) {
    final floorCount = config.floorCount;
    final floorHeightPx = config.floorHeightFeet * scale;
    final topOfUpperFloorY = plinthY - (floorCount * floorHeightPx);

    // CAD Blueprint / Drafting background
    final bgPaint = Paint()..color = isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // CAD Grid lines (subtle)
    final cadGridPaint = Paint()
      ..color = (isDark ? Colors.blue.shade900 : Colors.blue.shade50).withValues(alpha: 0.5)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 25.0) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), cadGridPaint);
    }
    for (double y = 0; y < size.height; y += 25.0) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), cadGridPaint);
    }

    final cadLinePaint = Paint()
      ..color = isDark ? Colors.white : const Color(0xFF0F172A)
      ..strokeWidth = 2.0;

    final dimLinePaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..strokeWidth = 1.0;

    // Ground line (Heavy CAD ground symbol)
    canvas.drawLine(Offset(size.width * 0.05, groundY), Offset(size.width * 0.95, groundY), cadLinePaint..strokeWidth = 2.5);
    // Ground hatch marks
    final hatchPaint = Paint()
      ..color = isDark ? Colors.white54 : Colors.black45
      ..strokeWidth = 1.0;
    for (double x = size.width * 0.08; x < size.width * 0.92; x += 12.0) {
      canvas.drawLine(Offset(x, groundY), Offset(x - 8, groundY + 8), hatchPaint);
    }

    // Plinth Box
    canvas.drawRect(Rect.fromLTRB(bldgLeft, plinthY, bldgRight, groundY), Paint()..style = PaintingStyle.stroke..color = cadLinePaint.color..strokeWidth = 2.0);

    // Main Structural Outer Wall Envelope
    canvas.drawRect(Rect.fromLTRB(bldgLeft, topOfUpperFloorY, bldgRight, plinthY), Paint()..style = PaintingStyle.stroke..color = cadLinePaint.color..strokeWidth = 2.5);

    // Floor Level Intermediates
    for (int i = 1; i <= floorCount; i++) {
      final floorY = plinthY - (i * floorHeightPx);
      // Floor slab line
      canvas.drawLine(Offset(bldgLeft, floorY), Offset(bldgRight, floorY), cadLinePaint..strokeWidth = 1.5);

      // Floor Fenestrations (Schematic Doors & Windows)
      final winTop = floorY + floorHeightPx * 0.25;
      final winBottom = floorY + floorHeightPx * 0.75;
      final winLeft = bldgLeft + bldgWidth * 0.15;
      final winRight = winLeft + bldgWidth * 0.25;

      // Window CAD box with diagonal cross
      final winRect = Rect.fromLTRB(winLeft, winTop, winRight, winBottom);
      canvas.drawRect(winRect, Paint()..style = PaintingStyle.stroke..color = cadLinePaint.color..strokeWidth = 1.5);
      canvas.drawLine(winRect.topLeft, winRect.bottomRight, hatchPaint);
      canvas.drawLine(winRect.bottomLeft, winRect.topRight, hatchPaint);

      if (i == 1) {
        // Ground Door
        final doorLeft = bldgLeft + bldgWidth * 0.60;
        final doorRight = doorLeft + bldgWidth * 0.22;
        final doorTop = plinthY - floorHeightPx * 0.75;
        final doorRect = Rect.fromLTRB(doorLeft, doorTop, doorRight, plinthY);
        canvas.drawRect(doorRect, Paint()..style = PaintingStyle.stroke..color = cadLinePaint.color..strokeWidth = 2.0);
      } else {
        // Upper floor window
        final upWinLeft = bldgLeft + bldgWidth * 0.60;
        final upWinRight = upWinLeft + bldgWidth * 0.25;
        final upWinRect = Rect.fromLTRB(upWinLeft, winTop, upWinRight, winBottom);
        canvas.drawRect(upWinRect, Paint()..style = PaintingStyle.stroke..color = cadLinePaint.color..strokeWidth = 1.5);
      }
    }

    // Parapet / Roof outline
    final parapetH = config.parapetHeightFeet * scale;
    final parapetTopY = topOfUpperFloorY - parapetH;
    canvas.drawRect(Rect.fromLTRB(bldgLeft, parapetTopY, bldgRight, topOfUpperFloorY), Paint()..style = PaintingStyle.stroke..color = cadLinePaint.color..strokeWidth = 2.0);

    // =========================================================================
    // LEVEL DATUMS (Standard Architectural Elevation Callouts)
    // =========================================================================
    final datumX = bldgRight + 25.0;

    // 1. Ground Level (GL)
    _drawDatumMarker(canvas, datumX, groundY, '±0\'0" GL (GROUND LEVEL)', isDark);

    // 2. Plinth Level (PL)
    _drawDatumMarker(canvas, datumX, plinthY, '+${config.plinthHeightFeet.toStringAsFixed(1)}\' PL (PLINTH LEVEL)', isDark);

    // 3. Each Floor Level
    for (int i = 1; i <= floorCount; i++) {
      final floorY = plinthY - (i * floorHeightPx);
      final levelFeet = config.plinthHeightFeet + (i * config.floorHeightFeet);
      final name = i == 1 ? 'FIRST FLOOR' : i == 2 ? 'SECOND FLOOR' : i == 3 ? 'THIRD FLOOR' : 'ROOF SLAB';
      _drawDatumMarker(canvas, datumX, floorY, '+$levelFeet\' $name', isDark);
    }

    // 4. Top of Parapet
    _drawDatumMarker(canvas, datumX, parapetTopY, '+${config.totalHeightFeet.toStringAsFixed(1)}\' TOP OF PARAPET', isDark);

    // =========================================================================
    // DIMENSION CHAINS
    // =========================================================================
    // Width dimension line below ground
    final widthDimY = groundY + 28.0;
    _drawDimensionLine(
      canvas,
      start: Offset(bldgLeft, widthDimY),
      end: Offset(bldgRight, widthDimY),
      label: '${config.facadeWidthFeet.toStringAsFixed(1)} FT FRONTAGE',
      dimPaint: dimLinePaint,
      isDark: isDark,
    );

    // Vertical height chain on left side
    final leftDimX = bldgLeft - 28.0;
    _drawVerticalDimensionLine(
      canvas,
      bottomY: groundY,
      topY: parapetTopY,
      x: leftDimX,
      label: '${config.totalHeightFeet.toStringAsFixed(1)} FT TOTAL HT',
      dimPaint: dimLinePaint,
      isDark: isDark,
    );

    // Title Block Stamp (CAD Corner)
    _drawCADTitleBlock(canvas, size, isDark);
  }

  void _drawDatumMarker(Canvas canvas, double x, double y, String label, bool isDark) {
    final markerPaint = Paint()..color = const Color(0xFFEF4444);
    // Datum circle & crosshair
    canvas.drawCircle(Offset(x, y), 4.5, Paint()..style = PaintingStyle.stroke..color = markerPaint.color..strokeWidth = 1.5);
    canvas.drawLine(Offset(x - 8, y), Offset(x + 16, y), markerPaint..strokeWidth = 1.0);
    canvas.drawLine(Offset(x, y - 6), Offset(x, y + 6), markerPaint..strokeWidth = 1.0);

    // Text Label
    final textSpan = TextSpan(
      text: label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white70 : const Color(0xFF1E293B),
        fontFamily: 'monospace',
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(x + 20, y - textPainter.height / 2));
  }

  void _drawDimensionLine(
    Canvas canvas, {
    required Offset start,
    required Offset end,
    required String label,
    required Paint dimPaint,
    required bool isDark,
  }) {
    // Dimension line
    canvas.drawLine(start, end, dimPaint);

    // Extension witness ticks
    final tickHeight = 6.0;
    canvas.drawLine(Offset(start.dx, start.dy - tickHeight), Offset(start.dx, start.dy + tickHeight), dimPaint);
    canvas.drawLine(Offset(end.dx, end.dy - tickHeight), Offset(end.dx, end.dy + tickHeight), dimPaint);

    // Dimension Arrow heads (45 deg architectural ticks)
    canvas.drawLine(Offset(start.dx - 3, start.dy - 3), Offset(start.dx + 3, start.dy + 3), dimPaint..strokeWidth = 1.8);
    canvas.drawLine(Offset(end.dx - 3, end.dy - 3), Offset(end.dx + 3, end.dy + 3), dimPaint..strokeWidth = 1.8);

    // Dimension Text
    final textSpan = TextSpan(
      text: label,
      style: TextStyle(
        fontSize: 9.5,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF0284C7),
        fontFamily: 'monospace',
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    final midX = (start.dx + end.dx) / 2;
    textPainter.paint(canvas, Offset(midX - textPainter.width / 2, start.dy + 4));
  }

  void _drawVerticalDimensionLine(
    Canvas canvas, {
    required double bottomY,
    required double topY,
    required double x,
    required String label,
    required Paint dimPaint,
    required bool isDark,
  }) {
    canvas.drawLine(Offset(x, bottomY), Offset(x, topY), dimPaint);

    // Ticks
    canvas.drawLine(Offset(x - 5, bottomY), Offset(x + 5, bottomY), dimPaint);
    canvas.drawLine(Offset(x - 5, topY), Offset(x + 5, topY), dimPaint);

    // Text Label rotated or vertical offset
    final textSpan = TextSpan(
      text: label,
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0284C7),
        fontFamily: 'monospace',
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(x - 14, (bottomY + topY) / 2 + textPainter.width / 2);
    canvas.rotate(-math.pi / 2);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  void _drawCADTitleBlock(Canvas canvas, Size size, bool isDark) {
    final boxW = 160.0;
    final boxH = 46.0;
    final boxRect = Rect.fromLTWH(12, 12, boxW, boxH);

    final borderPaint = Paint()
      ..color = isDark ? Colors.white38 : Colors.black38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(boxRect, borderPaint);

    final textSpan = TextSpan(
      children: [
        TextSpan(
          text: 'BUILDCALC ARCH CAD\n',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
            fontFamily: 'monospace',
          ),
        ),
        TextSpan(
          text: 'FRONT ELEVATION SCHEMATIC\n',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFF8C00),
            fontFamily: 'monospace',
          ),
        ),
        TextSpan(
          text: 'SCALE: PROPORTIONAL CAD\nNOT FOR STRUCTURAL PERMIT',
          style: TextStyle(
            fontSize: 7,
            color: isDark ? Colors.white60 : Colors.black54,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: boxW - 8);
    textPainter.paint(canvas, const Offset(16, 16));
  }

  void _paintWatermark(Canvas canvas, Size size, String text) {
    final watermarkSpan = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.35),
        letterSpacing: 1.2,
      ),
    );
    final painter = TextPainter(
      text: watermarkSpan,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 24);

    painter.paint(canvas, Offset((size.width - painter.width) / 2, size.height - painter.height - 8));
  }

  @override
  bool shouldRepaint(covariant ElevationCanvasPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.mode != mode ||
        oldDelegate.isDark != isDark;
  }
}
