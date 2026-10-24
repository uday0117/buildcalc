import 'package:buildcalc/app_settings.dart';
import 'package:buildcalc/models/project.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('default app settings use system theme and English locale', () {
    final settings = AppSettings();

    expect(settings.themeMode, ThemeMode.system);
    expect(settings.locale.languageCode, 'en');
  });

  test('project materials calculate totals and serialize cleanly', () {
    final project = Project(
      id: 'project-1',
      name: 'Villa Extension',
      location: 'Riyadh',
      budget: 450000,
      createdAt: DateTime(2026, 10, 1),
      notes: 'Front extension',
      materials: [
        ProjectMaterial(
          id: 'mat-1',
          name: 'Cement',
          unit: 'bag',
          quantity: 60,
          unitPrice: 28,
          wastagePercent: 10,
        ),
      ],
      history: [
        ProjectHistoryEntry(
          id: 'h-1',
          title: 'Initial estimate created',
          timestamp: DateTime(2026, 10, 1, 9, 0),
        ),
      ],
    );

    expect(project.totalMaterialCost, closeTo(1848.0, 0.001));
    expect(project.toJson()['name'], 'Villa Extension');
    expect(Project.fromJson(project.toJson()).name, 'Villa Extension');
  });
}
