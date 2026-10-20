import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_database/firebase_database.dart';
import 'relay_icons.dart';
import 'deep_sea_aquarium.dart';

class OverviewScreen extends StatelessWidget {
  final String userName;
  final Map<dynamic, dynamic> liveData;
  final Map<dynamic, dynamic> commandsData;
  final Map<dynamic, dynamic> calibrationData;
  final Map<dynamic, dynamic> tempCalibrationData;
  final Map<dynamic, dynamic> device02LiveData;
  final Map<dynamic, dynamic> phCalibrationData;
  final String? customLogo;
  final Map<String, String> relayNames;
  final Map<String, String> relayIcons;
  final VoidCallback onBookCutterTapped;

  const OverviewScreen({
    super.key,
    this.userName = 'Admin',
    required this.liveData,
    required this.commandsData,
    required this.calibrationData,
    required this.tempCalibrationData,
    required this.device02LiveData,
    required this.phCalibrationData,
    this.customLogo,
    required this.relayNames,
    required this.relayIcons,
    required this.onBookCutterTapped,
  });

  static Map<String, IconData> get _iconMap => kRelayIconMap;

  Future<void> _toggleRelay(int index, bool currentState) async {
    await FirebaseDatabase.instance
        .ref('device01/commands/relay$index')
        .set({'state': !currentState, 'updatedAt': ServerValue.timestamp});
  }

  Widget _buildLogo(double height) {
    if (customLogo != null) {
      return Image.memory(base64Decode(customLogo!), height: height, fit: BoxFit.contain);
    }
    return SvgPicture.asset('assets/LOGO.svg', height: height);
  }

  // --- MATH ENGINES (TDS, TEMP, pH) ---
  double _calculateAppSideTDS(double voltage) {
    if (voltage < 0.01) return 0.0;
    if (calibrationData['enabled'] != true || (calibrationData['pointCount'] ?? 0) < 3) {
      return math.max(
        0.0,
        (133.42 * math.pow(voltage, 3) - 255.86 * math.pow(voltage, 2) + 857.39 * voltage) * 0.5,
      );
    }
    List<Map<String, double>> pts = [];
    final raw = calibrationData['points'];
    if (raw is List) {
      for (int i = 0; i < raw.length; i++) {
        if (raw[i] != null) {
          pts.add({
            'v': (raw[i]['compensatedVoltage'] ?? 0.0).toDouble(),
            'p': (raw[i]['referencePPM'] ?? 0.0).toDouble(),
          });
        }
      }
    } else if (raw is Map) {
      raw.forEach((k, v) {
        if (v != null) {
          pts.add({
            'v': (v['compensatedVoltage'] ?? 0.0).toDouble(),
            'p': (v['referencePPM'] ?? 0.0).toDouble(),
          });
        }
      });
    }
    pts.sort((a, b) => a['v']!.compareTo(b['v']!));
    if (pts.length < 3) return 0.0;
    if (voltage < pts.first['v']!) {
      double x2 = pts[0]['v']!;
      double y2 = pts[0]['p']!;
      if (0.0 == x2) return 0.0;
      return math.max(0.0, voltage * (y2 / x2));
    }
    for (int i = 0; i < pts.length - 1; i++) {
      double x1 = pts[i]['v']!;
      double x2 = pts[i + 1]['v']!;
      double y1 = pts[i]['p']!;
      double y2 = pts[i + 1]['p']!;
      if (voltage >= x1 && voltage <= x2) {
        return math.max(0.0, y1 + (voltage - x1) * (y2 - y1) / (x2 - x1));
      }
    }
    int l = pts.length - 1;
    return math.max(
      0.0,
      pts[l - 1]['p']! + (voltage - pts[l - 1]['v']!) * (pts[l]['p']! - pts[l - 1]['p']!) / (pts[l]['v']! - pts[l - 1]['v']!),
    );
  }

