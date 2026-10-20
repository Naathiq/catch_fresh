import 'package:flutter/material.dart';

class WaterScreen extends StatelessWidget {
  final Map<dynamic, dynamic> liveData;

  const WaterScreen({super.key, required this.liveData});

  @override
  Widget build(BuildContext context) {
    final double tds = (liveData['tds'] as num?)?.toDouble() ?? 0.0;
    final int rawAdc = (liveData['rawADC'] as num?)?.toInt() ?? 0;
    final double sensorVoltage = (liveData['tdsVoltage'] as num?)?.toDouble() ?? 0.0;
    final double compVoltage = (liveData['compensatedVoltage'] as num?)?.toDouble() ?? 0.0;

    // pH placeholders
    final double ph = (liveData['ph'] as num?)?.toDouble() ?? 0.0;
    final double phVoltage = (liveData['phVoltage'] as num?)?.toDouble() ?? 0.0;

    final double tdsPercentage = (tds / 2000.0).clamp(0.0, 1.0);
    final double phPercentage = (ph / 14.0).clamp(0.0, 1.0); // pH is on a 0 to 14 scale

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column( // <-- Added the missing Column here
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('WATER', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          const Text('Sensor Analytics', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          const Text('Raw signal + calibrated results', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          const SizedBox(height: 24),

          // --- TDS SECTION ---
          _buildSectionHeader('TDS Analytics', Icons.water_drop, const Color(0xFF2DD4BF)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF94A3B8).withOpacity(0.13)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Dissolved Solids', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    Text('${tds > 0 ? tds.toStringAsFixed(0) : '--'} ppm', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                _buildProgressBar(tdsPercentage, const [Color(0xFF06B6D4), Color(0xFF2DD4BF)]),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildRawDataBox('Raw ADC', rawAdc > 0 ? rawAdc.toString() : '--')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildRawDataBox('Sensor V', sensorVoltage > 0 ? '${sensorVoltage.toStringAsFixed(4)}V' : '--')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildRawDataBox('Comp V', compVoltage > 0 ? '${compVoltage.toStringAsFixed(4)}V' : '--')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- PH SECTION ---
          _buildSectionHeader('pH Analytics', Icons.science, const Color(0xFF38BDF8)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF94A3B8).withOpacity(0.13)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Acidity / Alkalinity (0-14)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    Text(ph > 0 ? ph.toStringAsFixed(2) : '-- pH', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                // Special pH gradient (Red -> Green -> Blue/Purple)
                _buildProgressBar(phPercentage, const [Color(0xFFFB7185), Color(0xFF34D399), Color(0xFF818CF8)]),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildRawDataBox('Probe Voltage', phVoltage > 0 ? '${phVoltage.toStringAsFixed(4)}V' : 'Waiting..')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildRawDataBox('Calibration', 'Waiting..')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildProgressBar(double percentage, List<Color> gradientColors) {
    return Container(
      height: 8,
      width: double.infinity,
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(4)),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: percentage,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(colors: gradientColors),
          ),
        ),
      ),
    );
  }

  Widget _buildRawDataBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF020617).withOpacity(0.6),
        border: Border.all(color: const Color(0xFF1E293B)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}