import 'package:flutter/material.dart';

/// Metadata for a relay icon/logo option.
class RelayIconItem {
  final String key;
  final String label;
  final String category;
  final IconData icon;

  const RelayIconItem({
    required this.key,
    required this.label,
    required this.category,
    required this.icon,
  });
}

/// Comprehensive collection of specialized logos for relays.
const List<RelayIconItem> kRelayIcons = [
  // -------------------------------------------------------------
  // WATER & LIQUID MANAGEMENT
  // -------------------------------------------------------------
  RelayIconItem(key: 'water_drop', label: 'Water Pump', category: 'Water', icon: Icons.water_drop),
  RelayIconItem(key: 'water', label: 'Water Flow', category: 'Water', icon: Icons.water),
  RelayIconItem(key: 'waves', label: 'Wavemaker', category: 'Water', icon: Icons.waves),
  RelayIconItem(key: 'shower', label: 'Spray / Sprinkler', category: 'Water', icon: Icons.shower),
  RelayIconItem(key: 'opacity', label: 'Misting / Humidity', category: 'Water', icon: Icons.opacity),
  RelayIconItem(key: 'pool', label: 'Reservoir / Tank', category: 'Water', icon: Icons.pool),
  RelayIconItem(key: 'plumbing', label: 'Valve / Plumbing', category: 'Water', icon: Icons.plumbing),
  RelayIconItem(key: 'bubble_chart', label: 'Bubbler / CO2', category: 'Water', icon: Icons.bubble_chart),
  RelayIconItem(key: 'water_damage', label: 'Drain / Flood Alert', category: 'Water', icon: Icons.water_damage),
  RelayIconItem(key: 'grain', label: 'Fine Droplets', category: 'Water', icon: Icons.grain),
  RelayIconItem(key: 'soup_kitchen', label: 'Sump Pump', category: 'Water', icon: Icons.soup_kitchen),
  RelayIconItem(key: 'sync', label: 'Recirculation', category: 'Water', icon: Icons.sync),
  RelayIconItem(key: 'loop', label: 'Cycle Pump', category: 'Water', icon: Icons.loop),

  // -------------------------------------------------------------
  // AIR, AERATION & FANS
  // -------------------------------------------------------------
  RelayIconItem(key: 'air', label: 'Air Pump', category: 'Air & Fans', icon: Icons.air),
  RelayIconItem(key: 'wind_power', label: 'Blower / Air Flow', category: 'Air & Fans', icon: Icons.wind_power),
  RelayIconItem(key: 'toys', label: 'Fan / Propeller', category: 'Air & Fans', icon: Icons.toys),
  RelayIconItem(key: 'cyclone', label: 'Skimmer / Vortex', category: 'Air & Fans', icon: Icons.cyclone),
  RelayIconItem(key: 'hvac', label: 'Ventilation / HVAC', category: 'Air & Fans', icon: Icons.hvac),
  RelayIconItem(key: 'mode_fan_off', label: 'Exhaust Fan', category: 'Air & Fans', icon: Icons.mode_fan_off),

  // -------------------------------------------------------------
  // LIGHTING & UV
  // -------------------------------------------------------------
  RelayIconItem(key: 'lightbulb', label: 'Main Lights', category: 'Lighting', icon: Icons.lightbulb),
  RelayIconItem(key: 'lightbulb_outline', label: 'Ambient Lamp', category: 'Lighting', icon: Icons.lightbulb_outline),
  RelayIconItem(key: 'wb_sunny', label: 'Daylight / Grow', category: 'Lighting', icon: Icons.wb_sunny),
  RelayIconItem(key: 'mode_night', label: 'Moonlight', category: 'Lighting', icon: Icons.mode_night),
  RelayIconItem(key: 'nightlight_round', label: 'Night Mode', category: 'Lighting', icon: Icons.nightlight_round),
  RelayIconItem(key: 'flare', label: 'UV Sterilizer', category: 'Lighting', icon: Icons.flare),
  RelayIconItem(key: 'fluorescent', label: 'Fluorescent / T5', category: 'Lighting', icon: Icons.fluorescent),
  RelayIconItem(key: 'highlight', label: 'Spotlight', category: 'Lighting', icon: Icons.highlight),
  RelayIconItem(key: 'light', label: 'Indicator Light', category: 'Lighting', icon: Icons.light),
  RelayIconItem(key: 'wb_twilight', label: 'Dusk / Twilight', category: 'Lighting', icon: Icons.wb_twilight),
  RelayIconItem(key: 'flash_on', label: 'Strobe / Flash', category: 'Lighting', icon: Icons.flash_on),
  RelayIconItem(key: 'brightness_high', label: 'High Brightness', category: 'Lighting', icon: Icons.brightness_high),
  RelayIconItem(key: 'brightness_low', label: 'Low Brightness', category: 'Lighting', icon: Icons.brightness_low),

  // -------------------------------------------------------------
  // TEMPERATURE, HEATING & COOLING
  // -------------------------------------------------------------
  RelayIconItem(key: 'thermostat', label: 'Thermostat', category: 'Temperature', icon: Icons.thermostat),
  RelayIconItem(key: 'device_thermostat', label: 'Temp Probe', category: 'Temperature', icon: Icons.device_thermostat),
  RelayIconItem(key: 'whatshot', label: 'Water Heater', category: 'Temperature', icon: Icons.whatshot),
  RelayIconItem(key: 'local_fire_department', label: 'Heating Element', category: 'Temperature', icon: Icons.local_fire_department),
  RelayIconItem(key: 'ac_unit', label: 'Chiller / Cooler', category: 'Temperature', icon: Icons.ac_unit),
  RelayIconItem(key: 'severe_cold', label: 'Deep Chiller', category: 'Temperature', icon: Icons.severe_cold),
  RelayIconItem(key: 'heat_pump', label: 'Heat Pump', category: 'Temperature', icon: Icons.heat_pump),

  // -------------------------------------------------------------
  // FILTRATION, SANITATION & CHEMISTRY
  // -------------------------------------------------------------
  RelayIconItem(key: 'filter_alt', label: 'Filter', category: 'Filtration', icon: Icons.filter_alt),
  RelayIconItem(key: 'science', label: 'Chemical Dosing', category: 'Filtration', icon: Icons.science),
  RelayIconItem(key: 'biotech', label: 'Biological Filter', category: 'Filtration', icon: Icons.biotech),
  RelayIconItem(key: 'sanitizer', label: 'Ozone / Sanitizer', category: 'Filtration', icon: Icons.sanitizer),
  RelayIconItem(key: 'cleaning_services', label: 'Auto Backwash', category: 'Filtration', icon: Icons.cleaning_services),
  RelayIconItem(key: 'clean_hands', label: 'Flush Cycle', category: 'Filtration', icon: Icons.clean_hands),
  RelayIconItem(key: 'wash', label: 'Drain / Wash', category: 'Filtration', icon: Icons.wash),
  RelayIconItem(key: 'vaccines', label: 'Buffer / Medicine', category: 'Filtration', icon: Icons.vaccines),

  // -------------------------------------------------------------
  // FEEDING, FISH & BIOLOGY
  // -------------------------------------------------------------
  RelayIconItem(key: 'set_meal', label: 'Fish Feeder', category: 'Biology & Feed', icon: Icons.set_meal),
  RelayIconItem(key: 'restaurant', label: 'Auto Feeder', category: 'Biology & Feed', icon: Icons.restaurant),
  RelayIconItem(key: 'egg', label: 'Hatchery / Nursery', category: 'Biology & Feed', icon: Icons.egg),
  RelayIconItem(key: 'eco', label: 'Aquaponics / Flora', category: 'Biology & Feed', icon: Icons.eco),
  RelayIconItem(key: 'grass', label: 'Algae Scrubber', category: 'Biology & Feed', icon: Icons.grass),
  RelayIconItem(key: 'pets', label: 'Aquaculture', category: 'Biology & Feed', icon: Icons.pets),
  RelayIconItem(key: 'cruelty_free', label: 'Marine Life', category: 'Biology & Feed', icon: Icons.cruelty_free),
  RelayIconItem(key: 'agriculture', label: 'Culture / Farm', category: 'Biology & Feed', icon: Icons.agriculture),

  // -------------------------------------------------------------
  // POWER, ELECTRICAL & GRID
  // -------------------------------------------------------------
  RelayIconItem(key: 'power', label: 'Main Power', category: 'Power', icon: Icons.power),
  RelayIconItem(key: 'power_settings_new', label: 'Power Toggle', category: 'Power', icon: Icons.power_settings_new),
  RelayIconItem(key: 'bolt', label: 'Electric Load', category: 'Power', icon: Icons.bolt),
  RelayIconItem(key: 'electrical_services', label: 'Mains Relay', category: 'Power', icon: Icons.electrical_services),
  RelayIconItem(key: 'outlet', label: 'AC Outlet', category: 'Power', icon: Icons.outlet),
  RelayIconItem(key: 'electric_meter', label: 'Power Monitor', category: 'Power', icon: Icons.electric_meter),
  RelayIconItem(key: 'solar_power', label: 'Solar Power', category: 'Power', icon: Icons.solar_power),
  RelayIconItem(key: 'battery_charging_full', label: 'Battery UPS', category: 'Power', icon: Icons.battery_charging_full),
  RelayIconItem(key: 'cable', label: 'Wiring / Cable', category: 'Power', icon: Icons.cable),

  // -------------------------------------------------------------
  // AUTOMATION, TIMERS & SAFETY
  // -------------------------------------------------------------
  RelayIconItem(key: 'timer', label: 'Timer Switch', category: 'Automation', icon: Icons.timer),
  RelayIconItem(key: 'alarm', label: 'Alarm Buzzer', category: 'Automation', icon: Icons.alarm),
  RelayIconItem(key: 'schedule', label: 'Schedule Cycle', category: 'Automation', icon: Icons.schedule),
  RelayIconItem(key: 'notifications', label: 'Notification Bell', category: 'Automation', icon: Icons.notifications),
  RelayIconItem(key: 'notifications_active', label: 'Siren / Alert', category: 'Automation', icon: Icons.notifications_active),
  RelayIconItem(key: 'campaign', label: 'Horn / Siren', category: 'Automation', icon: Icons.campaign),
  RelayIconItem(key: 'warning', label: 'Safety Interlock', category: 'Automation', icon: Icons.warning),
  RelayIconItem(key: 'sensors', label: 'Level Sensor', category: 'Automation', icon: Icons.sensors),
  RelayIconItem(key: 'speed', label: 'Speed Controller', category: 'Automation', icon: Icons.speed),
  RelayIconItem(key: 'settings', label: 'Actuator / Gear', category: 'Automation', icon: Icons.settings),
  RelayIconItem(key: 'build', label: 'Maintenance', category: 'Automation', icon: Icons.build),
  RelayIconItem(key: 'precision_manufacturing', label: 'Industrial Motor', category: 'Automation', icon: Icons.precision_manufacturing),
  RelayIconItem(key: 'memory', label: 'Microcontroller', category: 'Automation', icon: Icons.memory),
  RelayIconItem(key: 'shield', label: 'Surge Protection', category: 'Automation', icon: Icons.shield),
  RelayIconItem(key: 'lock', label: 'Lockout Switch', category: 'Automation', icon: Icons.lock),
  RelayIconItem(key: 'toggle_on', label: 'Solenoid Relay', category: 'Automation', icon: Icons.toggle_on),
  RelayIconItem(key: 'router', label: 'IoT Gateway', category: 'Automation', icon: Icons.router),
  RelayIconItem(key: 'radar', label: 'Radar Sensor', category: 'Automation', icon: Icons.radar),
  RelayIconItem(key: 'tune', label: 'Calibrator', category: 'Automation', icon: Icons.tune),
];

/// Quick lookup map from key string to IconData.
final Map<String, IconData> kRelayIconMap = {
  for (final item in kRelayIcons) item.key: item.icon,
};

/// Lookup an IconData by key with fallback to [Icons.power].
IconData getRelayIcon(String? key) {
  if (key == null || key.isEmpty) return Icons.power;
  return kRelayIconMap[key] ?? Icons.power;
}

/// Lookup friendly label by key.
String getRelayIconLabel(String? key) {
  if (key == null || key.isEmpty) return 'Power';
  for (final item in kRelayIcons) {
    if (item.key == key) return item.label;
  }
  return key;
}

/// All available categories for filtering.
final List<String> kRelayCategories = [
  'All',
  'Water',
  'Air & Fans',
  'Lighting',
  'Temperature',
  'Filtration',
  'Biology & Feed',
  'Power',
  'Automation',
];
