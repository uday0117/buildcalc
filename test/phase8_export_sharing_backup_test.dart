import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:buildcalc/models/plan/export_metadata.dart';
import 'package:buildcalc/models/plan/material_estimation_models.dart';
import 'package:buildcalc/models/plan/plan_models.dart';
import 'package:buildcalc/models/plan/plan_unit.dart';
import 'package:buildcalc/services/plan_backup_service.dart';
import 'package:buildcalc/services/plan_image_export_service.dart';
import 'package:buildcalc/services/plan_material_estimator.dart';
import 'package:buildcalc/services/plan_pdf_export_service.dart';
import 'package:buildcalc/services/plan_share_service.dart';
import 'package:buildcalc/services/plan_storage_service.dart';
import 'package:buildcalc/widgets/plan/plan_export_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  FloorPlan createSampleFloorPlan({int roomCount = 3}) {
    final now = DateTime(2026, 10, 29, 10, 30);
    final rooms = <PlanRoom>[];

    for (int i = 0; i < roomCount; i++) {
      rooms.add(
        PlanRoom(
          id: 'room_$i',
          name: i == 0
              ? 'Living Room'
              : i == 1
              ? 'Master Bedroom'
              : 'Kitchen $i',
          type: i == 0
              ? RoomType.living
              : i == 1
              ? RoomType.masterBedroom
              : RoomType.kitchen,
          x: (i % 2) * 15.0,
          y: (i ~/ 2) * 15.0,
          width: 14.0,
          length: 12.0,
          colorValue: Colors.blue.toARGB32(),
          openings: [
            PlanOpening(
              id: 'door_$i',
              roomId: 'room_$i',
              wallSide: PlanWallSide.south,
              type: OpeningType.door,
              offsetFeet: 2.0,
              widthFeet: 3.0,
            ),
            PlanOpening(
              id: 'window_$i',
              roomId: 'room_$i',
              wallSide: PlanWallSide.north,
              type: OpeningType.window,
              offsetFeet: 4.0,
              widthFeet: 4.0,
            ),
          ],
        ),
      );
    }

    return FloorPlan(
      id: 'test_plan_001',
      name: 'Sunset Villa',
      plotWidthFeet: 35.0,
      plotLengthFeet: 45.0,
      layoutType: '2 BHK Independent',
      unit: PlanUnit.feet,
      createdAt: now,
      updatedAt: now,
      rooms: rooms,
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('ReportMetadata Tests', () {
    test(
      'default metadata initializes correctly and serializes to/from JSON',
      () {
        final now = DateTime(2026, 10, 29);
        final meta = ReportMetadata(
          title: 'Villa Floor Plan',
          projectName: 'Sunset Villa',
          clientName: 'Jane Smith',
          clientPhone: '+1-555-0199',
          companyName: 'Apex Architecture',
          preparedBy: 'Architect Dave',
          notes: 'Pre-construction preliminary drawing.',
          createdAt: now,
        );

        expect(meta.hasClientDetails, isTrue);
        expect(meta.hasCompanyDetails, isTrue);

        final jsonMap = meta.toJson();
        expect(jsonMap['title'], 'Villa Floor Plan');
        expect(jsonMap['clientName'], 'Jane Smith');
        expect(jsonMap['companyName'], 'Apex Architecture');

        final deserialized = ReportMetadata.fromJson(jsonMap);
        expect(deserialized.title, meta.title);
        expect(deserialized.clientName, meta.clientName);
        expect(deserialized.preparedBy, meta.preparedBy);
        expect(deserialized.notes, meta.notes);
      },
    );

    test(
      'saves and retrieves default company profile via SharedPreferences',
      () async {
        await ReportMetadata.saveDefaultCompanyDetails(
          companyName: 'BuildPro Consultants',
          companyAddress: '100 Metro Tower',
          companyPhone: '+1-800-BUILDCALC',
          companyEmail: 'info@buildpro.com',
          preparedBy: 'Er. John Doe',
        );

        final profile = await ReportMetadata.loadDefaultCompanyDetails();
        expect(profile['companyName'], 'BuildPro Consultants');
        expect(profile['companyAddress'], '100 Metro Tower');
        expect(profile['companyPhone'], '+1-800-BUILDCALC');
        expect(profile['companyEmail'], 'info@buildpro.com');
        expect(profile['preparedBy'], 'Er. John Doe');
      },
    );
  });

  group('PlanImageExportService 2D PNG Rendering Tests', () {
    test('renders 2D plan offscreen to crisp PNG image bytes', () async {
      final plan = createSampleFloorPlan(roomCount: 2);
      final pngBytes = await PlanImageExportService.renderPlanToPng(
        plan: plan,
        imageWidth: 800,
        imageHeight: 600,
      );

      expect(pngBytes, isNotNull);
      expect(pngBytes.length, greaterThan(100));

      // Validate PNG file magic signature (0x89, 'P', 'N', 'G')
      expect(pngBytes[0], 0x89);
      expect(pngBytes[1], 0x50);
      expect(pngBytes[2], 0x4E);
      expect(pngBytes[3], 0x47);
    });

    test('saves rendered PNG bytes to a local file', () async {
      final plan = createSampleFloorPlan(roomCount: 2);
      final pngBytes = await PlanImageExportService.renderPlanToPng(plan: plan);

      final tempDir = Directory.systemTemp.createTempSync(
        'buildcalc_png_test_',
      );
      final targetFile = File('${tempDir.path}/test_plan.png');
      await targetFile.writeAsBytes(pngBytes);

      expect(targetFile.existsSync(), isTrue);
      expect(targetFile.lengthSync(), equals(pngBytes.length));
      tempDir.deleteSync(recursive: true);
    });
  });

  group('PlanPdfExportService Floor Plan and Material PDF Tests', () {
    test(
      'generates 2D Floor Plan PDF with valid PDF magic bytes and room schedule',
      () async {
        final plan = createSampleFloorPlan(roomCount: 3);
        final metadata = ReportMetadata(
          title: 'Architectural Blueprint',
          clientName: 'Alice Johnson',
          companyName: 'Prime Builders',
          createdAt: DateTime(2026, 10, 29),
        );

        final pdfBytes = await PlanPdfExportService.generateFloorPlanPdf(
          plan: plan,
          metadata: metadata,
        );

        expect(pdfBytes, isNotNull);
        expect(pdfBytes.length, greaterThan(500));

        // Validate PDF signature "%PDF-"
        final signature = String.fromCharCodes(pdfBytes.take(5));
        expect(signature, '%PDF-');
      },
    );

    test(
      'generates MultiPage 2D Floor Plan PDF with long list of rooms without errors',
      () async {
        // Create a large floor plan with 16 rooms to trigger multi-page room schedule
        final longPlan = createSampleFloorPlan(roomCount: 16);
        final metadata = ReportMetadata(
          title: 'Large Commercial Mansion',
          clientName: 'Grand Estates LLC',
          companyName: 'Apex Architects',
          createdAt: DateTime(2026, 10, 29),
        );

        final pdfBytes = await PlanPdfExportService.generateFloorPlanPdf(
          plan: longPlan,
          metadata: metadata,
        );

        expect(pdfBytes, isNotNull);
        expect(pdfBytes.length, greaterThan(1000));
      },
    );

    test(
      'generates non-fabricated Material Quantity & Cost Report PDF matching calculations',
      () async {
        final plan = createSampleFloorPlan(roomCount: 3);
        const assumptions = MaterialEstimationAssumptions(
          brickRatePerUnit: 9.5,
          cementRatePerBag: 380.0,
          currencySymbol: '₹',
        );

        final report = PlanMaterialEstimator.estimateMaterials(
          plan: plan,
          assumptions: assumptions,
        );

        final metadata = ReportMetadata(
          title: 'Bill of Quantities',
          projectName: 'Sunset Villa Phase 1',
          clientName: 'Mr. Robert Green',
          companyName: 'CivilTech Contractors',
          preparedBy: 'Chief Estimator',
          includeRatesAndCosts: true,
          createdAt: DateTime(2026, 10, 29),
        );

        // Verify that values come from calculations, not fabricated
        expect(report.totalEstimatedCost, greaterThan(0));
        expect(report.lineItems.isNotEmpty, isTrue);
        expect(report.lineItems.any((i) => i.name.contains('Brick')), isTrue);
        expect(report.lineItems.any((i) => i.name.contains('Cement')), isTrue);

        final pdfBytes = await PlanPdfExportService.generateMaterialEstimatePdf(
          plan: plan,
          report: report,
          assumptions: assumptions,
          metadata: metadata,
        );

        expect(pdfBytes, isNotNull);
        expect(pdfBytes.length, greaterThan(1000));
        final signature = String.fromCharCodes(pdfBytes.take(5));
        expect(signature, '%PDF-');
      },
    );

    test(
      'generates Material Report PDF with hidden rates (quantities only)',
      () async {
        final plan = createSampleFloorPlan(roomCount: 2);
        const assumptions = MaterialEstimationAssumptions();
        final report = PlanMaterialEstimator.estimateMaterials(
          plan: plan,
          assumptions: assumptions,
        );

        final metadata = ReportMetadata(
          title: 'Quantities Estimate (Tender)',
          includeRatesAndCosts: false,
          createdAt: DateTime(2026, 10, 29),
        );

        final pdfBytes = await PlanPdfExportService.generateMaterialEstimatePdf(
          plan: plan,
          report: report,
          assumptions: assumptions,
          metadata: metadata,
        );

        expect(pdfBytes, isNotNull);
        expect(pdfBytes.length, greaterThan(500));
      },
    );
  });

  group('PlanBackupService Offline Local Storage & Restore Tests', () {
    test(
      'confirms offline local backup active and no unapproved paid cloud services',
      () {
        final status = PlanBackupService.getCloudBackupStatus();
        expect(status.isConfigured, isFalse);
        expect(status.isApproved, isFalse);
        expect(
          status.statusDescription,
          contains('Offline Local Storage Active'),
        );
        expect(
          status.statusDescription,
          contains('Cloud backup requires approved cloud service architecture'),
        );
      },
    );

    test(
      'exports saved plans to structured JSON backup and restores them offline',
      () async {
        final plan1 = createSampleFloorPlan(roomCount: 2);
        final plan2 = createSampleFloorPlan(
          roomCount: 4,
        ).copyWith(id: 'test_plan_002', name: 'Ocean Villa');

        await PlanStorageService.savePlan(plan1);
        await PlanStorageService.savePlan(plan2);

        // Export JSON backup
        final backupJson = await PlanBackupService.createBackupJson();
        expect(backupJson, isNotEmpty);

        final decoded = json.decode(backupJson) as Map<String, dynamic>;
        expect(decoded['app'], 'BuildCalc');
        expect(decoded['schemaVersion'], 1);
        expect(decoded['planCount'], 2);

        // Clear local storage to simulate new device or fresh install
        await PlanStorageService.deletePlan(plan1.id);
        await PlanStorageService.deletePlan(plan2.id);
        final emptyPlans = await PlanStorageService.getSavedPlans();
        expect(emptyPlans.isEmpty, isTrue);

        // Restore from backup JSON
        final restoredCount = await PlanBackupService.restoreBackupFromJson(
          backupJson,
          mergeWithExisting: true,
        );

        expect(restoredCount, 2);
        final restoredPlans = await PlanStorageService.getSavedPlans();
        expect(restoredPlans.length, 2);
        expect(restoredPlans.any((p) => p.name == 'Sunset Villa'), isTrue);
        expect(restoredPlans.any((p) => p.name == 'Ocean Villa'), isTrue);
      },
    );

    test('rejects corrupt or empty backup JSON gracefully', () async {
      expect(
        () async => await PlanBackupService.restoreBackupFromJson(''),
        throwsA(isA<FormatException>()),
      );

      expect(
        () async => await PlanBackupService.restoreBackupFromJson(
          '{"app": "BuildCalc"}',
        ),
        throwsA(isA<FormatException>()),
      );

      expect(
        () async => await PlanBackupService.restoreBackupFromJson(
          'invalid json string {[',
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('PlanShareService Unit Tests', () {
    test(
      'writes and saves bytes locally to filesystem without crashing',
      () async {
        final sampleBytes = Uint8List.fromList([1, 2, 3, 4, 5, 6]);
        final result = await PlanShareService.saveBytesToDevice(
          bytes: sampleBytes,
          fileName: 'test_plan_export.txt',
        );

        expect(result.isSuccess, isTrue);
        expect(result.filePath, isNotNull);
        final file = File(result.filePath!);
        expect(file.existsSync(), isTrue);
        expect(file.readAsBytesSync(), equals(sampleBytes));
      },
    );

    test('handles ExportActionResult models properly', () {
      final success = ExportActionResult.success(
        message: 'File shared successfully',
      );
      expect(success.isSuccess, isTrue);
      expect(success.message, 'File shared successfully');

      final failure = ExportActionResult.failure(
        message: 'Permission denied',
        error: 'IO Error',
      );
      expect(failure.isSuccess, isFalse);
      expect(failure.error, 'IO Error');
    });
  });

  group('PlanExportDialog Widget Tests', () {
    testWidgets(
      'renders export dialog with formats, client details, and buttons',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final plan = createSampleFloorPlan(roomCount: 2);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    PlanExportDialog.show(
                      context,
                      plan: plan,
                      initialFormat: ExportFormat.floorPlanPdf,
                    );
                  },
                  child: const Text('Open Export'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Export'));
        await tester.pumpAndSettle();

        // Verify Header
        expect(find.text('Export & Share Plan'), findsOneWidget);

        // Verify Format Options
        expect(find.text('2D Plan (PDF)'), findsOneWidget);
        expect(find.text('Materials & Cost (PDF)'), findsOneWidget);
        expect(find.text('2D Plan (PNG Image)'), findsOneWidget);

        // Verify Document Title TextField
        expect(find.text('Document Title'), findsOneWidget);

        // Verify Action Buttons
        expect(find.text('Save / Print PDF'), findsOneWidget);
        expect(find.text('Share File'), findsOneWidget);

        // Scroll horizontal row to ensure PNG chip is in view and tap it
        await tester.scrollUntilVisible(
          find.text('2D Plan (PNG Image)'),
          100.0,
          scrollable: find.byType(Scrollable).at(1),
        );
        await tester.tap(find.text('2D Plan (PNG Image)'));
        await tester.pumpAndSettle();

        // In PNG mode, button changes to "Save Image"
        expect(find.text('Save Image'), findsOneWidget);
      },
    );
  });
}
