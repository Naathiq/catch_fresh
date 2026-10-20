import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'overview_screen.dart';
import 'analytics_screen.dart'; // NEW
import 'calibration_screen.dart';
import 'cutters_screen.dart';   // NEW
import 'system_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  
  Map<dynamic, dynamic> _liveData = {};
  Map<dynamic, dynamic> _commandsData = {};
  Map<dynamic, dynamic> _calibrationData = {}; 
  Map<dynamic, dynamic> _tempCalibrationData = {}; 
  Map<dynamic, dynamic> _device02LiveData = {}; 
  Map<dynamic, dynamic> _phCalibrationData = {}; 
  bool _isConnected = false;

  String _userName = 'Admin';
  String? _customLogoBase64;
  Map<String, String> _relayNames = {'1': 'Pump 1', '2': 'Aerator', '3': 'Lights', '4': 'Heater'};
  Map<String, String> _relayIcons = {'1': 'water_drop', '2': 'air', '3': 'lightbulb', '4': 'thermostat'};

  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat(reverse: true);
    _setupDatabaseListeners();
    _loadLocalSettings();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Admin';
      _customLogoBase64 = prefs.getString('custom_logo');
      for (int i = 1; i <= 4; i++) {
        _relayNames[i.toString()] = prefs.getString('relay_name_$i') ?? _relayNames[i.toString()]!;
        _relayIcons[i.toString()] = prefs.getString('relay_icon_$i') ?? _relayIcons[i.toString()]!;
      }
    });
  }

  void _setupDatabaseListeners() {
    final db = FirebaseDatabase.instance;
    db.ref('device01/live').onValue.listen((event) {
      if (event.snapshot.value != null && mounted) setState(() { _liveData = event.snapshot.value as Map<dynamic, dynamic>; _isConnected = true; });
    });
    db.ref('device01/commands').onValue.listen((event) {
      if (event.snapshot.value != null && mounted) setState(() => _commandsData = event.snapshot.value as Map<dynamic, dynamic>);
    });
    db.ref('device01/calibration').onValue.listen((event) {
      if (event.snapshot.value != null && mounted) setState(() => _calibrationData = event.snapshot.value as Map<dynamic, dynamic>);
    });
    db.ref('device01/tempCalibration').onValue.listen((event) {
      if (event.snapshot.value != null && mounted) setState(() => _tempCalibrationData = event.snapshot.value as Map<dynamic, dynamic>);
    });
    db.ref('device02/live').onValue.listen((event) {
      if (event.snapshot.value != null && mounted) setState(() => _device02LiveData = event.snapshot.value as Map<dynamic, dynamic>);
    });
    db.ref('device02/calibration').onValue.listen((event) {
      if (event.snapshot.value != null && mounted) setState(() => _phCalibrationData = event.snapshot.value as Map<dynamic, dynamic>);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> views = [
      OverviewScreen(
        userName: _userName,
        liveData: _liveData, commandsData: _commandsData, 
        calibrationData: _calibrationData, tempCalibrationData: _tempCalibrationData,
        device02LiveData: _device02LiveData, phCalibrationData: _phCalibrationData,
        customLogo: _customLogoBase64, relayNames: _relayNames, relayIcons: _relayIcons,
        onBookCutterTapped: () => setState(() => _currentIndex = 3), // Switches to Cutter Tab!
      ),
      AnalyticsScreen(
        liveData: _liveData, 
        device02LiveData: _device02LiveData,
        relayNames: _relayNames,
      ), // TELEMETRY & MONTHLY REPORT TAB
      CalibrationScreen(calibrationData: _calibrationData, tempCalibrationData: _tempCalibrationData, liveData: _liveData, device02LiveData: _device02LiveData, phCalibrationData: _phCalibrationData),
      const CuttersScreen(), // CUTTERS TAB
      SystemScreen(liveData: _liveData, isConnected: _isConnected, relayNames: _relayNames, relayIcons: _relayIcons, onSettingsChanged: _loadLocalSettings),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      extendBody: true,
      body: Stack(
        children: [
          AnimatedBuilder(animation: _bgController, builder: (context, child) => Container(decoration: BoxDecoration(gradient: RadialGradient(center: Alignment(0, -0.5 + (_bgController.value * 0.2)), radius: 1.5, colors: const [Color(0xFF082F49), Color(0xFF020617)])))),
          AnimatedSwitcher(duration: const Duration(milliseconds: 400), switchInCurve: Curves.easeOutCubic, switchOutCurve: Curves.easeInCubic, child: views[_currentIndex]),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 16), height: 64,
          decoration: BoxDecoration(color: const Color(0xFF0F172A).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(32), border: Border.all(color: Colors.white.withValues(alpha: 0.1)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(0, Icons.dashboard_rounded, 'Overview'), 
                  _buildNavItem(1, Icons.analytics_rounded, 'Analytics'), 
                  _buildNavItem(2, Icons.tune_rounded, 'Tune'), 
                  _buildNavItem(3, Icons.support_agent_rounded, 'Cutters'), // NEW ICON
                  _buildNavItem(4, Icons.settings_rounded, 'Settings'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index), behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300), curve: Curves.easeOutQuint,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: isSelected ? const Color(0xFF2DD4BF).withValues(alpha: 0.15) : Colors.transparent, borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: isSelected ? const Color(0xFF2DD4BF) : const Color(0xFF64748B), size: 24),
          AnimatedContainer(duration: const Duration(milliseconds: 300), margin: const EdgeInsets.only(top: 4), height: 4, width: isSelected ? 4 : 0, decoration: const BoxDecoration(color: Color(0xFF2DD4BF), shape: BoxShape.circle))
        ]),
      ),
    );
  }
}