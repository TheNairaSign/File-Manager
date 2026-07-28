// wave_progress_indicator.dart
//
// An animated "liquid fill" progress indicator that rises from the bottom
// like a wave. Intended for internal memory / storage state visualization
// in a file management app.
//
// Color semantics (tunable via thresholds below):
//   progress == 0        -> grey   (empty / idle)
//   0 < progress < 0.5    -> grey -> yellow
//   0.5 <= progress <= 1  -> yellow -> red (approaching capacity)
//
// Usage:
//   WaveProgressIndicator(
//     progress: 0.72,          // 0.0 - 1.0
//     width: 140,
//     height: 220,
//     label: 'Memory',
//   )

import 'dart:math' as math;
import 'package:flutter/material.dart';

class WaveProgressIndicator extends StatefulWidget {
  /// Fill level, clamped to [0, 1].
  final double progress;

  final double width;
  final double height;

  /// How long the fill animates when [progress] changes.
  final Duration animationDuration;

  /// Duration of one full wave oscillation cycle (continuous, looping).
  final Duration waveDuration;

  final BorderRadius borderRadius;

  /// Optional label rendered in the center (e.g. "Memory" or a percentage).
  final String? label;
  final TextStyle? labelStyle;

  /// Background color behind the wave (container "empty" color).
  final Color backgroundColor;

  const WaveProgressIndicator({
    super.key,
    required this.progress,
    this.width = 140,
    this.height = 220,
    this.animationDuration = const Duration(milliseconds: 700),
    this.waveDuration = const Duration(seconds: 3),
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.label,
    this.labelStyle,
    this.backgroundColor = const Color(0xFF1E1E1E),
  });

  @override
  State<WaveProgressIndicator> createState() => _WaveProgressIndicatorState();
}

class _WaveProgressIndicatorState extends State<WaveProgressIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _waveController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  double _previousProgress = 0;

  double get _clampedTarget => widget.progress.clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _waveController =
        AnimationController(vsync: this, duration: widget.waveDuration)
          ..repeat();

    _progressController =
        AnimationController(vsync: this, duration: widget.animationDuration);

    _previousProgress = _clampedTarget;
    _progressAnimation = AlwaysStoppedAnimation(_previousProgress);
    // Animate in from 0 on first build for a nice entrance.
    _progressAnimation = Tween<double>(begin: 0, end: _previousProgress)
        .animate(CurvedAnimation(
            parent: _progressController, curve: Curves.easeOutCubic));
    _progressController.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant WaveProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = _clampedTarget;
    if ((target - _previousProgress).abs() > 0.0001) {
      _progressAnimation = Tween<double>(begin: _previousProgress, end: target)
          .animate(CurvedAnimation(
              parent: _progressController, curve: Curves.easeInOutCubic));
      _progressController.forward(from: 0);
      _previousProgress = target;
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  /// Maps a progress value to a color: grey (empty) -> yellow -> red (full).
  static Color colorForProgress(double p) {
    const grey = Color(0xFF9E9E9E);
    const yellow = Color(0xFFFFC107);
    const red = Color(0xFFE53935);

    if (p <= 0.001) return grey;
    if (p < 0.5) {
      final t = (p / 0.5).clamp(0.0, 1.0);
      return Color.lerp(grey, yellow, t)!;
    }
    final t = ((p - 0.5) / 0.5).clamp(0.0, 1.0);
    return Color.lerp(yellow, red, t)!;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Container(
        width: widget.width,
        height: widget.height,
        color: widget.backgroundColor,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: Listenable.merge([_waveController, _progressController]),
              builder: (context, _) {
                final p = _progressAnimation.value;
                final color = colorForProgress(p);
                return CustomPaint(
                  size: Size(widget.width, widget.height),
                  painter: _WavePainter(
                    progress: p,
                    wavePhase: _waveController.value * 2 * math.pi,
                    color: color,
                  ),
                );
              },
            ),
            if (widget.label != null)
              AnimatedBuilder(
                animation: _progressController,
                builder: (context, _) {
                  return Text(
                    widget.label!,
                    textAlign: TextAlign.center,
                    style: widget.labelStyle ??
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(color: Colors.black45, blurRadius: 4),
                          ],
                        ),
                  );
                },
              ),
            // Border outline for definition against dark backgrounds.
            Container(
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius,
                border: Border.all(color: Colors.white24, width: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  final Color color;

  _WavePainter({
    required this.progress,
    required this.wavePhase,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.001) return; // fully empty: background color shows through

    final waveHeight = size.height * 0.035;
    final baseline = size.height * (1 - progress);

    void drawWave(double phaseOffset, double amplitudeScale, double opacity) {
      final path = Path();
      final paint = Paint()..color = color.withOpacity(opacity);
      path.moveTo(0, size.height);
      path.lineTo(0, baseline);

      const step = 2.0;
      for (double x = 0; x <= size.width; x += step) {
        final y = baseline +
            math.sin((x / size.width * 2 * math.pi) + wavePhase + phaseOffset) *
                waveHeight *
                amplitudeScale;
        path.lineTo(x, y);
      }
      path.lineTo(size.width, baseline);
      path.lineTo(size.width, size.height);
      path.close();
      canvas.drawPath(path, paint);
    }

    // Back wave: slower-looking (via phase offset), more transparent, adds depth.
    drawWave(math.pi / 2, 0.6, 0.35);
    // Front wave: the primary fill.
    drawWave(0, 1.0, 0.85);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.color != color;
  }
}

// ---------------------------------------------------------------------------
// Demo / usage example. Remove this section when dropping the widget into
// your own app — only WaveProgressIndicator above is required.
// ---------------------------------------------------------------------------

void main() => runApp(const _DemoApp());

class _DemoApp extends StatelessWidget {
  const _DemoApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const _DemoScreen(),
    );
  }
}

class _DemoScreen extends StatefulWidget {
  const _DemoScreen();

  @override
  State<_DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<_DemoScreen> {
  double _memory = 0.0;
  double _cache = 0.42;
  double _disk = 0.9;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(title: const Text('Storage / Memory State')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  WaveProgressIndicator(
                    progress: _memory,
                    label: '${(_memory * 100).round()}%\nMemory',
                  ),
                  WaveProgressIndicator(
                    progress: _cache,
                    label: '${(_cache * 100).round()}%\nCache',
                  ),
                  WaveProgressIndicator(
                    progress: _disk,
                    label: '${(_disk * 100).round()}%\nDisk',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _slider('Memory', _memory, (v) => setState(() => _memory = v)),
            _slider('Cache', _cache, (v) => setState(() => _cache = v)),
            _slider('Disk', _disk, (v) => setState(() => _disk = v)),
          ],
        ),
      ),
    );
  }

  Widget _slider(String label, double value, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 70, child: Text(label)),
        Expanded(
          child: Slider(value: value, onChanged: onChanged),
        ),
      ],
    );
  }
}