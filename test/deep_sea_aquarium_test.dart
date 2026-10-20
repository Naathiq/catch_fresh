import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:catch_fresh/deep_sea_aquarium.dart';
import 'package:catch_fresh/overview_screen.dart';

void main() {
  testWidgets('DeepSeaAquarium mounts, animates frames, and paints without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 300,
            child: DeepSeaAquarium(),
          ),
        ),
      ),
    );

    // Initial pump
    expect(find.byType(DeepSeaAquarium), findsOneWidget);

    // Advance animation by several frames and seconds
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 5));

    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('OverviewScreen displays Live Sensors hero card with DeepSeaAquarium background', (WidgetTester tester) async {
    final liveData = {
      'temperature': 27.4,
      'compensatedVoltage': 1.5,
      'relay1': true,
      'relay2': false,
    };
    final device02LiveData = {
      'voltage': 2.5, // Produces pH 7.00
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OverviewScreen(
            userName: 'Harvester',
            liveData: liveData,
            commandsData: const {},
            calibrationData: const {},
            tempCalibrationData: const {},
            device02LiveData: device02LiveData,
            phCalibrationData: const {},
            relayNames: const {'1': 'Filter', '2': 'Aerator'},
            relayIcons: const {'1': 'water_drop', '2': 'air'},
            onBookCutterTapped: () {},
          ),
        ),
      ),
    );

    // Initial pump
    await tester.pump();

    // Verify DeepSeaAquarium is inside the OverviewScreen
    expect(find.byType(DeepSeaAquarium), findsOneWidget);

    // Verify Live Sensors hero card data fields
    expect(find.text('LIVE SENSORS'), findsOneWidget);
    expect(find.text('Total Dissolved Solids'), findsOneWidget);
    expect(find.text('Temperature'), findsOneWidget);
    expect(find.text('Water pH'), findsOneWidget);

    // Verify animated sensor numbers settle
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('27.4'), findsOneWidget);
    expect(find.text('7.00'), findsOneWidget);
    expect(find.text('°C'), findsOneWidget);
    expect(find.text('ppm'), findsOneWidget);
  });
}
