import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A rich, 60fps animated deep-sea aquarium featuring:
/// - Volumetric caustic light rays swaying through deep ocean water
/// - Graceful bioluminescent jellyfish pulsing with contracting bells & wavy tentacles
/// - Multiple animated swimming fish (pelagic cruisers, colorful reef fish, and schooling minnows)
///   with realistic sinusoidal tail-wags, buoyancy bobbing, and fin flutters
/// - Rising ambient bubbles and bubble aerator streams with realistic wobble & 3D specular shine
/// - Swaying deep-sea kelp flora and layered seabed silhouettes
/// - Floating marine snow / bioluminescent plankton specks
class DeepSeaAquarium extends StatefulWidget {
  final double? height;

  const DeepSeaAquarium({super.key, this.height});

  @override
  State<DeepSeaAquarium> createState() => _DeepSeaAquariumState();
}

class _DeepSeaAquariumState extends State<DeepSeaAquarium>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 60-second continuous loop for smooth, non-repeating feel
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Time in continuous seconds
          final double t = _controller.value * 60.0;
          return CustomPaint(
            painter: _DeepSeaPainter(time: t),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _DeepSeaPainter extends CustomPainter {
  final double time;

  _DeepSeaPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rect = Offset.zero & size;

    // 1. BASE DEEP-SEA GRADIENT
    _paintOceanGradient(canvas, rect);

    // 2. VOLUMETRIC CAUSTIC SUNBEAMS
    _paintCausticSunbeams(canvas, size);

    // 3. BACKGROUND SEABED & SWAYING KELP
    _paintBackgroundSeabed(canvas, size);
    _paintSwayingKelp(canvas, size);

    // 4. FLOATING MARINE SNOW & BIOLUMINESCENT PLANKTON
    _paintMarineSnow(canvas, size);

    // 5. DISTANT SECONDARY JELLYFISH
    _paintJellyfish(
      canvas: canvas,
      size: size,
      baseXRatio: 0.18,
      baseYRatio: 0.24,
      scale: 0.55,
      timeOffset: 2.1,
      primaryColor: const Color(0xFF38BDF8),
      glowColor: const Color(0xFF818CF8),
    );

    // 6. SWIMMING FISH
    _paintFishSchools(canvas, size);

    // 7. PRIMARY BIOLUMINESCENT JELLYFISH
    _paintJellyfish(
      canvas: canvas,
      size: size,
      baseXRatio: 0.76,
      baseYRatio: 0.38,
      scale: 1.0,
      timeOffset: 0.0,
      primaryColor: const Color(0xFFF472B6),
      glowColor: const Color(0xFF38BDF8),
    );

    // 8. RISING BUBBLE STREAMS & AMBIENT BUBBLES
    _paintBubbles(canvas, size);

    // 9. FOREGROUND ROCK SILHOUETTES & WATER VIGNETTE
    _paintForegroundRocks(canvas, size);
    _paintAmbientVignette(canvas, rect);
  }

  // ---------------------------------------------------------------------------
  // 1. OCEAN DEPTH GRADIENT
  // ---------------------------------------------------------------------------
  void _paintOceanGradient(Canvas canvas, Rect rect) {
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const [0.0, 0.22, 0.50, 0.78, 1.0],
      colors: const [
        Color(0xFF0369A1), // Sunlit upper azure
        Color(0xFF075985), // Vibrant mid-water
        Color(0xFF0C4A6E), // Deep sea twilight
        Color(0xFF082F49), // Abyssal navy
        Color(0xFF031628), // Trench floor midnight
      ],
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  // ---------------------------------------------------------------------------
  // 2. VOLUMETRIC CAUSTIC LIGHT RAYS (SHIMMERING SUNBEAMS)
  // ---------------------------------------------------------------------------
  void _paintCausticSunbeams(Canvas canvas, Size size) {
    final rayCount = 4;
    for (int i = 0; i < rayCount; i++) {
      final double phase = i * 1.5;
      final double sway = math.sin(time * 0.45 + phase) * 18.0;
      final double pulse = 0.08 + 0.04 * math.sin(time * 0.8 + phase * 1.2);

      final double topX = size.width * (0.15 + i * 0.24) + sway * 0.6;
      final double topWidth = 24.0 + i * 8.0;
      final double bottomX = topX + 70.0 + sway;
      final double bottomWidth = 85.0 + i * 22.0;

      final path = Path()
        ..moveTo(topX - topWidth * 0.5, 0)
        ..lineTo(topX + topWidth * 0.5, 0)
        ..lineTo(bottomX + bottomWidth * 0.5, size.height * 0.85)
        ..lineTo(bottomX - bottomWidth * 0.5, size.height * 0.85)
        ..close();

      final rayGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0.0, 0.35, 1.0],
        colors: [
          const Color(0xFFBAE6FD).withValues(alpha: pulse * 1.6),
          const Color(0xFF38BDF8).withValues(alpha: pulse * 0.8),
          Colors.transparent,
        ],
      );

      final rayPaint = Paint()
        ..shader = rayGradient.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height * 0.85),
        );
      canvas.drawPath(path, rayPaint);
    }
  }

  // ---------------------------------------------------------------------------
  // 3. BACKGROUND SEABED & SWAYING KELP
  // ---------------------------------------------------------------------------
  void _paintBackgroundSeabed(Canvas canvas, Size size) {
    // Distant hill
    final hillPaint1 = Paint()
      ..color = const Color(0xFF0369A1).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    final path1 = Path()
      ..moveTo(0, size.height * 0.62)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.52,
        size.width,
        size.height * 0.70,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path1, hillPaint1);

    // Midground hill
    final hillPaint2 = Paint()
      ..color = const Color(0xFF0C4A6E).withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;
    final path2 = Path()
      ..moveTo(0, size.height * 0.76)
      ..quadraticBezierTo(
        size.width * 0.65,
        size.height * 0.68,
        size.width,
        size.height * 0.82,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path2, hillPaint2);
  }

  void _paintSwayingKelp(Canvas canvas, Size size) {
    // Kelp stalks at bottom edges
    final kelpConfigs = [
      _KelpConfig(xRatio: 0.08, heightRatio: 0.38, swaySpeed: 1.1, phase: 0.0, width: 4.5),
      _KelpConfig(xRatio: 0.14, heightRatio: 0.48, swaySpeed: 0.9, phase: 1.2, width: 5.5),
      _KelpConfig(xRatio: 0.20, heightRatio: 0.32, swaySpeed: 1.2, phase: 2.3, width: 4.0),
      _KelpConfig(xRatio: 0.82, heightRatio: 0.36, swaySpeed: 1.0, phase: 0.8, width: 4.5),
      _KelpConfig(xRatio: 0.88, heightRatio: 0.50, swaySpeed: 0.85, phase: 1.8, width: 6.0),
      _KelpConfig(xRatio: 0.94, heightRatio: 0.40, swaySpeed: 1.15, phase: 2.8, width: 4.5),
    ];

    for (final k in kelpConfigs) {
      final double baseX = size.width * k.xRatio;
      final double kelpHeight = size.height * k.heightRatio;
      final double tipY = size.height - kelpHeight;
      final double sway = math.sin(time * k.swaySpeed + k.phase) * 16.0;

      final stalkPath = Path()
        ..moveTo(baseX, size.height)
        ..cubicTo(
          baseX + sway * 0.3,
          size.height - kelpHeight * 0.35,
          baseX - sway * 0.4,
          size.height - kelpHeight * 0.7,
          baseX + sway,
          tipY,
        );

      final stalkPaint = Paint()
        ..color = const Color(0xFF047857).withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = k.width
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(stalkPath, stalkPaint);

      // Fronds / leaves along kelp stalk
      final frondPaint = Paint()
        ..color = const Color(0xFF10B981).withValues(alpha: 0.55)
        ..style = PaintingStyle.fill;

      for (int f = 1; f <= 3; f++) {
        final double frondY = size.height - (kelpHeight * (f * 0.25));
        final double frondSway = math.sin(time * k.swaySpeed + k.phase + f) * 10.0;
        final bool isRight = f.isOdd;
        final double dir = isRight ? 1.0 : -1.0;
        final double frondX = baseX + frondSway * 0.5;

        final frondPath = Path()
          ..moveTo(frondX, frondY)
          ..quadraticBezierTo(
            frondX + dir * 14.0,
            frondY - 8.0,
            frondX + dir * 18.0 + frondSway * 0.4,
            frondY - 4.0,
          )
          ..quadraticBezierTo(
            frondX + dir * 8.0,
            frondY + 4.0,
            frondX,
            frondY,
          );
        canvas.drawPath(frondPath, frondPaint);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 4. FLOATING MARINE SNOW & BIOLUMINESCENT PARTICLES
  // ---------------------------------------------------------------------------
  void _paintMarineSnow(Canvas canvas, Size size) {
    const int count = 22;
    for (int i = 0; i < count; i++) {
      final double seed = (i * 97.13) % 1.0;
      final double speed = 12.0 + (i % 5) * 6.0;
      final double wobbleSpeed = 0.8 + (i % 4) * 0.3;

      final double y = (size.height + 20) - ((time * speed + seed * size.height * 2) % (size.height + 40));
      final double x = (seed * size.width + math.sin(time * wobbleSpeed + i) * 12.0) % size.width;

      final double radius = 0.9 + (i % 3) * 0.6;
      final double alpha = 0.25 + 0.25 * math.sin(time * 1.5 + i * 1.7).abs();

      final paint = Paint()
        ..color = const Color(0xFF67E8F9).withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  // ---------------------------------------------------------------------------
  // 5 & 7. BIOLUMINESCENT JELLYFISH (PULSING BELL & UNDULATING TENTACLES)
  // ---------------------------------------------------------------------------
  void _paintJellyfish({
    required Canvas canvas,
    required Size size,
    required double baseXRatio,
    required double baseYRatio,
    required double scale,
    required double timeOffset,
    required Color primaryColor,
    required Color glowColor,
  }) {
    final double t = time + timeOffset;

    // Rhythmic jellyfish cycle: contraction (power stroke) + relaxation (glide)
    // 3.6 second period
    final double cycle = (t % 3.6) / 3.6;
    
    // Contraction occurs swiftly during [0.0..0.35], expands slowly [0.35..1.0]
    final double pulseCurve = cycle < 0.35
        ? math.sin((cycle / 0.35) * math.pi * 0.5)
        : math.cos(((cycle - 0.35) / 0.65) * math.pi * 0.5);

    // Contraction squashes width, elongates height, and pushes jellyfish upward
    final double widthFactor = 1.0 - 0.22 * pulseCurve;
    final double heightFactor = 1.0 + 0.18 * pulseCurve;

    // Position in tank with vertical bobbing and gentle horizontal drift
    final double driftX = math.sin(t * 0.5) * (14.0 * scale);
    final double bobY = math.sin(t * 1.2) * (18.0 * scale) - (pulseCurve * 12.0 * scale);

    final double centerX = size.width * baseXRatio + driftX;
    final double centerY = size.height * baseYRatio + bobY;

    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.scale(scale * widthFactor, scale * heightFactor);

    final double bellWidth = 38.0;
    final double bellHeight = 24.0;

    // A. Outer Glow Aura
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          glowColor.withValues(alpha: 0.35),
          primaryColor.withValues(alpha: 0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: const Offset(0, 0), radius: bellWidth * 1.3));
    canvas.drawCircle(const Offset(0, 0), bellWidth * 1.3, glowPaint);

    // B. Bell Dome (Translucent mushroom/umbrella shape)
    final bellPath = Path()
      ..moveTo(-bellWidth * 0.5, 0)
      ..cubicTo(
        -bellWidth * 0.55,
        -bellHeight * 0.85,
        -bellWidth * 0.2,
        -bellHeight,
        0,
        -bellHeight,
      )
      ..cubicTo(
        bellWidth * 0.2,
        -bellHeight,
        bellWidth * 0.55,
        -bellHeight * 0.85,
        bellWidth * 0.5,
        0,
      )
      // Scalloped bottom margin
      ..cubicTo(
        bellWidth * 0.35,
        -2.0,
        bellWidth * 0.15,
        3.0,
        0,
        -1.0,
      )
      ..cubicTo(
        -bellWidth * 0.15,
        3.0,
        -bellWidth * 0.35,
        -2.0,
        -bellWidth * 0.5,
        0,
      )
      ..close();

    final bellPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withValues(alpha: 0.65),
          glowColor.withValues(alpha: 0.45),
          primaryColor.withValues(alpha: 0.25),
        ],
      ).createShader(Rect.fromLTWH(-bellWidth * 0.5, -bellHeight, bellWidth, bellHeight));
    canvas.drawPath(bellPath, bellPaint);

    // Bell rim edge highlight
    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(bellPath, rimPaint);

    // C. Glowing Inner Gonads/Organs (horseshoe lobes in the dome)
    final organPaint = Paint()
      ..color = const Color(0xFFFDE047).withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(-7, -bellHeight * 0.45), 3.0, organPaint);
    canvas.drawCircle(Offset(7, -bellHeight * 0.45), 3.0, organPaint);
    canvas.drawCircle(Offset(0, -bellHeight * 0.6), 3.5, organPaint);

    // D. Flowing Oral Arms & Tentacles
    // 5 tentacles with harmonic wave lagging behind the bell
    const int tentacleCount = 5;
    for (int ti = 0; ti < tentacleCount; ti++) {
      final double rootX = (ti - 2) * (bellWidth * 0.18);
      final double tentacleLength = 48.0 + (ti.isEven ? 14.0 : 0.0);
      final double phaseShift = ti * 0.75;

      final tentaclePath = Path()..moveTo(rootX, 0);

      // Draw tentacle using connected bezier segments with fluid harmonic drag
      const int segments = 5;
      double prevX = rootX;
      double prevY = 0;

      for (int s = 1; s <= segments; s++) {
        final double progress = s / segments;
        final double currY = progress * tentacleLength;
        // Fluid wave drag formula: greater lag down the tentacle
        final double wave = math.sin(t * 3.2 - progress * 4.0 + phaseShift) *
            (4.0 + progress * 9.0);
        final double currX = rootX + wave;

        tentaclePath.quadraticBezierTo(
          prevX + (currX - prevX) * 0.5,
          prevY + (currY - prevY) * 0.5,
          currX,
          currY,
        );
        prevX = currX;
        prevY = currY;
      }

      final tentaclePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.7),
            primaryColor.withValues(alpha: 0.5),
            glowColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(-bellWidth, 0, bellWidth * 2, tentacleLength))
        ..style = PaintingStyle.stroke
        ..strokeWidth = ti == 2 ? 1.6 : 1.1
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(tentaclePath, tentaclePaint);
    }

    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // 6. ANIMATED SWIMMING FISH
  // ---------------------------------------------------------------------------
  void _paintFishSchools(Canvas canvas, Size size) {
    // Fish 1: Graceful Blue Pelagic Cruiser (swimming Left-to-Right)
    _paintIndividualFish(
      canvas: canvas,
      size: size,
      time: time,
      crossSpeed: 0.055, // crosses every ~18 seconds
      yRatio: 0.35,
      yBobAmp: 6.0,
      yBobFreq: 2.2,
      bodyLength: 36.0,
      bodyHeight: 13.0,
      facingRight: true,
      tailFreq: 7.5,
      tailAmp: 0.40,
      timeOffset: 3.5,
      primaryColor: const Color(0xFF0284C7),
      secondaryColor: const Color(0xFF38BDF8),
      accentColor: const Color(0xFFE0F2FE),
      glowColor: const Color(0xFF00F5FF),
    );

    // Fish 2: Vibrant Coral Reef Fish / Clownfish (swimming Right-to-Left)
    _paintIndividualFish(
      canvas: canvas,
      size: size,
      time: time,
      crossSpeed: 0.07, // crosses every ~14 seconds
      yRatio: 0.65,
      yBobAmp: 7.0,
      yBobFreq: 2.6,
      bodyLength: 32.0,
      bodyHeight: 14.5,
      facingRight: false,
      tailFreq: 9.0,
      tailAmp: 0.45,
      timeOffset: 8.0,
      primaryColor: const Color(0xFFEA580C),
      secondaryColor: const Color(0xFFFBBF24),
      accentColor: Colors.white,
      glowColor: const Color(0xFFF97316),
    );

    // Fish 3: Fast Neon Minnow (swimming Right-to-Left)
    _paintIndividualFish(
      canvas: canvas,
      size: size,
      time: time,
      crossSpeed: 0.12, // crosses swiftly
      yRatio: 0.48,
      yBobAmp: 4.5,
      yBobFreq: 3.5,
      bodyLength: 20.0,
      bodyHeight: 7.0,
      facingRight: false,
      tailFreq: 13.0,
      tailAmp: 0.50,
      timeOffset: 1.2,
      primaryColor: const Color(0xFF06B6D4),
      secondaryColor: const Color(0xFF22D3EE),
      accentColor: const Color(0xFFF43F5E),
      glowColor: const Color(0xFF22D3EE),
    );

    // Fish 4: Schooling Companion Minnow (swimming Right-to-Left, following Fish 3)
    _paintIndividualFish(
      canvas: canvas,
      size: size,
      time: time,
      crossSpeed: 0.12,
      yRatio: 0.53,
      yBobAmp: 4.0,
      yBobFreq: 3.5,
      bodyLength: 18.0,
      bodyHeight: 6.5,
      facingRight: false,
      tailFreq: 13.0,
      tailAmp: 0.50,
      timeOffset: 1.45, // slightly behind
      primaryColor: const Color(0xFF06B6D4),
      secondaryColor: const Color(0xFF22D3EE),
      accentColor: const Color(0xFFF43F5E),
      glowColor: const Color(0xFF22D3EE),
    );
  }

  void _paintIndividualFish({
    required Canvas canvas,
    required Size size,
    required double time,
    required double crossSpeed,
    required double yRatio,
    required double yBobAmp,
    required double yBobFreq,
    required double bodyLength,
    required double bodyHeight,
    required bool facingRight,
    required double tailFreq,
    required double tailAmp,
    required double timeOffset,
    required Color primaryColor,
    required Color secondaryColor,
    required Color accentColor,
    required Color glowColor,
  }) {
    final double t = time + timeOffset;

    // Horizontal travel with wrap-around beyond card bounds
    final double totalSpan = size.width + bodyLength * 3.5;
    final double rawProgress = (t * crossSpeed) % 1.0;
    final double x = facingRight
        ? -bodyLength * 1.5 + (rawProgress * totalSpan)
        : size.width + bodyLength * 1.5 - (rawProgress * totalSpan);

    // Vertical sinusoidal bobbing with swimming rhythm
    final double yBob = math.sin(t * yBobFreq) * yBobAmp;
    final double y = size.height * yRatio + yBob;

    // Pitch tilt according to vertical velocity (heads up when rising, down when descending)
    final double pitch = math.cos(t * yBobFreq) * (facingRight ? -0.06 : 0.06);

    // Dynamic wagging tail angle
    final double tailWag = math.sin(t * tailFreq) * tailAmp;

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(pitch);

    // If facing left, flip horizontally so fish naturally points left
    if (!facingRight) {
      canvas.scale(-1.0, 1.0);
    }

    final double halfLen = bodyLength * 0.5;
    final double halfH = bodyHeight * 0.5;

    // A. Fish Caudal Fin (Tail) - pivots with tailWag at caudal peduncle
    canvas.save();
    canvas.translate(-halfLen * 0.8, 0);
    canvas.rotate(tailWag);

    final tailPath = Path()
      ..moveTo(0, 0)
      ..lineTo(-bodyLength * 0.38, -halfH * 1.1)
      ..quadraticBezierTo(-bodyLength * 0.28, 0, -bodyLength * 0.38, halfH * 1.1)
      ..close();

    final tailPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          secondaryColor.withValues(alpha: 0.85),
          accentColor.withValues(alpha: 0.65),
        ],
      ).createShader(Rect.fromLTWH(-bodyLength * 0.4, -halfH, bodyLength * 0.4, bodyHeight));
    canvas.drawPath(tailPath, tailPaint);

    // Tail fin ray accents
    final finRayPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawLine(const Offset(0, 0), Offset(-bodyLength * 0.35, -halfH * 0.8), finRayPaint);
    canvas.drawLine(const Offset(0, 0), Offset(-bodyLength * 0.35, halfH * 0.8), finRayPaint);
    canvas.restore();

    // B. Dorsal Fin (Top Spine)
    final dorsalPath = Path()
      ..moveTo(halfLen * 0.1, -halfH * 0.9)
      ..quadraticBezierTo(
        -halfLen * 0.1,
        -halfH * 1.6,
        -halfLen * 0.45,
        -halfH * 0.65,
      )
      ..lineTo(-halfLen * 0.3, -halfH * 0.6)
      ..close();
    final dorsalPaint = Paint()
      ..color = secondaryColor.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;
    canvas.drawPath(dorsalPath, dorsalPaint);

    // C. Streamlined Fish Body
    final bodyPath = Path()
      ..moveTo(halfLen, 0) // Snout/Nose
      ..cubicTo(
        halfLen * 0.6,
        -halfH,
        -halfLen * 0.2,
        -halfH * 1.05,
        -halfLen * 0.8,
        -halfH * 0.25,
      ) // Dorsal curve
      ..lineTo(-halfLen * 0.8, halfH * 0.25) // Caudal peduncle
      ..cubicTo(
        -halfLen * 0.2,
        halfH * 1.05,
        halfLen * 0.6,
        halfH,
        halfLen,
        0,
      ) // Ventral curve
      ..close();

    final bodyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        primaryColor,
        secondaryColor,
        accentColor.withValues(alpha: 0.8),
      ],
      stops: const [0.0, 0.45, 1.0],
    );
    final bodyPaint = Paint()..shader = bodyGradient.createShader(Rect.fromLTWH(-halfLen, -halfH, bodyLength, bodyHeight));
    canvas.drawPath(bodyPath, bodyPaint);

    // D. Shimmering Lateral Line
    final linePath = Path()
      ..moveTo(halfLen * 0.5, 0)
      ..quadraticBezierTo(0, halfH * 0.1, -halfLen * 0.7, 0);
    final linePaint = Paint()
      ..color = glowColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(linePath, linePaint);

    // E. Pectoral Fin (Side fin flutters)
    final double finFlutter = math.sin(t * tailFreq + 1.2) * 0.25;
    canvas.save();
    canvas.translate(halfLen * 0.2, halfH * 0.15);
    canvas.rotate(finFlutter);
    final pecPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-bodyLength * 0.15, halfH * 0.5, -bodyLength * 0.22, halfH * 0.1)
      ..close();
    final pecPaint = Paint()..color = secondaryColor.withValues(alpha: 0.7);
    canvas.drawPath(pecPath, pecPaint);
    canvas.restore();

    // F. Eye (Cornea, Pupil, Specular Catchlight)
    final eyeCenter = Offset(halfLen * 0.62, -halfH * 0.2);
    final eyeRadius = bodyHeight * 0.16;

    // Eye white/glow
    canvas.drawCircle(
      eyeCenter,
      eyeRadius,
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );
    // Dark pupil
    canvas.drawCircle(
      eyeCenter + const Offset(0.4, 0),
      eyeRadius * 0.65,
      Paint()..color = const Color(0xFF0F172A),
    );
    // Specular highlight
    canvas.drawCircle(
      eyeCenter + const Offset(-0.3, -0.4),
      eyeRadius * 0.28,
      Paint()..color = Colors.white,
    );

    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // 8. RISING WATER BUBBLES WITH 3D SPECULAR HIGHLIGHTS
  // ---------------------------------------------------------------------------
  void _paintBubbles(Canvas canvas, Size size) {
    // 24 bubbles with varied sizes, speeds, and wobble paths
    const int bubbleCount = 24;
    for (int i = 0; i < bubbleCount; i++) {
      final double seed = (i * 43.19) % 1.0;
      final double speed = 24.0 + (i % 6) * 10.0;
      final double wobbleFreq = 2.0 + (i % 4) * 0.7;
      final double wobbleAmp = 3.0 + (i % 3) * 2.5;

      // Wrap-around rising math
      final double totalH = size.height + 40.0;
      final double y = totalH - ((time * speed + seed * totalH * 2) % totalH) - 20.0;

      // Base X distribution: aerator columns near edges + ambient bubbles
      double baseX;
      if (i < 8) {
        // Left aerator bubble column
        baseX = size.width * 0.15 + (i % 3) * 6.0;
      } else if (i < 16) {
        // Right aerator bubble column
        baseX = size.width * 0.85 - (i % 3) * 6.0;
      } else {
        // Distributed ambient tank bubbles
        baseX = seed * size.width;
      }

      final double x = baseX + math.sin(time * wobbleFreq + i) * wobbleAmp;
      final double radius = 1.6 + (i % 5) * 0.9;

      // Outer bubble rim
      final rimPaint = Paint()
        ..color = const Color(0xFF67E8F9).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(Offset(x, y), radius, rimPaint);

      // Translucent bubble body
      final fillPaint = Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), radius, fillPaint);

      // 3D Specular highlight crescent
      final hlCenter = Offset(x - radius * 0.35, y - radius * 0.35);
      final hlPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.75)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(hlCenter, radius * 0.28, hlPaint);
    }
  }

  // ---------------------------------------------------------------------------
  // 9. FOREGROUND ROCKS & AMBIENT VIGNETTE
  // ---------------------------------------------------------------------------
  void _paintForegroundRocks(Canvas canvas, Size size) {
    final rockPaint = Paint()
      ..color = const Color(0xFF031628).withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;

    final rockPath = Path()
      ..moveTo(0, size.height * 0.88)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.80,
        size.width * 0.55,
        size.height * 0.89,
      )
      ..quadraticBezierTo(
        size.width * 0.80,
        size.height * 0.83,
        size.width,
        size.height * 0.92,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(rockPath, rockPaint);
  }

  void _paintAmbientVignette(Canvas canvas, Rect rect) {
    // Subtle top & side vignette to frame the tank card and enhance live sensor data legibility
    final vignette = RadialGradient(
      center: Alignment.center,
      radius: 1.05,
      colors: [
        Colors.transparent,
        const Color(0xFF021424).withValues(alpha: 0.45),
      ],
      stops: const [0.65, 1.0],
    );
    final paint = Paint()..shader = vignette.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _DeepSeaPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}

class _KelpConfig {
  final double xRatio;
  final double heightRatio;
  final double swaySpeed;
  final double phase;
  final double width;

  const _KelpConfig({
    required this.xRatio,
    required this.heightRatio,
    required this.swaySpeed,
    required this.phase,
    required this.width,
  });
}
