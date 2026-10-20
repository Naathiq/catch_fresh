import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'report_exporter.dart';

class MilestoneRecord {
  final String key;
  final String date;
  final String time;
  final String milestoneSlot;
  final String milestoneName;
  final double temperature;
  final double tds;
  final double ph;
  final Map<String, bool> relays;
  final int timestamp;

  MilestoneRecord({
    required this.key,
    required this.date,
    required this.time,
    required this.milestoneSlot,
    required this.milestoneName,
    required this.temperature,
    required this.tds,
    required this.ph,
    required this.relays,
    required this.timestamp,
  });

  factory MilestoneRecord.fromMap(String key, Map<dynamic, dynamic> map) {
    Map<String, bool> relaysMap = {};
    final rawRelays = map['relays'];
    if (rawRelays is Map) {
      rawRelays.forEach((k, v) {
        relaysMap[k.toString()] = v == true;
      });
    } else if (rawRelays is List) {
      for (int i = 0; i < rawRelays.length; i++) {
        if (rawRelays[i] != null) {
          relaysMap[i.toString()] = rawRelays[i] == true;
        }
      }
    }

    return MilestoneRecord(
      key: key,
      date: (map['date'] ?? '').toString(),
      time: (map['time'] ?? '').toString(),
      milestoneSlot: (map['milestoneSlot'] ?? '').toString(),
      milestoneName: (map['milestoneName'] ?? 'Snapshot').toString(),
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.0,
      tds: (map['tds'] as num?)?.toDouble() ?? 0.0,
      ph: (map['ph'] as num?)?.toDouble() ?? 0.0,
      relays: relaysMap,
      timestamp: (map['timestamp'] as num?)?.toInt() ?? 0,
    );
  }
}

class MonthlyReportView extends StatefulWidget {
  final Map<String, String>? relayNames;

  const MonthlyReportView({super.key, this.relayNames});

  @override
  State<MonthlyReportView> createState() => _MonthlyReportViewState();
}

class _MonthlyReportViewState extends State<MonthlyReportView> {
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = true;
  List<MilestoneRecord> _records = [];
  String? _errorMessage;

  // 0 = Temperature, 1 = TDS, 2 = pH
  int _selectedMetric = 0;
  String _selectedSlotFilter = 'All';
  int? _selectedScrubIndex;

  @override
  void initState() {
    super.initState();
    _fetchMonthData();
  }

  String get _monthKey {
    final y = _selectedMonth.year.toString();
    final m = _selectedMonth.month.toString().padLeft(2, '0');
    return '$y-$m';
  }

