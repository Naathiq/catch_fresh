import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class CalibrationScreen extends StatefulWidget {
  final Map<dynamic, dynamic> calibrationData;
  final Map<dynamic, dynamic> tempCalibrationData;
  final Map<dynamic, dynamic> liveData;
  final Map<dynamic, dynamic> device02LiveData;
  final Map<dynamic, dynamic> phCalibrationData;

  const CalibrationScreen({
    super.key,
    required this.calibrationData,
    required this.tempCalibrationData,
    required this.liveData,
    required this.device02LiveData,
    required this.phCalibrationData,
  });

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  bool _isUnlocked = false; // The Lock State
  final TextEditingController _pinController = TextEditingController();

  int _selectedTab = 0; // 0 = TDS, 1 = Temperature, 2 = pH

  final List<TextEditingController> _ppmControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  final List<TextEditingController> _tempControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  final List<TextEditingController> _phControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingPoints();
    _loadExistingTempPoints();
    _loadExistingPhPoints();
  }

  @override
  void dispose() {
    _pinController.dispose();
    for (var c in _ppmControllers) {
      c.dispose();
    }
    for (var c in _tempControllers) {
      c.dispose();
    }
    for (var c in _phControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CalibrationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.calibrationData != widget.calibrationData) {
      _loadExistingPoints();
    }
    if (oldWidget.tempCalibrationData != widget.tempCalibrationData) {
      _loadExistingTempPoints();
    }
    if (oldWidget.phCalibrationData != widget.phCalibrationData) {
      _loadExistingPhPoints();
    }
  }

  void _loadExistingPhPoints() {
    final rawPoints = widget.phCalibrationData['points'];
    if (rawPoints is List) {
      for (int i = 1; i <= 3; i++) {
        if (rawPoints.length > i && rawPoints[i] != null) {
          _phControllers[i - 1].text = rawPoints[i]['referencePH'].toString();
        }
      }
    } else if (rawPoints is Map) {
      for (int i = 1; i <= 3; i++) {
        if (rawPoints[i.toString()] != null) {
          _phControllers[i - 1].text = rawPoints[i.toString()]['referencePH'].toString();
        }
      }
    }
  }

  void _loadExistingPoints() {
    final rawPoints = widget.calibrationData['points'];
    if (rawPoints is List) {
      for (int i = 1; i <= 3; i++) {
        if (rawPoints.length > i && rawPoints[i] != null) {
          _ppmControllers[i - 1].text = rawPoints[i]['referencePPM'].toString();
        }
      }
    } else if (rawPoints is Map) {
      for (int i = 1; i <= 3; i++) {
        if (rawPoints[i.toString()] != null) {
          _ppmControllers[i - 1].text = rawPoints[i.toString()]['referencePPM'].toString();
        }
      }
    }
  }

  void _loadExistingTempPoints() {
    final rawPoints = widget.tempCalibrationData['points'];
    if (rawPoints is List) {
      for (int i = 1; i <= 3; i++) {
        if (rawPoints.length > i && rawPoints[i] != null) {
          _tempControllers[i - 1].text = rawPoints[i]['referenceTemp'].toString();
        }
      }
    } else if (rawPoints is Map) {
      for (int i = 1; i <= 3; i++) {
        if (rawPoints[i.toString()] != null) {
          _tempControllers[i - 1].text = rawPoints[i.toString()]['referenceTemp'].toString();
        }
      }
    }
  }

  Future<void> _saveCalibrationPoint(int pointIndex) async {
    final double liveVoltage = (widget.liveData['compensatedVoltage'] ?? 0.0).toDouble();
    final double liveTemp = (widget.liveData['temperature'] ?? 25.0).toDouble();
    final double refPPM = double.tryParse(_ppmControllers[pointIndex - 1].text) ?? 0.0;

    if (refPPM <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid PPM value'), backgroundColor: Colors.red));
      return;
    }

    try {
      await FirebaseDatabase.instance.ref('device01/calibration/points/$pointIndex').update({
        'referencePPM': refPPM,
        'compensatedVoltage': liveVoltage,
        'temperature': liveTemp,
      });

      await FirebaseDatabase.instance.ref('device01/calibration').update({'pointCount': 3});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Point $pointIndex Saved! Math updated instantly.'), backgroundColor: const Color(0xFF10B981)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _saveTempPoint(int pointIndex, double typedReferenceTemp) async {
    final double rawFactoryTemp = (widget.liveData['temperature'] ?? 0.0).toDouble();

    await FirebaseDatabase.instance.ref('device01/tempCalibration/points/$pointIndex').update({
      'referenceTemp': typedReferenceTemp, 
      'factoryTemp': rawFactoryTemp,
    });
  }

  Future<void> _toggleCalibration(bool enabled) async {
    await FirebaseDatabase.instance.ref('device01/calibration').update({'enabled': enabled});
  }

  Future<void> _toggleTempCalibration(bool enabled) async {
    await FirebaseDatabase.instance.ref('device01/tempCalibration').update({'enabled': enabled});
  }

  @override
  Widget build(BuildContext context) {
    // --- 1. SHOW LOCK SCREEN IF NOT UNLOCKED ---
    if (!_isUnlocked) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: const Color(0xFF0F172A), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3))), child: const Icon(Icons.lock_outline, color: Color(0xFF38BDF8), size: 48)),
              const SizedBox(height: 24),
              const Text('Restricted Access', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Enter admin PIN to modify calibration curves.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8.0, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '•••••',
                  hintStyle: const TextStyle(color: Color(0xFF475569)),
                  filled: true, fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                onChanged: (value) {
                  if (value == '54321') {
                    setState(() => _isUnlocked = true);
                  }
                },
              ),
            ],
          ),
        ),
      );
    }

    // --- 2. SHOW CALIBRATION UI IF UNLOCKED (Existing UI with lock button) ---
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TUNE', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                  SizedBox(height: 4), Text('Sensor Calibration', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                ],
              ),
              IconButton(icon: const Icon(Icons.lock_open, color: Color(0xFF10B981)), onPressed: () => setState(() { _isUnlocked = false; _pinController.clear(); }))
            ],
          ),
          const SizedBox(height: 24),

          // Custom Tab Bar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
            child: Row(
              children: [
                Expanded(child: _buildTabButton(0, 'TDS')),
                Expanded(child: _buildTabButton(1, 'TEMP')),
                Expanded(child: _buildTabButton(2, 'pH')),
              ],
            ),
          ),
          const SizedBox(height: 24),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _selectedTab == 0 ? _buildTDSTab() : (_selectedTab == 1 ? _buildTempTab() : _buildPhTab()),
          )
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, [IconData? icon]) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF64748B)),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTDSTab() => _buildTdsView();
  Widget _buildTempTab() => _buildTempView();

  Widget _buildTdsView() {
    final bool isEnabled = widget.calibrationData['enabled'] == true;
    final double liveVoltage = (widget.liveData['compensatedVoltage'] ?? 0.0).toDouble();

    return Column(
      key: const ValueKey('TDS'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3), width: 1.5),
          ),
          child: Column(
            children: [
              const Text('RAW ANALOG VOLTAGE (FROM ESP32)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Text('${liveVoltage.toStringAsFixed(6)} V', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 36, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
              const SizedBox(height: 4),
              Text('Wait for voltage to stabilize before capturing a point', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Icon(isEnabled ? Icons.calculate : Icons.warning_amber, color: isEnabled ? const Color(0xFF10B981) : const Color(0xFFF59E0B), size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Custom App TDS Interpolation', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.bold)),
                    Text(isEnabled ? 'ACTIVE' : 'DISABLED (Using Factory)', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              Switch(value: isEnabled, activeColor: const Color(0xFF2DD4BF), onChanged: _toggleCalibration),
            ],
          ),
        ),
        const SizedBox(height: 32),

        const Text('TDS CALIBRATION POINTS', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
        const SizedBox(height: 16),

        _buildCalibrationCard(1),
        _buildCalibrationCard(2),
        _buildCalibrationCard(3),
      ],
    );
  }

  Widget _buildTempView() {
    final bool isEnabled = widget.tempCalibrationData['enabled'] == true;
    final double rawTemp = (widget.liveData['temperature'] ?? 0.0).toDouble();

    return Column(
      key: const ValueKey('TEMP'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3), width: 1.5),
          ),
          child: Column(
            children: [
              const Text('RAW FACTORY TEMP (FROM ESP32)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Text('${rawTemp > 0 ? rawTemp.toStringAsFixed(1) : '--'} °C', style: const TextStyle(color: Color(0xFF10B981), fontSize: 36, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
              const SizedBox(height: 4),
              Text('Adaptive 1-3 Point calibration (1=Offset, 2/3=Slope Interpolation)', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Icon(isEnabled ? Icons.thermostat : Icons.warning_amber, color: isEnabled ? const Color(0xFF10B981) : const Color(0xFFF59E0B), size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Custom App Temp Interpolation', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.bold)),
                    Text(isEnabled ? 'ACTIVE' : 'DISABLED (Using Factory)', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              Switch(value: isEnabled, activeColor: const Color(0xFF2DD4BF), onChanged: _toggleTempCalibration),
            ],
          ),
        ),
        const SizedBox(height: 32),

        const Text('TEMPERATURE CALIBRATION POINTS', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
        const SizedBox(height: 16),

        _buildTempCalibrationCard(1),
        _buildTempCalibrationCard(2),
        _buildTempCalibrationCard(3),
      ],
    );
  }

  Widget _buildCalibrationCard(int pointIndex) {
    double savedVoltage = 0.0;
    try {
      final rawPoints = widget.calibrationData['points'];
      if (rawPoints is List) savedVoltage = (rawPoints[pointIndex]['compensatedVoltage'] ?? 0).toDouble();
      if (rawPoints is Map) savedVoltage = (rawPoints[pointIndex.toString()]['compensatedVoltage'] ?? 0).toDouble();
    } catch (e) { /* Ignore */ }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Buffer Point $pointIndex', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 14, fontWeight: FontWeight.bold)),
              Text(savedVoltage > 0 ? 'Saved: ${savedVoltage.toStringAsFixed(5)}V' : 'Not Set', style: TextStyle(color: savedVoltage > 0 ? const Color(0xFF10B981) : Colors.white54, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _ppmControllers[pointIndex - 1],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Fluid PPM',
                    labelStyle: const TextStyle(color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: const Color(0xFF38BDF8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF38BDF8), width: 1)),
                  ),
                  onPressed: () => _saveCalibrationPoint(pointIndex),
                  child: const Text('CAPTURE LIVE', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTempCalibrationCard(int pointIndex) {
    double savedFactoryTemp = 0.0;
    double savedRefTemp = 0.0;
    try {
      final rawPoints = widget.tempCalibrationData['points'];
      if (rawPoints is List) {
        if (rawPoints.length > pointIndex && rawPoints[pointIndex] != null) {
          savedFactoryTemp = (rawPoints[pointIndex]['factoryTemp'] ?? 0).toDouble();
          savedRefTemp = (rawPoints[pointIndex]['referenceTemp'] ?? 0).toDouble();
        }
      } else if (rawPoints is Map) {
        if (rawPoints[pointIndex.toString()] != null) {
          savedFactoryTemp = (rawPoints[pointIndex.toString()]['factoryTemp'] ?? 0).toDouble();
          savedRefTemp = (rawPoints[pointIndex.toString()]['referenceTemp'] ?? 0).toDouble();
        }
      }
    } catch (e) { /* Ignore */ }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Temp Point $pointIndex', style: const TextStyle(color: Color(0xFF10B981), fontSize: 14, fontWeight: FontWeight.bold)),
              Text(
                savedRefTemp > 0 ? 'Saved: ${savedRefTemp.toStringAsFixed(1)}°C (Raw: ${savedFactoryTemp.toStringAsFixed(1)}°C)' : 'Not Set',
                style: TextStyle(color: savedRefTemp > 0 ? const Color(0xFF10B981) : Colors.white54, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _tempControllers[pointIndex - 1],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Ref Temp °C',
                    labelStyle: const TextStyle(color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF10B981), width: 1)),
                  ),
                  onPressed: () async {
                    final double refTemp = double.tryParse(_tempControllers[pointIndex - 1].text) ?? 0.0;
                    if (refTemp <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid reference temperature'), backgroundColor: Colors.red));
                      return;
                    }
                    try {
                      await _saveTempPoint(pointIndex, refTemp);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Temp Point $pointIndex Saved!'), backgroundColor: const Color(0xFF10B981)));
                      }
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red));
                    }
                  },
                  child: const Text('CAPTURE LIVE', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _showErr(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccess(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: const Color(0xFF10B981)));
  }

  Future<void> _savePhPoint(int pointIndex) async {
    final double liveVoltage = (widget.device02LiveData['voltage'] ?? 0.0).toDouble();
    final double refPH = double.tryParse(_phControllers[pointIndex - 1].text) ?? 0.0;
    
    if (refPH <= 0 || refPH > 14) return _showErr('Enter valid pH (0-14)');

    await FirebaseDatabase.instance.ref('device02/calibration/points/$pointIndex').update({
      'referencePH': refPH, 'voltage': liveVoltage,
    });
    _showSuccess('pH Point $pointIndex Saved!');
  }

  Widget _buildPhTab() {
    final bool isEnabled = widget.phCalibrationData['enabled'] == true;
    final double liveVoltage = (widget.device02LiveData['voltage'] ?? 0.0).toDouble();

    return Column(
      key: const ValueKey('PH'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF4C1D95)]), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFA78BFA).withOpacity(0.3), width: 1.5)),
          child: Column(children: [
            const Text('DEVICE 02 - RAW pH VOLTAGE', style: TextStyle(color: Color(0xFFC4B5FD), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 8), Text('${liveVoltage.toStringAsFixed(5)} V', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
          ]),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF1E293B).withOpacity(0.5), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.05))),
          child: Row(children: [
            Icon(isEnabled ? Icons.science : Icons.warning_amber, color: isEnabled ? const Color(0xFFA78BFA) : const Color(0xFFF59E0B), size: 28), const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('pH App Interpolation', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.bold)),
              Text(isEnabled ? 'ACTIVE' : 'DISABLED', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            ])),
            Switch(value: isEnabled, activeColor: const Color(0xFFA78BFA), onChanged: (val) => FirebaseDatabase.instance.ref('device02/calibration').update({'enabled': val})),
          ]),
        ),
        const SizedBox(height: 32),
        const Text('MULTI-POINT pH CALIBRATION', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
        const SizedBox(height: 16),
        _buildPhCard(1), _buildPhCard(2), _buildPhCard(3),
      ],
    );
  }

  Widget _buildPhCard(int pointIndex) {
    double savedVoltage = 0.0;
    try {
      final rawPoints = widget.phCalibrationData['points'];
      if (rawPoints is List) savedVoltage = (rawPoints[pointIndex]['voltage'] ?? 0).toDouble();
      if (rawPoints is Map) savedVoltage = (rawPoints[pointIndex.toString()]['voltage'] ?? 0).toDouble();
    } catch (e) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF0F172A).withOpacity(0.6), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Buffer Point $pointIndex', style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 14, fontWeight: FontWeight.bold)),
          Text(savedVoltage > 0 ? 'Saved: ${savedVoltage.toStringAsFixed(5)}V' : 'Not Set', style: TextStyle(color: savedVoltage > 0 ? const Color(0xFF10B981) : Colors.white54, fontSize: 11)),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(flex: 2, child: TextField(controller: _phControllers[pointIndex - 1], keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Buffer pH (e.g. 7.0)', labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12), filled: true, fillColor: const Color(0xFF1E293B), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0)))),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B), foregroundColor: const Color(0xFFA78BFA), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFA78BFA), width: 1))), onPressed: () => _savePhPoint(pointIndex), child: const Text('CAPTURE LIVE', style: TextStyle(fontWeight: FontWeight.bold)))),
        ])
      ]),
    );
  }
}