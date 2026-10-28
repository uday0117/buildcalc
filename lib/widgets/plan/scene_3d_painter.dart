import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../models/plan/plan_3d_models.dart';

class Scene3DPainter extends CustomPainter {
  final Mesh3D mesh;
  final Camera3DState camera;
  final bool showLabels;
  final bool showLighting;

  // Normalized directional sunlight vector (from top-front-right)
  static final Point3D _sunDirection = const Point3D(
    0.45,
    -0.55,
    0.70,
  ).normalized;

  Scene3DPainter({
    required this.mesh,
    required this.camera,
    this.showLabels = true,
    this.showLighting = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (mesh.polygons.isEmpty) return;

    final width = size.width;
    final height = size.height;
    final screenCenter = Offset(
      width / 2 + camera.pan.dx,
      height / 2 + camera.pan.dy,
    );

    // 1. Calculate Camera Frame
    final target = mesh.center;
    final d = camera.distance;
    final azim = camera.azimuth;
    final elev = camera.elevation;

    // Eye position in spherical coordinates relative to target
    final eyeX = target.x + d * math.cos(elev) * math.sin(azim);
    final eyeY = target.y - d * math.cos(elev) * math.cos(azim);
    final eyeZ = target.z + d * math.sin(elev);
    final eye = Point3D(eyeX, eyeY, eyeZ);

    // Forward vector (from eye to target)
    final fwd = (target - eye).normalized;

    // World Up
    const worldUp = Point3D(0, 0, 1);

    // Camera Right = Fwd x Up
    Point3D right = fwd.cross(worldUp).normalized;
    if (right.length < 0.001) {
      right = const Point3D(1, 0, 0);
    }

    // Camera Up = Right x Fwd
    final up = right.cross(fwd).normalized;

    // Perspective / Isometric scaling
    final viewportDimension = math.min(width, height);
    final focalLength = viewportDimension * 1.35; // Perspective focal scale
    final isoScale = (viewportDimension / (d * 0.75)); // Isometric scale

    // 2. Transform & Depth Sort Polygons
    final List<_RenderPolygon> renderList = [];

    for (final poly in mesh.polygons) {
      // Calculate depth from centroid to eye
      final centroid = poly.center;
      final toCentroid = centroid - eye;
      final depth = toCentroid.dot(fwd);

      // In perspective mode, cull polygons behind the camera near plane
      if (camera.projectionMode == ProjectionMode.perspective && depth <= 1.0) {
        continue;
      }

      // Project vertices
      final List<Offset> projectedPoints = [];
      bool allValid = true;

      for (final v in poly.vertices) {
        final toVertex = v - eye;
        final vDepth = toVertex.dot(fwd);

        if (camera.projectionMode == ProjectionMode.perspective &&
            vDepth <= 0.5) {
          allValid = false;
          break;
        }

        final xCam = toVertex.dot(right);
        final yCam = toVertex.dot(up);

        double sx;
        double sy;

        if (camera.projectionMode == ProjectionMode.perspective) {
          sx = screenCenter.dx + (xCam / vDepth) * focalLength;
          sy = screenCenter.dy - (yCam / vDepth) * focalLength;
        } else {
          sx = screenCenter.dx + xCam * isoScale;
          sy = screenCenter.dy - yCam * isoScale;
        }

        projectedPoints.add(Offset(sx, sy));
      }

      if (!allValid || projectedPoints.length < 3) continue;

      // Lighting shading
      Color shadedColor = poly.baseColor;
      if (showLighting && !poly.category.isGlass) {
        final dot = poly.normal.dot(_sunDirection);
        // Lambertian diffuse + ambient
        final intensity = (0.45 + 0.55 * math.max(0.0, dot)).clamp(0.35, 1.15);
        shadedColor = _applyLighting(poly.baseColor, intensity);
      }

      renderList.add(
        _RenderPolygon(
          points: projectedPoints,
          color: shadedColor,
          opacity: poly.opacity,
          edgeColor: poly.edgeColor,
          edgeWidth: poly.edgeWidth,
          depth: depth,
          category: poly.category,
        ),
      );
    }

    // Sort by depth descending (furthest first - Painter's Algorithm)
    renderList.sort((a, b) => b.depth.compareTo(a.depth));

    // 3. Render 3D Polygons
    final fillPaint = Paint()..style = PaintingStyle.fill;
    final edgePaint = Paint()..style = PaintingStyle.stroke;

    for (final item in renderList) {
      final path = Path();
      path.moveTo(item.points[0].dx, item.points[0].dy);
      for (int i = 1; i < item.points.length; i++) {
        path.lineTo(item.points[i].dx, item.points[i].dy);
      }
      path.close();

      // Fill
      fillPaint.color = item.color.withValues(alpha: item.opacity);
      canvas.drawPath(path, fillPaint);

      // Edge border
      if (item.edgeColor != null && item.edgeWidth > 0) {
        edgePaint.color = item.edgeColor!;
        edgePaint.strokeWidth = item.edgeWidth;
        canvas.drawPath(path, edgePaint);
      }
    }

    // 4. Render 3D Room Annotations & Dimension Badges
    if (showLabels && mesh.roomAnnotations.isNotEmpty) {
      for (final ann in mesh.roomAnnotations) {
        final toPos = ann.position - eye;
        final depth = toPos.dot(fwd);

        if (camera.projectionMode == ProjectionMode.perspective &&
            depth <= 1.0) {
          continue;
        }

        final xCam = toPos.dot(right);
        final yCam = toPos.dot(up);

        double sx;
        double sy;

        if (camera.projectionMode == ProjectionMode.perspective) {
          sx = screenCenter.dx + (xCam / depth) * focalLength;
          sy = screenCenter.dy - (yCam / depth) * focalLength;
        } else {
          sx = screenCenter.dx + xCam * isoScale;
          sy = screenCenter.dy - yCam * isoScale;
        }

        _drawRoomBadge(canvas, Offset(sx, sy), ann);
      }
    }
  }

  /// Draws a clean floating label with room name and dimensions
  void _drawRoomBadge(Canvas canvas, Offset screenPos, RoomAnnotation3D ann) {
    const textStyleName = TextStyle(
      color: Color(0xFF1E293B),
      fontSize: 10,
      fontWeight: FontWeight.bold,
      fontFamily: 'Roboto',
    );
    const textStyleDim = TextStyle(
      color: Color(0xFF64748B),
      fontSize: 9,
      fontWeight: FontWeight.w500,
      fontFamily: 'Roboto',
    );

    final titleSpan = TextSpan(
      children: [
        TextSpan(text: '${ann.name}\n', style: textStyleName),
        TextSpan(text: ann.dimensionsText, style: textStyleDim),
      ],
    );

    final textPainter = TextPainter(
      text: titleSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final paddingH = 7.0;
    final paddingV = 4.0;
    final badgeWidth = textPainter.width + paddingH * 2;
    final badgeHeight = textPainter.height + paddingV * 2;

    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: screenPos,
        width: badgeWidth,
        height: badgeHeight,
      ),
      const Radius.circular(8),
    );

    // Badge Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawRRect(badgeRect.shift(const Offset(0, 1.5)), shadowPaint);

    // Badge Background
    final bgPaint = Paint()..color = Colors.white.withValues(alpha: 0.94);
    canvas.drawRRect(badgeRect, bgPaint);

    // Badge Left Accent Bar
    final borderPaint = Paint()
      ..color = ann.color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(badgeRect, borderPaint);

    // Text layout
    textPainter.paint(
      canvas,
      Offset(
        screenPos.dx - textPainter.width / 2,
        screenPos.dy - textPainter.height / 2,
      ),
    );
  }

  Color _applyLighting(Color base, double intensity) {
    final r = (base.r * 255.0 * intensity).clamp(0.0, 255.0).round();
    final g = (base.g * 255.0 * intensity).clamp(0.0, 255.0).round();
    final b = (base.b * 255.0 * intensity).clamp(0.0, 255.0).round();
    return Color.fromARGB((base.a * 255.0).round(), r, g, b);
  }

  @override
  bool shouldRepaint(covariant Scene3DPainter oldDelegate) {
    return oldDelegate.mesh != mesh ||
        oldDelegate.camera != camera ||
        oldDelegate.showLabels != showLabels ||
        oldDelegate.showLighting != showLighting;
  }
}

class _RenderPolygon {
  final List<Offset> points;
  final Color color;
  final double opacity;
  final Color? edgeColor;
  final double edgeWidth;
  final double depth;
  final PolygonCategory category;

  _RenderPolygon({
    required this.points,
    required this.color,
    required this.opacity,
    this.edgeColor,
    required this.edgeWidth,
    required this.depth,
    required this.category,
  });
}
