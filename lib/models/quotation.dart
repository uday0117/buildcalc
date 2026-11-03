import 'package:flutter/foundation.dart';

class QuotationItem {
  final String id;
  final String description;
  final double quantity;
  final String unit;
  final double unitPrice;

  const QuotationItem({
    required this.id,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'quantity': quantity,
        'unit': unit,
        'unitPrice': unitPrice,
      };

  factory QuotationItem.fromJson(Map<String, dynamic> json) => QuotationItem(
        id: json['id'] ?? '',
        description: json['description'] ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
        unit: json['unit'] ?? 'pcs',
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      );

  QuotationItem copyWith({
    String? id,
    String? description,
    double? quantity,
    String? unit,
    double? unitPrice,
  }) =>
      QuotationItem(
        id: id ?? this.id,
        description: description ?? this.description,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        unitPrice: unitPrice ?? this.unitPrice,
      );
}

@immutable
class Quotation {
  final String id;
  final String quoteNumber;
  final DateTime date;
  final DateTime? validUntil;

  // Contractor Business Info
  final String contractorName;
  final String contractorPhone;
  final String contractorEmail;
  final String contractorAddress;

  // Client Info
  final String clientName;
  final String clientPhone;
  final String projectName;
  final String projectLocation;

  // Items & Financials
  final List<QuotationItem> items;
  final double taxPercent;
  final double discountAmount;
  final String currencySymbol;
  final String notes;
  final String status; // 'Draft', 'Sent', 'Approved', 'Completed'

  const Quotation({
    required this.id,
    required this.quoteNumber,
    required this.date,
    this.validUntil,
    required this.contractorName,
    required this.contractorPhone,
    this.contractorEmail = '',
    this.contractorAddress = '',
    required this.clientName,
    this.clientPhone = '',
    required this.projectName,
    this.projectLocation = '',
    required this.items,
    this.taxPercent = 0.0,
    this.discountAmount = 0.0,
    this.currencySymbol = '\$',
    this.notes = '',
    this.status = 'Draft',
  });

  double get subtotal =>
      items.fold(0.0, (previousValue, item) => previousValue + item.total);

  double get taxAmount => (subtotal - discountAmount) > 0
      ? (subtotal - discountAmount) * (taxPercent / 100.0)
      : 0.0;

  double get grandTotal {
    final discounted = subtotal - discountAmount;
    final total = (discounted > 0 ? discounted : 0.0) + taxAmount;
    return total > 0 ? total : 0.0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'quoteNumber': quoteNumber,
        'date': date.toIso8601String(),
        'validUntil': validUntil?.toIso8601String(),
        'contractorName': contractorName,
        'contractorPhone': contractorPhone,
        'contractorEmail': contractorEmail,
        'contractorAddress': contractorAddress,
        'clientName': clientName,
        'clientPhone': clientPhone,
        'projectName': projectName,
        'projectLocation': projectLocation,
        'items': items.map((i) => i.toJson()).toList(),
        'taxPercent': taxPercent,
        'discountAmount': discountAmount,
        'currencySymbol': currencySymbol,
        'notes': notes,
        'status': status,
      };

  factory Quotation.fromJson(Map<String, dynamic> json) => Quotation(
        id: json['id'] ?? '',
        quoteNumber: json['quoteNumber'] ?? '',
        date: json['date'] != null
            ? DateTime.tryParse(json['date']) ?? DateTime.now()
            : DateTime.now(),
        validUntil: json['validUntil'] != null
            ? DateTime.tryParse(json['validUntil'])
            : null,
        contractorName: json['contractorName'] ?? '',
        contractorPhone: json['contractorPhone'] ?? '',
        contractorEmail: json['contractorEmail'] ?? '',
        contractorAddress: json['contractorAddress'] ?? '',
        clientName: json['clientName'] ?? '',
        clientPhone: json['clientPhone'] ?? '',
        projectName: json['projectName'] ?? '',
        projectLocation: json['projectLocation'] ?? '',
        items: (json['items'] as List<dynamic>?)
                ?.map((i) => QuotationItem.fromJson(Map<String, dynamic>.from(i)))
                .toList() ??
            [],
        taxPercent: (json['taxPercent'] as num?)?.toDouble() ?? 0.0,
        discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
        currencySymbol: json['currencySymbol'] ?? '\$',
        notes: json['notes'] ?? '',
        status: json['status'] ?? 'Draft',
      );

  Quotation copyWith({
    String? id,
    String? quoteNumber,
    DateTime? date,
    DateTime? validUntil,
    String? contractorName,
    String? contractorPhone,
    String? contractorEmail,
    String? contractorAddress,
    String? clientName,
    String? clientPhone,
    String? projectName,
    String? projectLocation,
    List<QuotationItem>? items,
    double? taxPercent,
    double? discountAmount,
    String? currencySymbol,
    String? notes,
    String? status,
  }) =>
      Quotation(
        id: id ?? this.id,
        quoteNumber: quoteNumber ?? this.quoteNumber,
        date: date ?? this.date,
        validUntil: validUntil ?? this.validUntil,
        contractorName: contractorName ?? this.contractorName,
        contractorPhone: contractorPhone ?? this.contractorPhone,
        contractorEmail: contractorEmail ?? this.contractorEmail,
        contractorAddress: contractorAddress ?? this.contractorAddress,
        clientName: clientName ?? this.clientName,
        clientPhone: clientPhone ?? this.clientPhone,
        projectName: projectName ?? this.projectName,
        projectLocation: projectLocation ?? this.projectLocation,
        items: items ?? this.items,
        taxPercent: taxPercent ?? this.taxPercent,
        discountAmount: discountAmount ?? this.discountAmount,
        currencySymbol: currencySymbol ?? this.currencySymbol,
        notes: notes ?? this.notes,
        status: status ?? this.status,
      );
}