  double _calculateAppSideTemp(double rawTemp) {
    if (tempCalibrationData['enabled'] != true) return rawTemp;
    List<Map<String, double>> pts = [];
    final raw = tempCalibrationData['points'];
    if (raw is List) {
      for (int i = 0; i < raw.length; i++) {
        if (raw[i] != null) {
          pts.add({
            'f': (raw[i]['factoryTemp'] ?? 0.0).toDouble(),
            'r': (raw[i]['referenceTemp'] ?? 0.0).toDouble(),
          });
        }
      }
    } else if (raw is Map) {
      raw.forEach((k, v) {
        if (v != null) {
          pts.add({
            'f': (v['factoryTemp'] ?? 0.0).toDouble(),
            'r': (v['referenceTemp'] ?? 0.0).toDouble(),
          });
        }
      });
    }
    if (pts.isEmpty) return rawTemp;
    pts.sort((a, b) => a['f']!.compareTo(b['f']!));
    if (pts.length == 1) return rawTemp + (pts[0]['r']! - pts[0]['f']!);
    if (rawTemp < pts.first['f']!) {
      return pts[0]['r']! + (rawTemp - pts[0]['f']!) * (pts[1]['r']! - pts[0]['r']!) / (pts[1]['f']! - pts[0]['f']!);
    }
    for (int i = 0; i < pts.length - 1; i++) {
      if (rawTemp >= pts[i]['f']! && rawTemp <= pts[i + 1]['f']!) {
        return pts[i]['r']! + (rawTemp - pts[i]['f']!) * (pts[i + 1]['r']! - pts[i]['r']!) / (pts[i + 1]['f']! - pts[i]['f']!);
      }
    }
    int l = pts.length - 1;
    return pts[l - 1]['r']! + (rawTemp - pts[l - 1]['f']!) * (pts[l]['r']! - pts[l - 1]['r']!) / (pts[l]['f']! - pts[l - 1]['f']!);
  }

  double _calculateAppSidePH(double voltage) {
    if (voltage < 0.1) return 0.0;
    if (phCalibrationData['enabled'] != true) return 7.0 + ((2.5 - voltage) / 0.18);
    List<Map<String, double>> pts = [];
    final raw = phCalibrationData['points'];
    if (raw is List) {
      for (int i = 0; i < raw.length; i++) {
        if (raw[i] != null) {
          pts.add({
            'v': (raw[i]['voltage'] ?? 0.0).toDouble(),
            'p': (raw[i]['referencePH'] ?? 0.0).toDouble(),
          });
        }
      }
    } else if (raw is Map) {
      raw.forEach((k, v) {
        if (v != null) {
          pts.add({
            'v': (v['voltage'] ?? 0.0).toDouble(),
            'p': (v['referencePH'] ?? 0.0).toDouble(),
          });
        }
      });
    }
    if (pts.isEmpty) return 7.0;
    pts.sort((a, b) => a['v']!.compareTo(b['v']!));
    if (voltage < pts.first['v']!) {
      if (pts.length == 1) return pts[0]['p']!;
      return pts[0]['p']! + (voltage - pts[0]['v']!) * (pts[1]['p']! - pts[0]['p']!) / (pts[1]['v']! - pts[0]['v']!);
    }
    for (int i = 0; i < pts.length - 1; i++) {
      if (voltage >= pts[i]['v']! && voltage <= pts[i + 1]['v']!) {
        return pts[i]['p']! + (voltage - pts[i]['v']!) * (pts[i + 1]['p']! - pts[i]['p']!) / (pts[i + 1]['v']! - pts[i]['v']!);
      }
    }
    int l = pts.length - 1;
    return pts[l - 1]['p']! + (voltage - pts[l - 1]['v']!) * (pts[l]['p']! - pts[l - 1]['p']!) / (pts[l]['v']! - pts[l - 1]['v']!);
  }

