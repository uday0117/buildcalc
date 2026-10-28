enum PlanUnit {
  feet,
  meters,
  inches,
  yards;

  String get symbol {
    switch (this) {
      case PlanUnit.feet:
        return 'ft';
      case PlanUnit.meters:
        return 'm';
      case PlanUnit.inches:
        return 'in';
      case PlanUnit.yards:
        return 'yd';
    }
  }

  String get areaSymbol {
    switch (this) {
      case PlanUnit.feet:
        return 'sq ft';
      case PlanUnit.meters:
        return 'sq m';
      case PlanUnit.inches:
        return 'sq in';
      case PlanUnit.yards:
        return 'sq yd';
    }
  }

  String get label {
    switch (this) {
      case PlanUnit.feet:
        return 'Feet (ft)';
      case PlanUnit.meters:
        return 'Meters (m)';
      case PlanUnit.inches:
        return 'Inches (in)';
      case PlanUnit.yards:
        return 'Yards (yd)';
    }
  }

  /// Factor to multiply internal feet to get target unit value
  double get lengthMultiplierFromFeet {
    switch (this) {
      case PlanUnit.feet:
        return 1.0;
      case PlanUnit.meters:
        return 0.3048;
      case PlanUnit.inches:
        return 12.0;
      case PlanUnit.yards:
        return 1.0 / 3.0;
    }
  }

  /// Factor to multiply target unit value to get internal feet
  double get lengthMultiplierToFeet {
    switch (this) {
      case PlanUnit.feet:
        return 1.0;
      case PlanUnit.meters:
        return 1.0 / 0.3048;
      case PlanUnit.inches:
        return 1.0 / 12.0;
      case PlanUnit.yards:
        return 3.0;
    }
  }

  /// Convert length in feet to this unit
  double fromFeet(double feet) => feet * lengthMultiplierFromFeet;

  /// Convert length in this unit to internal feet
  double toFeet(double value) => value * lengthMultiplierToFeet;

  /// Factor to multiply internal sq ft to get target sq unit value
  double get areaMultiplierFromSqFt {
    switch (this) {
      case PlanUnit.feet:
        return 1.0;
      case PlanUnit.meters:
        return 0.3048 * 0.3048; // 0.09290304
      case PlanUnit.inches:
        return 144.0;
      case PlanUnit.yards:
        return 1.0 / 9.0;
    }
  }

  /// Factor to multiply target sq unit value to get internal sq feet
  double get areaMultiplierToSqFt {
    switch (this) {
      case PlanUnit.feet:
        return 1.0;
      case PlanUnit.meters:
        return 1.0 / (0.3048 * 0.3048);
      case PlanUnit.inches:
        return 1.0 / 144.0;
      case PlanUnit.yards:
        return 9.0;
    }
  }

  /// Convert area in sq ft to this unit's sq area
  double areaFromSqFt(double sqFt) => sqFt * areaMultiplierFromSqFt;

  /// Convert area in this unit to internal sq ft
  double areaToSqFt(double value) => value * areaMultiplierToSqFt;

  /// Format length with symbol, e.g. "12.5 ft" or "3.81 m"
  String formatLength(double feet, {int decimals = 1}) {
    final val = fromFeet(feet);
    return '${val.toStringAsFixed(decimals)} $symbol';
  }

  /// Format dimension pair, e.g. "12'0" x 14'0"" or "12.0 x 14.0 ft"
  String formatDimensions(double widthFeet, double lengthFeet, {int decimals = 1}) {
    if (this == PlanUnit.feet) {
      // Architectural feet & inches notation
      final wFt = widthFeet.floor();
      final wIn = ((widthFeet - wFt) * 12).round();
      final lFt = lengthFeet.floor();
      final lIn = ((lengthFeet - lFt) * 12).round();
      return "$wFt'$wIn\" × $lFt'$lIn\"";
    }
    final w = fromFeet(widthFeet).toStringAsFixed(decimals);
    final l = fromFeet(lengthFeet).toStringAsFixed(decimals);
    return '$w × $l $symbol';
  }

  /// Format area with symbol, e.g. "168.0 sq ft" or "15.6 sq m"
  String formatArea(double sqFt, {int decimals = 1}) {
    final val = areaFromSqFt(sqFt);
    return '${val.toStringAsFixed(decimals)} $areaSymbol';
  }
}

