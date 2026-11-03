import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/vastu_rules.dart';

class VastuCompassDial extends StatefulWidget {
  final VastuDirection selectedDirection;
  final ValueChanged<VastuDirection> onDirectionChanged;
  final double size;

  const VastuCompassDial({
    super.key,
    required this.selectedDirection,
    required this.onDirectionChanged,
    this.size = 280,
  });

  @override
  State<VastuCompassDial> createState() => _VastuCompassDialState();
}

class _VastuCompassDialState extends State<VastuCompassDial>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _angleAnimation;
  double _currentAngle = 0;

  @override
  void initState() {
    super.initState();
    _currentAngle = widget.selectedDirection.degreeAngle;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _angleAnimation = Tween<double>(
      begin: _currentAngle,
      end: _currentAngle,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(covariant VastuCompassDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDirection != widget.selectedDirection) {
      _rotateToDirection(widget.selectedDirection);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _rotateToDirection(VastuDirection dir) {
    final target = dir.degreeAngle;
    _angleAnimation = Tween<double>(
      begin: _currentAngle,
      end: target,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _currentAngle = target;
    _animController.forward(from: 0);
  }

  VastuDirection _angleToDirection(double angleDeg) {
    final norm = (angleDeg % 360 + 360) % 360;
    if (norm >= 337.5 || norm < 22.5) return VastuDirection.north;
    if (norm >= 22.5 && norm < 67.5) return VastuDirection.northEast;
    if (norm >= 67.5 && norm < 112.5) return VastuDirection.east;
    if (norm >= 112.5 && norm < 157.5) return VastuDirection.southEast;
    if (norm >= 157.5 && norm < 202.5) return VastuDirection.south;
    if (norm >= 202.5 && norm < 247.5) return VastuDirection.southWest;
    if (norm >= 247.5 && norm < 292.5) return VastuDirection.west;
    return VastuDirection.northWest;
  }

  void _handlePanUpdate(Offset localPos, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;
    // Calculate angle in degrees from top (North)
    double deg = (math.atan2(dy, dx) * 180 / math.pi) + 90;
    if (deg < 0) deg += 360;
    final dir = _angleToDirection(deg);
    if (dir != widget.selectedDirection) {
      widget.onDirectionChanged(dir);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: GestureDetector(
        onPanUpdate: (details) =>
            _handlePanUpdate(details.localPosition, Size(widget.size, widget.size)),
        onTapUp: (details) =>
            _handlePanUpdate(details.localPosition, Size(widget.size, widget.size)),
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _angleAnimation,
            builder: (context, _) {
              return CustomPaint(
                painter: _VastuCompassPainter(
                  angleDeg: _angleAnimation.value,
                  selectedDirection: widget.selectedDirection,
                  isDark: isDark,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _VastuCompassPainter extends CustomPainter {
  final double angleDeg;
  final VastuDirection selectedDirection;
  final bool isDark;

  _VastuCompassPainter({
    required this.angleDeg,
    required this.selectedDirection,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Outer decorative ring
    final outerRingPaint = Paint()
      ..color = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius - 4, outerRingPaint);

    // 2. Dial background
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 6, bgPaint);

    // 3. Draw 8 Vastu directional sectors (petals)
    const sectors = [
      VastuDirection.north,
      VastuDirection.northEast,
      VastuDirection.east,
      VastuDirection.southEast,
      VastuDirection.south,
      VastuDirection.southWest,
      VastuDirection.west,
      VastuDirection.northWest,
    ];

    const sectorAngle = (2 * math.pi) / 8;

    for (int i = 0; i < sectors.length; i++) {
      final dir = sectors[i];
      final isSelected = dir == selectedDirection;
      final startAngle = (i * sectorAngle) - (math.pi / 2) - (sectorAngle / 2);

      final sectorPaint = Paint()
        ..color = isSelected
            ? dir.elementColor.withValues(alpha: isDark ? 0.45 : 0.25)
            : (isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC))
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 10),
        startAngle,
        sectorAngle,
        true,
        sectorPaint,
      );

      // Sector dividing lines
      final linePaint = Paint()
        ..color = isDark ? Colors.white12 : const Color(0xFFE2E8F0)
        ..strokeWidth = 1.2;

      final lx = center.dx + (radius - 10) * math.cos(startAngle);
      final ly = center.dy + (radius - 10) * math.sin(startAngle);
      canvas.drawLine(center, Offset(lx, ly), linePaint);

      // Label (Direction initials & Sanskrit name)
      final midAngle = startAngle + (sectorAngle / 2);
      final labelDist = radius * 0.72;
      final tx = center.dx + labelDist * math.cos(midAngle);
      final ty = center.dy + labelDist * math.sin(midAngle);

      final textSpan = TextSpan(
        text: '${dir.shortName}\n${dir.sanskritName.split(' ').first}',
        style: TextStyle(
          color: isSelected
              ? dir.elementColor
              : (isDark ? Colors.white70 : const Color(0xFF475569)),
          fontSize: isSelected ? 9.5 : 8.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          height: 1.1,
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(tx - tp.width / 2, ty - tp.height / 2));
    }

    // 4. Center Brahmasthan Circle
    final centerCirclePaint = Paint()
      ..color = const Color(0xFFFF8C00).withValues(alpha: isDark ? 0.2 : 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.28, centerCirclePaint);

    final centerBorder = Paint()
      ..color = const Color(0xFFFF8C00).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius * 0.28, centerBorder);

    // 5. Magnetic Compass Needle
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate((angleDeg * math.pi) / 180);

    final needleLength = radius * 0.78;
    const needleWidth = 10.0;

    // North Needle (Red tip)
    final northPath = Path()
      ..moveTo(0, -needleLength)
      ..lineTo(needleWidth, 0)
      ..lineTo(0, -4)
      ..close();
    final northPaint = Paint()..color = const Color(0xFFEF4444);
    canvas.drawPath(northPath, northPaint);

    final northShadePath = Path()
      ..moveTo(0, -needleLength)
      ..lineTo(-needleWidth, 0)
      ..lineTo(0, -4)
      ..close();
    final northShadePaint = Paint()..color = const Color(0xFFB91C1C);
    canvas.drawPath(northShadePath, northShadePaint);

    // South Needle (Silver/Dark tip)
    final southPath = Path()
      ..moveTo(0, needleLength)
      ..lineTo(needleWidth, 0)
      ..lineTo(0, 4)
      ..close();
    final southPaint = Paint()
      ..color = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    canvas.drawPath(southPath, southPaint);

    final southShadePath = Path()
      ..moveTo(0, needleLength)
      ..lineTo(-needleWidth, 0)
      ..lineTo(0, 4)
      ..close();
    final southShadePaint = Paint()
      ..color = isDark ? const Color(0xFF64748B) : const Color(0xFF475569);
    canvas.drawPath(southShadePath, southShadePaint);

    // Center Gold Pivot
    final pivotPaint = Paint()..color = const Color(0xFFFF8C00);
    canvas.drawCircle(Offset.zero, 7, pivotPaint);

    final pivotInner = Paint()..color = Colors.white;
    canvas.drawCircle(Offset.zero, 3, pivotInner);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _VastuCompassPainter oldDelegate) {
    return oldDelegate.angleDeg != angleDeg ||
        oldDelegate.selectedDirection != selectedDirection ||
        oldDelegate.isDark != isDark;
  }
}

