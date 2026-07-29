import 'dart:typed_data';

import 'package:file_manager/core/platform/file_channel.dart';
import 'package:file_manager/models/video_thumbnail.dart';
import 'package:signals_flutter/signals_flutter.dart';

class VideoThumbnailProvider {
  
  /// Configuration signal (video path, quality, dimensions, etc.)
  final Signal<VideoThumbnailConfig?> config = signal(null);

  /// State signal for file output path
  final Signal<String?> thumbnailPath = signal(null);

  /// State signal for in-memory byte output
  final Signal<Uint8List?> thumbnailBytes = signal(null);

  /// Status flags
  final Signal<bool> isLoading = signal(false);
  final Signal<String?> errorMessage = signal(null);

  // ─── Computed Signals (Derived State) ───────────────────────────────────

  /// Evaluates true if thumbnail data or path exists
  late final Computed<bool> hasThumbnail = computed(() {
    return thumbnailBytes.value != null || (thumbnailPath.value?.isNotEmpty ?? false);
  });

  /// Evaluates true if an error is present
  late final Computed<bool> hasError = computed(() {
    return errorMessage.value != null;
  });

  // ─── Actions / Methods ───────────────────────────────────────────────────

  /// Generates a thumbnail file on local storage
  Future<String?> generateFile(VideoThumbnailConfig newConfig) async {
    _resetState(newConfig);
    final fileChannel = FileChannel();

    try {
      final path = await fileChannel.fetchFile(newConfig);
      thumbnailPath.value = path;
      return path;
    } catch (e) {
      errorMessage.value = e.toString();
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Generates thumbnail byte data directly in memory
  Future<Uint8List?> generateData(VideoThumbnailConfig newConfig) async {
    _resetState(newConfig);
    final fileChannel = FileChannel();

    try {
      final bytes = await fileChannel.fetchData(newConfig);
      thumbnailBytes.value = bytes;
      return bytes;
    } catch (e) {
      errorMessage.value = e.toString();
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Clears active signals back to initial state
  void clear() {
    config.value = null;
    thumbnailPath.value = null;
    thumbnailBytes.value = null;
    errorMessage.value = null;
    isLoading.value = false;
  }

  void _resetState(VideoThumbnailConfig newConfig) {
    config.value = newConfig;
    isLoading.value = true;
    errorMessage.value = null;
    thumbnailPath.value = null;
    thumbnailBytes.value = null;
  }
}