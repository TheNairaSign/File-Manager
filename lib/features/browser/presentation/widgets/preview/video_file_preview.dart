import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:file_manager/features/browser/presentation/providers/video_thumbnail_provider.dart';
import 'package:file_manager/models/video_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:video_player/video_player.dart';

/// Thumbnail mode: uses Signals to fetch the video thumbnail asynchronously.
/// Full-screen mode: initializes a real `VideoPlayerController` for playback.
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
  // Instance of our Signals controller for tile thumbnails
  late final VideoThumbnailProvider _thumbnailProvider;

  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  bool _initFailed = false;

  @override
  void initState() {
    super.initState();

    if (widget.fullScreen) {
      _initController();
    } else {
      _thumbnailProvider = VideoThumbnailProvider();
      _fetchThumbnail();
    }
  }

  /// Triggers native thumbnail extraction via signals
  void _fetchThumbnail() {
    final config = VideoThumbnailConfig(
      video: widget.file.path,
      maxHeight: 300, // Reduced resolution for efficient grid previews
      quality: 75,
      imageFormat: ImageFormat.JPEG,
    );

    _thumbnailProvider.generateData(config);
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
    if (!widget.fullScreen) {
      _thumbnailProvider.clear();
    }
    _controller?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── 1. TILE MODE (Signal Thumbnail) ───────────────────────────────────
    if (!widget.fullScreen) {
      return Watch((context) {
        final isLoading = _thumbnailProvider.isLoading.watch(context);
        final bytes = _thumbnailProvider.thumbnailBytes.watch(context);
        final hasError = _thumbnailProvider.hasError.watch(context);

        return Container(
          color: Colors.black87,
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            fit: StackFit.expand,
            children: [
              // Display extracted thumbnail image bytes
              if (bytes != null)
                Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                ),

              // Play icon overlay
              if (!isLoading)
                const Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    color: Colors.white,
                    size: 36,
                  ),
                ),

              // Loading spinner
              if (isLoading)
                const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),

              // Fallback error indicator
              if (hasError && bytes == null)
                const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 28,
                  ),
                ),
            ],
          ),
        );
      });
    }

    // ── 2. FULLSCREEN MODE (VideoPlayer) ──────────────────────────────────
    if (_initFailed) {
      return Center(
        child: Text(
          'Unable to play this video',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    final controller = _controller;
    if (controller == null) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    
    final chewieController = _chewieController?? ChewieController(
      videoPlayerController: controller,
      autoPlay: true,
      looping: false,
      showControls: true,
    );

    final playerWidget = Chewie(
      controller: chewieController,
    );
    return playerWidget;
    
/*
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
    */
  }
}