  @override
  Widget build(BuildContext context) {
    final double rawTemp = (liveData['temperature'] ?? 0.0).toDouble();
    final double compVoltage = (liveData['compensatedVoltage'] ?? 0.0).toDouble();
    final double phVoltage = (device02LiveData['voltage'] ?? 0.0).toDouble();

    final double finalTemp = _calculateAppSideTemp(rawTemp);
    final double finalTDS = _calculateAppSideTDS(compVoltage);
    final double finalPH = _calculateAppSidePH(phVoltage);

    // Count active relays
    int activeRelaysCount = 0;
    for (int i = 1; i <= 4; i++) {
      final commandMap = commandsData['relay$i'] as Map<dynamic, dynamic>?;
      final bool desired = commandMap != null ? commandMap['state'] == true : liveData['relay$i'] == true;
      if (desired) activeRelaysCount++;
    }

    return SafeArea(
      top: true,
      bottom: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------------------------------------------------
            // 1. REFINED LUXURY OCEAN HEADER
            // ---------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('WELCOME, ${userName.toUpperCase()}', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                  const SizedBox(height: 4), 
                  const Text('Your Tank Data', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                ],
              ),
              _buildLogo(36),
            ],
          ),
            const SizedBox(height: 22),

            // ---------------------------------------------------------
            // 2. CINEMATIC WATER-QUALITY HERO CARD
            // ---------------------------------------------------------
            _InteractiveHeroCard(
              tds: finalTDS,
              ph: finalPH,
              temp: finalTemp,
              logoBuilder: _buildLogo,
            ),
            const SizedBox(height: 28),

            // ---------------------------------------------------------
            // 3. QUICK CONTROLS SECTION HEADER
            // ---------------------------------------------------------
            Row(
              children: [
                const Text(
                  'QUICK CONTROLS',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(width: 10),
                // Elegant Active Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: activeRelaysCount > 0
                        ? const Color(0xFF2DD4BF).withValues(alpha: 0.15)
                        : const Color(0xFF1E293B).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: activeRelaysCount > 0
                          ? const Color(0xFF2DD4BF).withValues(alpha: 0.35)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: activeRelaysCount > 0
                              ? const Color(0xFF2DD4BF)
                              : const Color(0xFF64748B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$activeRelaysCount of 4 Active',
                        style: TextStyle(
                          color: activeRelaysCount > 0
                              ? const Color(0xFF2DD4BF)
                              : const Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1E293B),
                          const Color(0xFF1E293B).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ---------------------------------------------------------
            // 4. 2x2 RESPONSIVE RELAY QUICK CONTROLS GRID
            // ---------------------------------------------------------
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.7,
              children: List.generate(4, (i) {
                final int rNum = i + 1;
                final bool physical = liveData['relay$rNum'] == true;
                final commandMap = commandsData['relay$rNum'] as Map<dynamic, dynamic>?;
                final bool desired = commandMap != null ? commandMap['state'] == true : physical;
                return _InteractiveRelayButton(
                  rNum: rNum,
                  physical: physical,
                  desired: desired,
                  isPending: physical != desired,
                  name: relayNames[rNum.toString()] ?? 'Relay $rNum',
                  icon: _iconMap[relayIcons[rNum.toString()] ?? 'power'] ?? Icons.power,
                  onToggle: _toggleRelay,
                );
              }),
            ),
            const SizedBox(height: 28),

            // ---------------------------------------------------------
            // 5. SERVICES SECTION HEADER
            // ---------------------------------------------------------
            Row(
              children: [
                const Text(
                  'SERVICES',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1E293B),
                          const Color(0xFF1E293B).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ---------------------------------------------------------
            // 6. ANIMATED BOOK A CUTTER BANNER
            // ---------------------------------------------------------
            _AnimatedCutterBanner(onTap: onBookCutterTapped),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// CUSTOM ANIMATION WIDGETS (VECTOR SEABED & VISIBLE RELAYS)
// ---------------------------------------------------------
class _InteractiveHeroCard extends StatefulWidget {
  final double tds; final double ph; final double temp; final Widget Function(double) logoBuilder;
  const _InteractiveHeroCard({required this.tds, required this.ph, required this.temp, required this.logoBuilder});
  @override State<_InteractiveHeroCard> createState() => _InteractiveHeroCardState();
}

class _InteractiveHeroCardState extends State<_InteractiveHeroCard> {
  bool _isPressed = false;
  
  @override 
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true), onTapUp: (_) => setState(() => _isPressed = false), onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0, duration: const Duration(milliseconds: 250), curve: Curves.easeOutQuart,
        child: Container(
          width: double.infinity, 
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(color: const Color(0xFF0284C7).withValues(alpha: 0.2), blurRadius: 30, offset: const Offset(0, 15)), 
              BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 20, offset: const Offset(0, 10))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              children: [
                // 1. ANIMATED DEEP-SEA AQUARIUM BACKGROUND (FISH, JELLYFISH, BUBBLES, KELP, SUNBEAMS)
                const Positioned.fill(child: DeepSeaAquarium()),

                // Sizer to ensure card has full minimum height
                const SizedBox(height: 280, width: double.infinity),

                // 2. LOGO WATERMARK
                Positioned(right: -30, bottom: -30, child: Opacity(opacity: 0.08, child: widget.logoBuilder(180))),

                // 3. FOREGROUND DATA
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), 
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [_PulsingIndicator(), SizedBox(width: 8), Text('LIVE SENSORS', style: TextStyle(color: Color(0xFF6EE7B7), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2))]),
                      ),
                      const SizedBox(height: 28),
                      
                      const Text(
                        'Total Dissolved Solids',
                        style: TextStyle(
                          color: Color(0xFFBAE6FD),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black87, blurRadius: 8, offset: Offset(0, 1))],
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic,
                        children: [
                          TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0, end: widget.tds), duration: const Duration(milliseconds: 1500), curve: Curves.easeOutQuart,
                            builder: (context, double val, child) => Text(
                              val > 0 ? val.toStringAsFixed(0) : '--',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 56,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.5,
                                shadows: [Shadow(color: Colors.black87, blurRadius: 14, offset: Offset(0, 2))],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'ppm',
                            style: TextStyle(
                              color: Color(0xFFE0F2FE),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              shadows: [Shadow(color: Colors.black87, blurRadius: 8, offset: Offset(0, 1))],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Temperature',
                                style: TextStyle(
                                  color: Color(0xFF34D399),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  shadows: [Shadow(color: Colors.black87, blurRadius: 8, offset: Offset(0, 1))],
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic,
                                children: [
                                  TweenAnimationBuilder(
                                    tween: Tween<double>(begin: 0, end: widget.temp),
                                    duration: const Duration(milliseconds: 1500),
                                    curve: Curves.easeOutQuart,
                                    builder: (context, double val, child) => Text(
                                      val > 0 ? val.toStringAsFixed(1) : '--',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        shadows: [Shadow(color: Colors.black87, blurRadius: 10, offset: Offset(0, 2))],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '°C',
                                    style: TextStyle(
                                      color: Color(0xFFE0F2FE),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      shadows: [Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 1))],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Water pH',
                                style: TextStyle(
                                  color: Color(0xFFFDE047),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  shadows: [Shadow(color: Colors.black87, blurRadius: 8, offset: Offset(0, 1))],
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic,
                                children: [
                                  TweenAnimationBuilder(
                                    tween: Tween<double>(begin: 0, end: widget.ph),
                                    duration: const Duration(milliseconds: 1500),
                                    curve: Curves.easeOutQuart,
                                    builder: (context, double val, child) => Text(
                                      val > 0 ? val.toStringAsFixed(2) : '--',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        shadows: [Shadow(color: Colors.black87, blurRadius: 10, offset: Offset(0, 2))],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingIndicator extends StatefulWidget { const _PulsingIndicator(); @override State<_PulsingIndicator> createState() => _PulsingIndicatorState(); }
class _PulsingIndicatorState extends State<_PulsingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(); }
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) { 
    return SizedBox(width: 12, height: 12, child: Stack(alignment: Alignment.center, children: [
      AnimatedBuilder(animation: _controller, builder: (context, _) => Transform.scale(scale: 1.0 + (_controller.value * 1.5), child: Opacity(opacity: 1.0 - _controller.value, child: Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF34D399), width: 1.0)))))),
      Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF10B981))),
    ])); 
  }
}

// --- HIGH VISIBILITY RELAY BUTTON ---
class _InteractiveRelayButton extends StatefulWidget {
  final int rNum; final bool physical, desired, isPending; final String name; final IconData icon; final Function(int, bool) onToggle;
  const _InteractiveRelayButton({required this.rNum, required this.physical, required this.desired, required this.isPending, required this.name, required this.icon, required this.onToggle});
  @override State<_InteractiveRelayButton> createState() => _InteractiveRelayButtonState();
}
class _InteractiveRelayButtonState extends State<_InteractiveRelayButton> {
  bool _isPressed = false;
  @override Widget build(BuildContext context) {
    final bool isActive = widget.desired;
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true), onTapUp: (_) { setState(() => _isPressed = false); widget.onToggle(widget.rNum, widget.desired); }, onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0, duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0D9488) : const Color(0xFF1E293B), 
            borderRadius: BorderRadius.circular(24), 
            border: Border.all(color: widget.isPending ? const Color(0xFFFBBF24) : (isActive ? const Color(0xFF14B8A6) : Colors.white.withValues(alpha: 0.15)), width: isActive ? 2 : 1), 
            boxShadow: isActive ? [BoxShadow(color: const Color(0xFF0D9488).withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 5))] : []
          ),
          child: Row(children: [
            Icon(widget.icon, color: isActive ? Colors.white : const Color(0xFF94A3B8), size: 28), const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(widget.name, style: TextStyle(color: isActive ? Colors.white : const Color(0xFFF1F5F9), fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis), const SizedBox(height: 2),
              Text(widget.isPending ? 'SYNCING..' : (widget.physical ? 'ON' : 'OFF'), style: TextStyle(color: widget.isPending ? const Color(0xFFFDE68A) : (isActive ? const Color(0xFFCCFBF1) : const Color(0xFF94A3B8)), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
            ])),
          ]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// ANIMATED BOOK A CUTTER BANNER
// ---------------------------------------------------------
class _AnimatedCutterBanner extends StatefulWidget {
  final VoidCallback onTap;

  const _AnimatedCutterBanner({required this.onTap});

  @override
  State<_AnimatedCutterBanner> createState() => _AnimatedCutterBannerState();
}

class _AnimatedCutterBannerState extends State<_AnimatedCutterBanner>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _nudgeController;

  @override
  void initState() {
    super.initState();
    _nudgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _nudgeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF071B2F), Color(0xFF064E3B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.35),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF059669).withValues(alpha: 0.22),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Book a Cutter',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Tap to connect with trusted harvesters',
                      style: TextStyle(
                        color: Color(0xFF6EE7B7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: _nudgeController,
                builder: (context, child) => Transform.translate(
                  offset: Offset(4 * _nudgeController.value, 0),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFF6EE7B7),
                    size: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

