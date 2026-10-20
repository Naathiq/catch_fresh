import 'package:flutter/material.dart';
import 'monthly_report_view.dart';

class AnalyticsScreen extends StatefulWidget {
  final Map<dynamic, dynamic> liveData;
  final Map<dynamic, dynamic> device02LiveData;
  final Map<String, String>? relayNames;

  const AnalyticsScreen({
    super.key,
    required this.liveData,
    required this.device02LiveData,
    this.relayNames,
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  // 0 = Monthly Report, 1 = Live Telemetry
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'INTELLIGENCE & REPORTS',
                      style: TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Aquaculture Analytics',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Live Pulse Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
                    SizedBox(width: 4),
                    Text(
                      'CLOUD SYNC',
                      style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Segmented Switcher (Monthly Report vs Live Telemetry)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSegmentButton(
                    index: 0,
                    label: 'Monthly Report',
                    icon: Icons.calendar_month_rounded,
                  ),
                ),
                Expanded(
                  child: _buildSegmentButton(
                    index: 1,
                    label: 'Live Telemetry',
                    icon: Icons.sensors_rounded,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Active View
          if (_activeTab == 0)
            MonthlyReportView(relayNames: widget.relayNames)
          else
            _buildLiveTelemetryView(),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final bool active = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2DD4BF) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? const Color(0xFF020617) : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: active ? const Color(0xFF020617) : const Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveTelemetryView() {
    final double rawTemp = (widget.liveData['temperature'] ?? 0.0).toDouble();
    final double compVoltage = (widget.liveData['compensatedVoltage'] ?? 0.0).toDouble();
    final double phVoltage = (widget.device02LiveData['voltage'] ?? 0.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGlassMetricCard(
          'Factory Temperature',
          rawTemp > 0 ? rawTemp.toStringAsFixed(1) : '--',
          '°C',
          Icons.thermostat,
          const Color(0xFF10B981),
        ),
        const SizedBox(height: 16),
        _buildGlassMetricCard(
          'TDS Compensated Voltage',
          compVoltage > 0 ? compVoltage.toStringAsFixed(4) : '--',
          'V',
          Icons.electrical_services,
          const Color(0xFF38BDF8),
        ),
        const SizedBox(height: 16),
        _buildGlassMetricCard(
          'pH Raw Voltage (Device 02)',
          phVoltage > 0 ? phVoltage.toStringAsFixed(4) : '--',
          'V',
          Icons.science,
          const Color(0xFFA78BFA),
        ),
      ],
    );
  }

  Widget _buildGlassMetricCard(String title, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 4),
                    Text(unit, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
