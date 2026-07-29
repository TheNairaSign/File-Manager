import 'package:flutter/foundation.dart';

/// Supported image formats for video thumbnail generation.
// ignore: constant_identifier_names
enum ImageFormat { JPEG, PNG, WEBP }

/// Data configuration model representing video thumbnail parameters.
@immutable
class VideoThumbnailConfig {
  /// The video source path (local file path or remote HTTP URL).
  final String video;

  /// Optional HTTP headers for network video requests.
  final Map<String, String>? headers;

  /// Custom target output file path (used only when generating a file).
  final String? thumbnailPath;

  /// Target encoding format (JPEG, PNG, or WEBP).
  final ImageFormat imageFormat;

  /// Maximum thumbnail height in pixels (0 maintains original height).
  final int maxHeight;

  /// Maximum thumbnail width in pixels (0 maintains original width).
  final int maxWidth;

  /// Frame timestamp in milliseconds to capture.
  final int timeMs;

  /// Compression quality ranging from 0 to 100 (ignored for PNG format).
  final int quality;

  const VideoThumbnailConfig({
    required this.video,
    this.headers,
    this.thumbnailPath,
    this.imageFormat = ImageFormat.PNG,
    this.maxHeight = 0,
    this.maxWidth = 0,
    this.timeMs = 0,
    this.quality = 10,
  }) : assert(quality >= 0 && quality <= 100, 'Quality must be between 0 and 100');

  /// Converts thumbnail settings into a native-ready argument map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'video': video,
      'headers': headers,
      'path': thumbnailPath,
      'format': imageFormat.index,
      'maxh': maxHeight,
      'maxw': maxWidth,
      'timeMs': timeMs,
      'quality': quality,
    };
  }

  VideoThumbnailConfig copyWith({
    String? video,
    Map<String, String>? headers,
    String? thumbnailPath,
    ImageFormat? imageFormat,
    int? maxHeight,
    int? maxWidth,
    int? timeMs,
    int? quality,
  }) {
    return VideoThumbnailConfig(
      video: video ?? this.video,
      headers: headers ?? this.headers,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      imageFormat: imageFormat ?? this.imageFormat,
      maxHeight: maxHeight ?? this.maxHeight,
      maxWidth: maxWidth ?? this.maxWidth,
      timeMs: timeMs ?? this.timeMs,
      quality: quality ?? this.quality,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoThumbnailConfig &&
        other.video == video &&
        mapEquals(other.headers, headers) &&
        other.thumbnailPath == thumbnailPath &&
        other.imageFormat == imageFormat &&
        other.maxHeight == maxHeight &&
        other.maxWidth == maxWidth &&
        other.timeMs == timeMs &&
        other.quality == quality;
  }

  @override
  int get hashCode => Object.hash(
        video,
        headers,
        thumbnailPath,
        imageFormat,
        maxHeight,
        maxWidth,
        timeMs,
        quality,
      );
}