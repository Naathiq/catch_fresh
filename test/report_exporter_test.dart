import 'package:flutter_test/flutter_test.dart';
import 'package:catch_fresh/monthly_report_view.dart';
import 'package:catch_fresh/report_exporter.dart';

void main() {
  test('ReportExporter generates valid non-empty CSV and PDF for milestones', () async {
    final records = [
      MilestoneRecord(
        key: '2026-10-20_06-00',
        date: '2026-10-20',
        time: '06:00',
        milestoneSlot: '06:00',
        milestoneName: 'Morning',
        temperature: 27.8,
        tds: 215.0,
        ph: 7.5,
        relays: {'1': true, '2': false, '3': false, '4': false},
        timestamp: 1792475794665,
      ),
      MilestoneRecord(
        key: '2026-10-20_12-00',
        date: '2026-10-20',
        time: '12:00',
        milestoneSlot: '12:00',
        milestoneName: 'Midday',
        temperature: 29.2,
        tds: 220.0,
        ph: 7.8,
        relays: {'1': true, '2': true, '3': false, '4': false},
        timestamp: 1792475794665,
      ),
    ];

    // Test CSV generation
    final csv = ReportExporter.generateCsvString(records);
    expect(csv.contains('Date,Time,Milestone,Temperature(°C),TDS(ppm),pH,Pump1,Pump2,Relay3,Relay4'), isTrue);
    expect(csv.contains('2026-10-20,06:00,Morning,27.8,215.0,7.5,ON,OFF,OFF,OFF'), isTrue);

    // Test PDF generation
    final pdfBytes = await ReportExporter.generatePdf(
      monthLabel: 'October 2026',
      monthKey: '2026-10',
      records: records,
      avgTemp: 28.5,
      minTemp: 27.8,
      maxTemp: 29.2,
      avgTds: 217.5,
      minTds: 215.0,
      maxTds: 220.0,
      avgPh: 7.65,
      minPh: 7.5,
      maxPh: 7.8,
      relayNames: {'1': 'Pump 1', '2': 'Aerator'},
    );

    expect(pdfBytes, isNotNull);
    expect(pdfBytes.length, greaterThan(1000)); // Real PDF bytes > 1KB
  });
}
