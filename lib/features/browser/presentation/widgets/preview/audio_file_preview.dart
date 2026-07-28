import 'dart:io';

import 'package:file_manager/features/browser/presentation/widgets/preview/preview_file_type.dart';
import 'package:file_manager/features/browser/presentation/widgets/preview/preview_service.dart';
import 'package:flutter/material.dart';
// Requires: audioplayers: ^6.0.0 (add to pubspec.yaml)
import 'package:audioplayers/audioplayers.dart';

/// Thumbnail mode: a static waveform-style icon tile (no playback started —
/// starting an AudioPlayer per grid tile would be wasteful).
/// Full-screen mode: a minimal play/pause + seek bar player.
class AudioFilePreview extends StatefulWidget {
  const AudioFilePreview({
    super.key,
    required this.file,
    this.fullScreen = false,
  });

  final File file;
  final bool fullScreen;

  @override
  State<AudioFilePreview> createState() => _AudioFilePreviewState();
}

class _AudioFilePreviewState extends State<AudioFilePreview> {
  final _player = AudioPlayer();
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    if (widget.fullScreen) {
      _player.onPositionChanged.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      _player.onDurationChanged.listen((d) {
        if (mounted) setState(() => _total = d);
      });
      _player.onPlayerStateChanged.listen((s) {
        if (mounted) setState(() => _isPlaying = s == PlayerState.playing);
      });
    }
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play(DeviceFileSource(widget.file.path));
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = FilePreviewService.colorFor(PreviewFileType.audio);

    if (!widget.fullScreen) {
      return Container(
        color: color.withValues(alpha: 0.1),
        alignment: Alignment.center,
        child: Icon(Icons.audiotrack, color: color, size: 32),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.audiotrack, color: color, size: 64),
          const SizedBox(height: 16),
          Slider(
            value: _position.inMilliseconds
                .clamp(0, _total.inMilliseconds == 0 ? 1 : _total.inMilliseconds)
                .toDouble(),
            max: (_total.inMilliseconds == 0 ? 1 : _total.inMilliseconds)
                .toDouble(),
            onChanged: (v) =>
                _player.seek(Duration(milliseconds: v.round())),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 42,
                icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle),
                onPressed: _togglePlay,
              ),
            ],
          ),
        ],
      ),
    );
  }
}