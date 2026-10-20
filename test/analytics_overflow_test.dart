import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:catch_fresh/analytics_screen.dart';
import 'package:catch_fresh/monthly_report_view.dart';

void main() {
  testWidgets('AnalyticsScreen renders without any RenderFlex overflow on small screens', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnalyticsScreen(
            liveData: {
              'temperature': 28.5,
              'compensatedVoltage': 2.124,
            },
            device02LiveData: {
              'voltage': 3.95,
            },
            relayNames: {
              '1': 'Pump 1',
              '2': 'Aerator',
              '3': 'Lights',
              '4': 'Heater',
            },
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Aquaculture Analytics'), findsOneWidget);
    expect(find.text('CLOUD SYNC'), findsOneWidget);
    expect(find.text('Monthly Report'), findsOneWidget);
    expect(find.text('Live Telemetry'), findsOneWidget);

    // Switch to Live Telemetry
    await tester.tap(find.text('Live Telemetry'));
    await tester.pumpAndSettle();

    expect(find.text('Factory Temperature'), findsOneWidget);
    expect(find.text('TDS Compensated Voltage'), findsOneWidget);
    expect(find.text('pH Raw Voltage (Device 02)'), findsOneWidget);
  });

  testWidgets('MonthlyReportView elements layout cleanly without overflow on narrow 320px screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MonthlyReportView(),
          ),
        ),
      ),
    );

    await tester.pump();
    // Verify no render flex assertion thrown
  });
}