  String get _monthLabel {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[_selectedMonth.month - 1]} ${_selectedMonth.year}';
  }

  Future<void> _fetchMonthData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedScrubIndex = null;
    });

    try {
      final ref = FirebaseDatabase.instance.ref('history/$_monthKey');
      final snapshot = await ref.get();

      if (!mounted) return;

      if (!snapshot.exists || snapshot.value == null) {
        setState(() {
          _records = [];
          _isLoading = false;
        });
        return;
      }

      final rawData = snapshot.value;
      List<MilestoneRecord> loaded = [];

      if (rawData is Map) {
        rawData.forEach((key, val) {
          if (val is Map) {
            loaded.add(MilestoneRecord.fromMap(key.toString(), val));
          }
        });
      }

      // Sort chronologically
      loaded.sort((a, b) {
        if (a.timestamp != 0 && b.timestamp != 0) {
          return a.timestamp.compareTo(b.timestamp);
        }
        return a.key.compareTo(b.key);
      });

      setState(() {
        _records = loaded;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load report data: $e';
      });
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta, 1);
    });
    _fetchMonthData();
  }

  List<MilestoneRecord> get _filteredRecords {
    if (_selectedSlotFilter == 'All') return _records;
    return _records.where((r) => r.milestoneName == _selectedSlotFilter || r.milestoneSlot == _selectedSlotFilter).toList();
  }

  // --- STATS COMPUTATION ---
  double get _avgTemp => _records.isEmpty ? 0.0 : _records.map((r) => r.temperature).reduce((a, b) => a + b) / _records.length;
  double get _minTemp => _records.isEmpty ? 0.0 : _records.map((r) => r.temperature).reduce(math.min);
  double get _maxTemp => _records.isEmpty ? 0.0 : _records.map((r) => r.temperature).reduce(math.max);

  double get _avgTds => _records.isEmpty ? 0.0 : _records.map((r) => r.tds).reduce((a, b) => a + b) / _records.length;
  double get _minTds => _records.isEmpty ? 0.0 : _records.map((r) => r.tds).reduce(math.min);
  double get _maxTds => _records.isEmpty ? 0.0 : _records.map((r) => r.tds).reduce(math.max);

  double get _avgPh => _records.isEmpty ? 0.0 : _records.map((r) => r.ph).reduce((a, b) => a + b) / _records.length;
  double get _minPh => _records.isEmpty ? 0.0 : _records.map((r) => r.ph).reduce(math.min);
  double get _maxPh => _records.isEmpty ? 0.0 : _records.map((r) => r.ph).reduce(math.max);

  bool _isExporting = false;

  Future<void> _triggerPdfDownload() async {
    if (_records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No records available for this month.')));
      return;
    }

    setState(() => _isExporting = true);
    try {
      await ReportExporter.downloadPdf(
        monthLabel: _monthLabel,
        monthKey: _monthKey,
        records: _records,
        avgTemp: _avgTemp,
        minTemp: _minTemp,
        maxTemp: _maxTemp,
        avgTds: _avgTds,
        minTds: _minTds,
        maxTds: _maxTds,
        avgPh: _avgPh,
        minPh: _minPh,
        maxPh: _maxPh,
        relayNames: widget.relayNames,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _triggerExcelDownload() async {
    if (_records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No records available for this month.')));
      return;
    }

    setState(() => _isExporting = true);
    try {
      await ReportExporter.downloadExcelCsv(
        monthKey: _monthKey,
        records: _records,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF0F172A),
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF2DD4BF), size: 18),
                SizedBox(width: 8),
                Text('Excel (.csv) downloaded & copied to clipboard!'),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error exporting Excel: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showExportSheet() {
    if (_records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No records to export.')));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'EXPORT MONTHLY REPORT',
                style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
              ),
              const SizedBox(height: 4),
              Text(
                'Download Report for $_monthLabel',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // PDF Option
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
                tileColor: const Color(0xFF1E293B).withValues(alpha: 0.6),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF10B981), size: 22),
                ),
                title: const Text('Download Printable PDF Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Formatted audit sheet with KPIs and milestones table', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF64748B), size: 14),
                onTap: () {
                  Navigator.pop(ctx);
                  _triggerPdfDownload();
                },
              ),
              const SizedBox(height: 12),
              // Excel Option
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
                tileColor: const Color(0xFF1E293B).withValues(alpha: 0.6),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF38BDF8).withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.table_chart_rounded, color: Color(0xFF38BDF8), size: 22),
                ),
                title: const Text('Download Excel Spreadsheet (.CSV)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Raw sensor data table for Microsoft Excel & Google Sheets', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF64748B), size: 14),
                onTap: () {
                  Navigator.pop(ctx);
                  _triggerExcelDownload();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- MONTH SELECTOR HEADER ---
        _buildMonthPickerBar(),
        const SizedBox(height: 16),

        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: Color(0xFF2DD4BF)),
                  SizedBox(height: 16),
                  Text('Loading month milestone telemetry...', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                ],
              ),
            ),
          )
        else if (_errorMessage != null)
          _buildErrorBox()
        else if (_records.isEmpty)
          _buildEmptyBox()
        else ...[
          // --- KPI SUMMARY CARDS ---
          _buildKpiGrid(),
          const SizedBox(height: 16),

          // --- 1-CLICK EXPORT BAR ---
          _buildExportActionBar(),
          const SizedBox(height: 24),

          // --- CHART SECTION ---
          _buildChartCard(),
          const SizedBox(height: 24),

          // --- LOGS TABLE SECTION ---
          _buildMilestoneLogsSection(),
        ],
      ],
    );
  }

  Widget _buildMonthPickerBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left, color: Color(0xFF38BDF8)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            tooltip: 'Previous Month',
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_month, color: Color(0xFF2DD4BF), size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _monthLabel,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right, color: Color(0xFF38BDF8)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            tooltip: 'Next Month',
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: _showExportSheet,
            icon: const Icon(Icons.file_download_outlined, color: Color(0xFF2DD4BF)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            tooltip: 'Export Options',
          ),
        ],
      ),
    );
  }

  Widget _buildExportActionBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ONE-CLICK REPORT EXPORT',
                style: TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              if (_isExporting)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2DD4BF)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // 1-Click PDF Button
              Expanded(
                child: GestureDetector(
                  onTap: _isExporting ? null : _triggerPdfDownload,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF14B8A6).withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Download PDF',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // 1-Click Excel / CSV Button
              Expanded(
                child: GestureDetector(
                  onTap: _isExporting ? null : _triggerExcelDownload,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.table_chart_rounded, color: Color(0xFF38BDF8), size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Download Excel',
                            style: TextStyle(color: Color(0xFF38BDF8), fontSize: 13, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricKpi(
                title: 'Water Temp',
                avg: '${_avgTemp.toStringAsFixed(1)}°C',
                range: '${_minTemp.toStringAsFixed(0)}° - ${_maxTemp.toStringAsFixed(0)}°C',
                icon: Icons.thermostat,
                accentColor: const Color(0xFF10B981),
                status: _avgTemp >= 24 && _avgTemp <= 32 ? 'Optimal (24-32°)' : 'Attention',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricKpi(
                title: 'TDS Level',
                avg: '${_avgTds.toStringAsFixed(0)} ppm',
                range: '${_minTds.toStringAsFixed(0)} - ${_maxTds.toStringAsFixed(0)}',
                icon: Icons.water_drop,
                accentColor: const Color(0xFF38BDF8),
                status: _avgTds < 500 ? 'Freshwater Safe' : 'Elevated',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricKpi(
                title: 'pH Acidity',
                avg: _avgPh.toStringAsFixed(2),
                range: '${_minPh.toStringAsFixed(1)} - ${_maxPh.toStringAsFixed(1)}',
                icon: Icons.science,
                accentColor: const Color(0xFFA78BFA),
                status: _avgPh >= 6.8 && _avgPh <= 8.5 ? 'Balanced (6.8-8.5)' : 'Critical',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricKpi(
                title: 'Milestones Logged',
                avg: '${_records.length}',
                range: '4 Snapshots / Day',
                icon: Icons.history_toggle_off_rounded,
                accentColor: const Color(0xFFF59E0B),
                status: 'Cloud Auto-Synced',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricKpi({
    required String title,
    required String avg,
    required String range,
    required IconData icon,
    required Color accentColor,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(icon, color: accentColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(avg, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text('Range: $range', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(status, style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    final records = _filteredRecords;
    if (records.isEmpty) return const SizedBox.shrink();

    Color metricColor;
    String metricUnit;
    String metricTitle;
    List<double> values;

    if (_selectedMetric == 0) {
      metricTitle = 'Water Temperature Trend';
      metricColor = const Color(0xFF10B981);
      metricUnit = '°C';
      values = records.map((r) => r.temperature).toList();
    } else if (_selectedMetric == 1) {
      metricTitle = 'TDS Level Trend';
      metricColor = const Color(0xFF38BDF8);
      metricUnit = 'ppm';
      values = records.map((r) => r.tds).toList();
    } else {
      metricTitle = 'pH Balance Trend';
      metricColor = const Color(0xFFA78BFA);
      metricUnit = 'pH';
      values = records.map((r) => r.ph).toList();
    }

    final double minVal = values.reduce(math.min);
    final double maxVal = values.reduce(math.max);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  metricTitle,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
              Row(
                children: [
                  _buildMetricTabPill(0, 'Temp', const Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  _buildMetricTabPill(1, 'TDS', const Color(0xFF38BDF8)),
                  const SizedBox(width: 6),
                  _buildMetricTabPill(2, 'pH', const Color(0xFFA78BFA)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Showing ${records.length} data points (Tap graph to inspect reading)',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
          const SizedBox(height: 20),

          // --- INTERACTIVE GRAPH CANVAS ---
          SizedBox(
            height: 180,
            width: double.infinity,
            child: GestureDetector(
              onPanDown: (details) => _handleScrub(details.localPosition.dx, context, records.length),
              onPanUpdate: (details) => _handleScrub(details.localPosition.dx, context, records.length),
              child: CustomPaint(
                painter: _SmoothTrendChartPainter(
                  values: values,
                  lineColor: metricColor,
                  scrubIndex: _selectedScrubIndex,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // --- SCRUB VALUE INSPECTOR ---
          if (_selectedScrubIndex != null && _selectedScrubIndex! < records.length) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: metricColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: metricColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.touch_app_rounded, color: metricColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${records[_selectedScrubIndex!].date} • ${records[_selectedScrubIndex!].time} (${records[_selectedScrubIndex!].milestoneName})',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${values[_selectedScrubIndex!].toStringAsFixed(1)} $metricUnit',
                    style: TextStyle(color: metricColor, fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Min: ${minVal.toStringAsFixed(1)} $metricUnit', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600)),
                Text('Max: ${maxVal.toStringAsFixed(1)} $metricUnit', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _handleScrub(double localDx, BuildContext ctx, int totalPoints) {
    if (totalPoints <= 1) return;
    final RenderBox? box = ctx.findRenderObject() as RenderBox?;
    final double width = box?.size.width ?? 300.0;
    final double ratio = (localDx / width).clamp(0.0, 1.0);
    final int index = (ratio * (totalPoints - 1)).round();
    setState(() {
      _selectedScrubIndex = index;
    });
  }

  Widget _buildMetricTabPill(int index, String label, Color color) {
    final bool active = _selectedMetric == index;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedMetric = index;
        _selectedScrubIndex = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? color : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(color: active ? color : const Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildMilestoneLogsSection() {
    final records = _filteredRecords;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RECORDED MILESTONES', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                SizedBox(height: 2),
                Text('Detailed Readings Log', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
              child: Text('${records.length} items', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Filter chips: All, Morning, Midday, Evening, Midnight
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildSlotFilterChip('All'),
              const SizedBox(width: 8),
              _buildSlotFilterChip('Morning'),
              const SizedBox(width: 8),
              _buildSlotFilterChip('Midday'),
              const SizedBox(width: 8),
              _buildSlotFilterChip('Evening'),
              const SizedBox(width: 8),
              _buildSlotFilterChip('Midnight'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // List of entries (newest first for the table)
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: records.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            // Reverse order to show latest first in table
            final r = records[records.length - 1 - i];
            return _buildMilestoneRow(r);
          },
        ),
      ],
    );
  }

  Widget _buildSlotFilterChip(String label) {
    final bool active = _selectedSlotFilter == label;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedSlotFilter = label;
        _selectedScrubIndex = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2DD4BF) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? const Color(0xFF2DD4BF) : Colors.white.withValues(alpha: 0.1)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFF020617) : const Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMilestoneRow(MilestoneRecord r) {
    Color slotColor = const Color(0xFF38BDF8);
    IconData slotIcon = Icons.wb_sunny_outlined;

    if (r.milestoneName == 'Morning') {
      slotColor = const Color(0xFFF59E0B);
      slotIcon = Icons.wb_twilight;
    } else if (r.milestoneName == 'Midday') {
      slotColor = const Color(0xFFFBBF24);
      slotIcon = Icons.wb_sunny;
    } else if (r.milestoneName == 'Evening') {
      slotColor = const Color(0xFFFB923C);
      slotIcon = Icons.wb_twilight;
    } else if (r.milestoneName == 'Midnight') {
      slotColor = const Color(0xFFA78BFA);
      slotIcon = Icons.nightlight_round;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          // Milestone Icon Badge
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: slotColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(slotIcon, color: slotColor, size: 18),
          ),
          const SizedBox(width: 10),

          // Date & Time Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  r.date,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${r.time} • ${r.milestoneName}',
                  style: TextStyle(color: slotColor, fontSize: 10, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Sensor Values (FittedBox scales down gracefully if screen is narrow)
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildValuePill('${r.temperature.toStringAsFixed(1)}°C', const Color(0xFF10B981)),
                  const SizedBox(width: 4),
                  _buildValuePill('${r.tds.toStringAsFixed(0)} ppm', const Color(0xFF38BDF8)),
                  const SizedBox(width: 4),
                  _buildValuePill('${r.ph.toStringAsFixed(2)} pH', const Color(0xFFA78BFA)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValuePill(String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        val,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildEmptyBox() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, color: Color(0xFF64748B), size: 48),
            const SizedBox(height: 16),
            Text(
              'No Milestones Logged for $_monthLabel',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your GitHub Actions cloud logger runs 4 times daily (06:00, 12:00, 18:00, 00:00 IST) and will automatically log upcoming data points here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.white, fontSize: 13))),
          IconButton(
            onPressed: _fetchMonthData,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Smooth Trend Line Chart with Gradient Fill
class _SmoothTrendChartPainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;
  final int? scrubIndex;

  _SmoothTrendChartPainter({
    required this.values,
    required this.lineColor,
    this.scrubIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final double minVal = values.reduce(math.min);
    final double maxVal = values.reduce(math.max);
    final double range = (maxVal - minVal).abs() < 0.001 ? 1.0 : (maxVal - minVal);

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4.0);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final double stepX = values.length > 1 ? size.width / (values.length - 1) : size.width;

    List<Offset> points = [];
    for (int i = 0; i < values.length; i++) {
      final double x = i * stepX;
      final double normalized = (values[i] - minVal) / range;
      final double y = size.height - (normalized * (size.height - 24)) - 12;
      points.add(Offset(x, y));
    }

    // Gradient Fill Path
    final fillPath = Path();
    fillPath.moveTo(points.first.dx, size.height);
    fillPath.lineTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      fillPath.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.35),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // Stroke Path
    final strokePath = Path();
    strokePath.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      strokePath.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    final strokePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(strokePath, strokePaint);

    // Draw scrubber indicator if active
    if (scrubIndex != null && scrubIndex! < points.length) {
      final pt = points[scrubIndex!];

      // Vertical line
      final scrubLinePaint = Paint()
        ..color = lineColor.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(pt.dx, 0), Offset(pt.dx, size.height), scrubLinePaint);

      // Outer glow circle
      final glowPaint = Paint()..color = lineColor.withValues(alpha: 0.3);
      canvas.drawCircle(pt, 8, glowPaint);

      // Inner solid point
      final pointPaint = Paint()..color = Colors.white;
      canvas.drawCircle(pt, 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SmoothTrendChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.scrubIndex != scrubIndex;
  }
}
