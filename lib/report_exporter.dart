import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'monthly_report_view.dart';
import 'platform_helper.dart';

class ReportExporter {
  /// Generates a clean, professional PDF document for the monthly aquaculture report
  static Future<Uint8List> generatePdf({
    required String monthLabel,
    required String monthKey,
    required List<MilestoneRecord> records,
    required double avgTemp,
    required double minTemp,
    required double maxTemp,
    required double avgTds,
    required double minTds,
    required double maxTds,
    required double avgPh,
    required double minPh,
    required double maxPh,
    Map<String, String>? relayNames,
  }) async {
    final pdf = pw.Document();

    final pump1Name = relayNames?['1'] ?? 'Pump 1';
    final pump2Name = relayNames?['2'] ?? 'Aerator';

    // Aquaculture Status strings
    final tempStatus = avgTemp >= 24 && avgTemp <= 32 ? 'Optimal (24-32°C)' : 'Requires Monitoring';
    final tdsStatus = avgTds < 500 ? 'Freshwater Safe (<500 ppm)' : 'Elevated TDS';
    final phStatus = avgPh >= 6.8 && avgPh <= 8.5 ? 'Balanced (6.8-8.5 pH)' : 'Critical Range';

    final nowStr = DateTime.now().toLocal().toString().split('.').first;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'CATCH FRESH AQUACULTURE',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal800,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Monthly Water Quality & Milestone Audit Report',
                        style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.teal50,
                          borderRadius: pw.BorderRadius.circular(6),
                          border: pw.Border.all(color: PdfColors.teal600, width: 0.8),
                        ),
                        child: pw.Text(
                          monthLabel.toUpperCase(),
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Exported: $nowStr',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Divider(color: PdfColors.teal800, thickness: 1.5),
              pw.SizedBox(height: 8),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(color: PdfColors.grey300),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Catch Fresh Smart IoT Aquaculture | Autonomous Cloud Logger',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // KPI Summary Cards
            pw.Text(
              'EXECUTIVE MONTHLY SUMMARY',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _buildTableCell('Parameter', isHeader: true),
                    _buildTableCell('Monthly Avg', isHeader: true),
                    _buildTableCell('Observed Range (Min - Max)', isHeader: true),
                    _buildTableCell('Compliance Status', isHeader: true),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _buildTableCell('Water Temperature'),
                    _buildTableCell('${avgTemp.toStringAsFixed(1)} °C', isBold: true),
                    _buildTableCell('${minTemp.toStringAsFixed(1)} °C - ${maxTemp.toStringAsFixed(1)} °C'),
                    _buildTableCell(tempStatus, textColor: PdfColors.green800),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _buildTableCell('Total Dissolved Solids (TDS)'),
                    _buildTableCell('${avgTds.toStringAsFixed(0)} ppm', isBold: true),
                    _buildTableCell('${minTds.toStringAsFixed(0)} ppm - ${maxTds.toStringAsFixed(0)} ppm'),
                    _buildTableCell(tdsStatus, textColor: PdfColors.teal800),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _buildTableCell('pH Balance (Acidity/Alkalinity)'),
                    _buildTableCell(avgPh.toStringAsFixed(2), isBold: true),
                    _buildTableCell('${minPh.toStringAsFixed(2)} - ${maxPh.toStringAsFixed(2)}'),
                    _buildTableCell(phStatus, textColor: PdfColors.purple800),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _buildTableCell('Milestone Snapshots Recorded'),
                    _buildTableCell('${records.length} points', isBold: true),
                    _buildTableCell('4 Daily Milestones (06:00, 12:00, 18:00, 00:00)'),
                    _buildTableCell('Cloud Auto-Synced', textColor: PdfColors.blue800),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Milestones Table
            pw.Text(
              'DETAILED MILESTONE TELEMETRY LOG (${records.length} RECORDS)',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.2), // Date
                1: const pw.FlexColumnWidth(1.6), // Time
                2: const pw.FlexColumnWidth(2.0), // Milestone
                3: const pw.FlexColumnWidth(1.8), // Temp
                4: const pw.FlexColumnWidth(1.8), // TDS
                5: const pw.FlexColumnWidth(1.6), // pH
                6: const pw.FlexColumnWidth(1.5), // Pump 1
                7: const pw.FlexColumnWidth(1.5), // Aerator
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.teal700),
                  children: [
                    _buildTableCell('Date', isHeader: true, textColor: PdfColors.white),
                    _buildTableCell('Time', isHeader: true, textColor: PdfColors.white),
                    _buildTableCell('Slot', isHeader: true, textColor: PdfColors.white),
                    _buildTableCell('Temp', isHeader: true, textColor: PdfColors.white),
                    _buildTableCell('TDS', isHeader: true, textColor: PdfColors.white),
                    _buildTableCell('pH', isHeader: true, textColor: PdfColors.white),
                    _buildTableCell(pump1Name, isHeader: true, textColor: PdfColors.white),
                    _buildTableCell(pump2Name, isHeader: true, textColor: PdfColors.white),
                  ],
                ),
                ...records.map((r) {
                  final p1On = r.relays['1'] == true;
                  final p2On = r.relays['2'] == true;

                  return pw.TableRow(
                    children: [
                      _buildTableCell(r.date),
                      _buildTableCell(r.time),
                      _buildTableCell(r.milestoneName),
                      _buildTableCell('${r.temperature.toStringAsFixed(1)}°C'),
                      _buildTableCell('${r.tds.toStringAsFixed(0)} ppm'),
                      _buildTableCell(r.ph.toStringAsFixed(2)),
                      _buildTableCell(p1On ? 'ON' : 'OFF', textColor: p1On ? PdfColors.green800 : PdfColors.grey600),
                      _buildTableCell(p2On ? 'ON' : 'OFF', textColor: p2On ? PdfColors.green800 : PdfColors.grey600),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 24),

            // Sign-off / Verification box
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Farm Manager Signature: __________________________', style: const pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(height: 8),
                      pw.Text('Date of Verification: __________________________', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Facility / Tank ID: Pond #01 - Catch Fresh', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.SizedBox(height: 8),
                      pw.Text('Audit Status: VERIFIED AUTOMATED TELEMETRY', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
                    ],
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    PdfColor? textColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 8.5 : 8,
          fontWeight: isHeader || isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor ?? (isHeader ? PdfColors.black : PdfColors.grey900),
        ),
      ),
    );
  }

