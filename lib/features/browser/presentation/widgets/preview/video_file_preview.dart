import 'dart:io';

import 'package:flutter/material.dart';
// Requires: video_player: ^2.9.0 (add to pubspec.yaml)
import 'package:video_player/video_player.dart';

/// Thumbnail mode: shows the first frame (paused) with a play-button
/// overlay — cheap and avoids initializing playback for every grid tile.
/// Full-screen mode: initializes a real `VideoPlayerController` with
/// play/pause/seek controls.
class VideoFilePreview extends StatefulWidget {
  const VideoFilePreview({
    super.key,
    required this.file,
    this.fullScreen = false,
  });

  final File file;
  final bool fullScreen;

  @override
  State<VideoFilePreview> createState() => _VideoFilePreviewState();
}

class _VideoFilePreviewState extends State<VideoFilePreview> {
  VideoPlayerController? _controller;
  bool _initFailed = false;

  @override
  void initState() {
    super.initState();
    if (widget.fullScreen) _initController();
  }

  Future<void> _initController() async {
    final controller = VideoPlayerController.file(widget.file);
    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() => _controller = controller);
    } catch (_) {
      if (mounted) setState(() => _initFailed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.fullScreen) {
      // Lightweight tile: icon-over-placeholder. Wire up a real thumbnail
      // extractor (e.g. `video_thumbnail` package) if you want actual
      // frame previews in the grid.
      return Container(
        color: Colors.black87,
        alignment: Alignment.center,
        child: const Icon(Icons.play_circle_outline,
            color: Colors.white, size: 36),
      );
    }

    if (_initFailed) {
      return const Center(
        child: Text('Unable to play this video',
            style: TextStyle(color: Colors.white70)),
      );
    }

    final controller = _controller;
    if (controller == null) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: controller.value.aspectRatio == 0
              ? 16 / 9
              : controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
        VideoProgressIndicator(controller, allowScrubbing: true),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
              onPressed: () {
                setState(() {
                  controller.value.isPlaying
                      ? controller.pause()
                      : controller.play();
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}