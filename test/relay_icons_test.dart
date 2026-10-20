import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:catch_fresh/relay_icons.dart';

void main() {
  group('Relay Icons Tests', () {
    test('Contains extensive library of logos (> 70)', () {
      expect(kRelayIcons.length, greaterThan(70));
    });

    test('All keys in kRelayIcons are unique', () {
      final keys = kRelayIcons.map((e) => e.key).toList();
      final uniqueKeys = keys.toSet();
      expect(keys.length, equals(uniqueKeys.length));
    });

    test('All items have non-empty label, key, category, and icon', () {
      for (final item in kRelayIcons) {
        expect(item.key.isNotEmpty, isTrue);
        expect(item.label.isNotEmpty, isTrue);
        expect(item.category.isNotEmpty, isTrue);
        expect(item.icon, isNotNull);
      }
    });

    test('Preserves backward compatibility for original 10 icon keys', () {
      const originalKeys = [
        'power',
        'water_drop',
        'air',
        'lightbulb',
        'thermostat',
        'toys',
        'mode_night',
        'science',
        'bolt',
        'waves',
      ];
      for (final key in originalKeys) {
        expect(kRelayIconMap.containsKey(key), isTrue, reason: '$key should be present');
      }
    });

    test('getRelayIcon resolves existing keys and falls back to power', () {
      expect(getRelayIcon('water_drop'), equals(Icons.water_drop));
      expect(getRelayIcon('whatshot'), equals(Icons.whatshot));
      expect(getRelayIcon('ac_unit'), equals(Icons.ac_unit));
      expect(getRelayIcon('unknown_key'), equals(Icons.power));
      expect(getRelayIcon(null), equals(Icons.power));
    });

    test('getRelayIconLabel resolves friendly names and falls back safely', () {
      expect(getRelayIconLabel('water_drop'), equals('Water Pump'));
      expect(getRelayIconLabel('whatshot'), equals('Water Heater'));
      expect(getRelayIconLabel('ac_unit'), equals('Chiller / Cooler'));
      expect(getRelayIconLabel(null), equals('Power'));
    });

    test('All categories in kRelayCategories are valid', () {
      expect(kRelayCategories, contains('All'));
      expect(kRelayCategories, contains('Water'));
      expect(kRelayCategories, contains('Air & Fans'));
      expect(kRelayCategories, contains('Lighting'));
      expect(kRelayCategories, contains('Temperature'));
      expect(kRelayCategories, contains('Filtration'));
      expect(kRelayCategories, contains('Biology & Feed'));
      expect(kRelayCategories, contains('Power'));
      expect(kRelayCategories, contains('Automation'));
    });
  });
}
