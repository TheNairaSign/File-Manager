import 'dart:math' as math;
import 'package:file_manager/core/helpers/byte_converter.dart';
import 'package:file_manager/features/browser/presentation/pages/folder_page.dart';
import 'package:file_manager/models/storage_volume.dart';
import 'package:flutter/material.dart';

class StorageVolumeCard extends StatefulWidget {
  final StorageVolume? volume;
  /// Fill level, clamped to [0, 1]. Used if volume is null.
  final double progress;
  final bool isSelected;
  final VoidCallback? onTap;

  final double width;
  final double height;

  /// How long the fill animates when [progress] changes.
  final Duration animationDuration;

  /// Duration of one full wave oscillation cycle (continuous, looping).
  final Duration waveDuration;

  final BorderRadius borderRadius;

  /// Optional label rendered if volume is null.
  final String? label;
  final TextStyle? labelStyle;

  /// Background color behind the wave.
  final Color backgroundColor;

  /// Whether to draw border outline.
  final bool showBorder;

  const StorageVolumeCard({
    super.key,
    this.volume,
    this.progress = 0.0,
    this.isSelected = false,
    this.onTap,
    this.width = 180,
    this.height = 80,
    this.animationDuration = const Duration(milliseconds: 700),
    this.waveDuration = const Duration(seconds: 3),
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.label,
    this.labelStyle,
    this.backgroundColor = Colors.transparent,
    this.showBorder = false,
  });

  @override
  State<StorageVolumeCard> createState() => _StorageVolumeCardState();
}

class _StorageVolumeCardState extends State<StorageVolumeCard> with TickerProviderStateMixin {
  late final AnimationController _waveController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  double _previousProgress = 0;

  double get _clampedTarget {
    final val = widget.volume?.usageRatio ?? widget.progress;
    return val.clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _waveController =
        AnimationController(vsync: this, duration: widget.waveDuration)
          ..repeat();

    _progressController =
        AnimationController(vsync: this, duration: widget.animationDuration);

    _previousProgress = _clampedTarget;
    _progressAnimation = Tween<double>(begin: 0, end: _previousProgress).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    _progressController.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant StorageVolumeCard oldWidget) {
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

  String _getVolumeTitle() {
    if (widget.volume == null) return widget.label ?? 'Storage';
    if (widget.volume!.isPrimary) {
      return 'Internal Storage';
    }
    if (widget.volume!.description.isNotEmpty && widget.volume!.description != 'Storage') {
      return widget.volume!.description;
    }
    return 'External Storage';
  }

  IconData _getVolumeIcon() {
    if (widget.volume == null) return Icons.storage_rounded;
    if (widget.volume!.isPrimary) {
      return Icons.smartphone_rounded;
    }
    if (widget.volume!.isRemovable) {
      return Icons.sd_card_rounded;
  }
    return Icons.storage_rounded;
  }

  /// Maps a progress value to a color.
  static Color colorForProgress(BuildContext context, double p) {
    final grey = Theme.of(context).colorScheme.surface;
    const yellow = Color(0xFFFFC107);
    const orange = Color(0xFFFF9800);
    const red = Color(0xFFE53935);

    if (p <= 0.001) return grey;
    if (p < 0.75) {
      final t = (p / 0.75).clamp(0.0, 1.0);
      return Color.lerp(grey, yellow, t)!;
    }
    if (p < 0.90) {
      final t = ((p - 0.75) / 0.15).clamp(0.0, 1.0);
      return Color.lerp(yellow, orange, t)!;
    }
    final t = ((p - 0.90) / 0.10).clamp(0.0, 1.0);
    return Color.lerp(Colors.redAccent, red, t)!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ratio = _clampedTarget;
    final percentText = (ratio * 100).toInt();

    final isSelected = widget.isSelected;
    final borderColor = isSelected
        ? theme.colorScheme.primary
        : theme.dividerColor.withValues(alpha: 0.15);

    return Material(
      color: Colors.transparent,
      borderRadius: widget.borderRadius,
      child: InkWell(
        // onTap: widget.onTap,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FolderPage(path: widget.volume!.path),
            ),
          );
        },
        borderRadius: widget.borderRadius,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            // border: Border.all(
            //   color: Colors.grey[isDark ? 800 : 200]!,
            //   width: isSelected ? 2.0 : 1.0,
            // ),
            // boxShadow: isSelected
            //     ? [
            //         BoxShadow(
            //           color: theme.colorScheme.primary.withValues(alpha: 0.15),
            //           blurRadius: 8,
            //           offset: const Offset(0, 3),
            //         ),
            //       ]
            //     : null,
          ),
          child: ClipRRect(
            borderRadius: widget.borderRadius,
            child: Stack(
              children: [
                // Wave Background Animation
                Positioned.fill(
                  child: Container(
                    color: widget.backgroundColor.withValues(alpha: 0.5),
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_waveController, _progressController]),
                      builder: (context, _) {
                        final p = _progressAnimation.value;
                        final color = colorForProgress(context, p);
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
                  ),
                ),
                // Foreground Text & Icon Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      // Container(
                      //   padding: const EdgeInsets.all(8),
                      //   decoration: BoxDecoration(
                      //     // color: isSelected
                      //     //     ? theme.colorScheme.primary
                      //     //     : theme.colorScheme.primary.withValues(alpha: 0.15),
                      //     color: Colors.transparent,
                      //     borderRadius: BorderRadius.circular(10),
                      //   ),
                      //   child: Icon(
                      //     _getVolumeIcon(),
                      //     size: 20,
                      //     // color: isSelected
                      //     //     ? theme.colorScheme.onPrimary
                      //     //     : theme.colorScheme.primary,
                      //   ),
                      // ),
                      // const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _getVolumeTitle(),
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // if (isSelected)
                                //   Icon(
                                //     Icons.check_circle_rounded,
                                //     size: 16,
                                //     color: theme.colorScheme.primary,
                                //   ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  widget.volume != null && widget.volume!.totalBytes > 0
                                      ? '${formatBytes(widget.volume!.usedBytes)} / ${formatBytes(widget.volume!.totalBytes)}'
                                      : widget.label ?? 'Storage',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    // color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                                    color: Colors.grey
                                  ),
                                ),
                                Text(
                                  '$percentText%',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: colorForProgress(context, ratio),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
    if (progress <= 0.001) return; // fully empty: backgroundColor shows through

    final waveHeight = size.height * 0.035;
    final baseline = size.height * (1 - progress);

    void drawWave(double phaseOffset, double amplitudeScale, double opacity) {
      final path = Path();
      final paint = Paint()..color = color.withValues(alpha: opacity);
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
    drawWave(math.pi / 2, 0.6, 0.10);
    // Front wave: the primary fill.
    drawWave(0, 1.0, 0.25);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.color != color;
  }
}