  /// Triggers 1-Click PDF Download / Print Preview
  static Future<void> downloadPdf({
    required String monthLabel,
    required String monthKey,
    required List<MilestoneRecord> records,
    required double avgTemp,
    required double minTemp,
    required double maxTemp,
    required double avgTds,
    required double minTds,
    required double maxTds,
    required double avgPh,
    required double minPh,
    required double maxPh,
    Map<String, String>? relayNames,
  }) async {
    final pdfBytes = await generatePdf(
      monthLabel: monthLabel,
      monthKey: monthKey,
      records: records,
      avgTemp: avgTemp,
      minTemp: minTemp,
      maxTemp: maxTemp,
      avgTds: avgTds,
      minTds: minTds,
      maxTds: maxTds,
      avgPh: avgPh,
      minPh: minPh,
      maxPh: maxPh,
      relayNames: relayNames,
    );

    if (kIsWeb) {
      PlatformHelper.downloadFile(
        pdfBytes,
        'Catch_Fresh_Report_$monthKey.pdf',
        'application/pdf',
      );
      return;
    }

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Catch_Fresh_Report_$monthKey.pdf',
    );
  }

  /// Generates clean CSV string
  static String generateCsvString(List<MilestoneRecord> records) {
    final buffer = StringBuffer();
    buffer.writeln('Date,Time,Milestone,Temperature(°C),TDS(ppm),pH,Pump1,Pump2,Relay3,Relay4');

    for (final r in records) {
      final r1 = r.relays['1'] == true ? 'ON' : 'OFF';
      final r2 = r.relays['2'] == true ? 'ON' : 'OFF';
      final r3 = r.relays['3'] == true ? 'ON' : 'OFF';
      final r4 = r.relays['4'] == true ? 'ON' : 'OFF';
      buffer.writeln('${r.date},${r.time},${r.milestoneName},${r.temperature},${r.tds},${r.ph},$r1,$r2,$r3,$r4');
    }

    return buffer.toString();
  }

  /// Triggers 1-Click Excel / CSV Download
  static Future<void> downloadExcelCsv({
    required String monthKey,
    required List<MilestoneRecord> records,
  }) async {
    final csvContent = generateCsvString(records);
    final bytes = Uint8List.fromList(utf8.encode(csvContent));

    // Also copy to clipboard for convenience
    Clipboard.setData(ClipboardData(text: csvContent));

    if (kIsWeb) {
      PlatformHelper.downloadFile(
        bytes,
        'Catch_Fresh_Report_$monthKey.csv',
        'text/csv;charset=utf-8',
      );
      return;
    }

    // Opens file download / share
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Catch_Fresh_Report_$monthKey.csv',
    );
  }
}
