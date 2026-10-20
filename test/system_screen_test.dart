import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:catch_fresh/system_screen.dart';

void main() {
  testWidgets('SystemScreen displays relay interface with logos and opens logo picker', (WidgetTester tester) async {
    final relayNames = {'1': 'Pump 1', '2': 'Aerator', '3': 'Lights', '4': 'Heater'};
    final relayIcons = {'1': 'water_drop', '2': 'air', '3': 'lightbulb', '4': 'thermostat'};

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SystemScreen(
            liveData: const {'online': true},
            isConnected: true,
            relayNames: relayNames,
            relayIcons: relayIcons,
            onSettingsChanged: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Personalization header and Relay Interface section
    expect(find.text('Personalization'), findsOneWidget);
    expect(find.text('Relay Interface'), findsOneWidget);
    expect(find.textContaining('Logos'), findsOneWidget);

    // Verify all 4 relay name fields
    expect(find.text('Relay 1 Name'), findsOneWidget);
    expect(find.text('Relay 2 Name'), findsOneWidget);
    expect(find.text('Relay 3 Name'), findsOneWidget);
    expect(find.text('Relay 4 Name'), findsOneWidget);

    // Tap the first relay logo selector button (it has a Tooltip)
    final logoButton = find.byTooltip('Tap to change logo (Current: Water Pump)');
    expect(logoButton, findsOneWidget);
    await tester.tap(logoButton);
    await tester.pumpAndSettle();

    // Verify the modal sheet opens
    expect(find.text('Choose Relay Logo'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Water'), findsWidgets);
    expect(find.text('Lighting'), findsWidgets);
  });
}
