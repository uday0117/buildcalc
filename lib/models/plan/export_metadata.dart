import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Metadata for customized export reports (2D Floor Plan and Material Estimations).
class ReportMetadata {
  static const String _companyDetailsKey = 'buildcalc_export_company_details';

  final String title;
  final String projectName;
  final String clientName;
  final String clientPhone;
  final String clientEmail;
  final String companyName;
  final String companyAddress;
  final String companyPhone;
  final String companyEmail;
  final String preparedBy;
  final String projectLocation;
  final String notes;
  final bool includeRatesAndCosts;
  final DateTime createdAt;

  const ReportMetadata({
    this.title = 'BuildCalc Floor Plan & Estimate',
    this.projectName = '',
    this.clientName = '',
    this.clientPhone = '',
    this.clientEmail = '',
    this.companyName = '',
    this.companyAddress = '',
    this.companyPhone = '',
    this.companyEmail = '',
    this.preparedBy = '',
    this.projectLocation = '',
    this.notes = '',
    this.includeRatesAndCosts = true,
    required this.createdAt,
  });

  ReportMetadata copyWith({
    String? title,
    String? projectName,
    String? clientName,
    String? clientPhone,
    String? clientEmail,
    String? companyName,
    String? companyAddress,
    String? companyPhone,
    String? companyEmail,
    String? preparedBy,
    String? projectLocation,
    String? notes,
    bool? includeRatesAndCosts,
    DateTime? createdAt,
  }) {
    return ReportMetadata(
      title: title ?? this.title,
      projectName: projectName ?? this.projectName,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      clientEmail: clientEmail ?? this.clientEmail,
      companyName: companyName ?? this.companyName,
      companyAddress: companyAddress ?? this.companyAddress,
      companyPhone: companyPhone ?? this.companyPhone,
      companyEmail: companyEmail ?? this.companyEmail,
      preparedBy: preparedBy ?? this.preparedBy,
      projectLocation: projectLocation ?? this.projectLocation,
      notes: notes ?? this.notes,
      includeRatesAndCosts: includeRatesAndCosts ?? this.includeRatesAndCosts,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get hasClientDetails =>
      clientName.trim().isNotEmpty ||
      clientPhone.trim().isNotEmpty ||
      clientEmail.trim().isNotEmpty;

  bool get hasCompanyDetails =>
      companyName.trim().isNotEmpty ||
      companyAddress.trim().isNotEmpty ||
      companyPhone.trim().isNotEmpty ||
      companyEmail.trim().isNotEmpty ||
      preparedBy.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
    'title': title,
    'projectName': projectName,
    'clientName': clientName,
    'clientPhone': clientPhone,
    'clientEmail': clientEmail,
    'companyName': companyName,
    'companyAddress': companyAddress,
    'companyPhone': companyPhone,
    'companyEmail': companyEmail,
    'preparedBy': preparedBy,
    'projectLocation': projectLocation,
    'notes': notes,
    'includeRatesAndCosts': includeRatesAndCosts,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ReportMetadata.fromJson(Map<String, dynamic> json) => ReportMetadata(
    title: json['title'] as String? ?? 'BuildCalc Floor Plan & Estimate',
    projectName: json['projectName'] as String? ?? '',
    clientName: json['clientName'] as String? ?? '',
    clientPhone: json['clientPhone'] as String? ?? '',
    clientEmail: json['clientEmail'] as String? ?? '',
    companyName: json['companyName'] as String? ?? '',
    companyAddress: json['companyAddress'] as String? ?? '',
    companyPhone: json['companyPhone'] as String? ?? '',
    companyEmail: json['companyEmail'] as String? ?? '',
    preparedBy: json['preparedBy'] as String? ?? '',
    projectLocation: json['projectLocation'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
    includeRatesAndCosts: json['includeRatesAndCosts'] as bool? ?? true,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
        : DateTime.now(),
  );

  /// Saves the company / professional details to preferences for reuse in future exports.
  static Future<void> saveDefaultCompanyDetails({
    required String companyName,
    required String companyAddress,
    required String companyPhone,
    required String companyEmail,
    required String preparedBy,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'companyName': companyName,
      'companyAddress': companyAddress,
      'companyPhone': companyPhone,
      'companyEmail': companyEmail,
      'preparedBy': preparedBy,
    };
    await prefs.setString(_companyDetailsKey, json.encode(data));
  }

  /// Loads saved company / professional details from preferences.
  static Future<Map<String, String>> loadDefaultCompanyDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_companyDetailsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = json.decode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }
}
