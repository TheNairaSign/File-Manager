// media_manager.dart
import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:file_manager/core/errors/media_channel_error.dart';
import 'package:file_manager/models/media_file.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MediaManager {
  static const String channel = 'com.example.filemanager/files';
  static const MethodChannel platformChannel = MethodChannel(channel);

  Future<Either<MediaChannelError, List<MediaFile>>> getAudioFiles() =>
      _fetchList('audio', 'audio');

  Future<Either<MediaChannelError, List<MediaFile>>> getVideoFiles() =>
      _fetchList('videos', 'videos');

  Future<Either<MediaChannelError, List<MediaFile>>> getImageFiles() =>
      _fetchList('images', 'images');

  Future<Either<MediaChannelError, List<MediaFile>>> getDocumentFiles() =>
      _fetchList('docs', 'docs');

  Future<Either<MediaChannelError, List<MediaFile>>> _fetchList(
    String method,
    String key,
  ) async {
    final result = await _invoke<List<Object?>>(method);
    log("Result on method $method is $result", name: "MediaManager");
    return result.map((data) {
      return data
          .cast<Map<Object?, Object?>>()
          .map(MediaFile.fromJson)
          .toList();
    });
  }

  Future<Either<MediaChannelError, T>> _invoke<T>(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    try {
      final result = await platformChannel.invokeMethod<T>('getMedia', {
        'type': method,
      });

      if (result == null) {
        return Left(MediaChannelError(
          code: 'NULL_RESULT',
          message: '$method returned null unexpectedly',
        ));
      }
      log("Result on method $method is $result", name: "MediaManager");
      return Right(result);
    } on PlatformException catch (e) {
      log('[MediaChannel] $method failed — ${e.code}: ${e.message}');
      return Left(MediaChannelError(
        code: e.code,
        message: e.message ?? 'No message',
      ));
    } catch (e) {
      log('[MediaChannel] $method unexpected error: $e');
      return Left(MediaChannelError(
        code: 'UNEXPECTED_ERROR',
        message: e.toString(),
      ));
    }
  }
}

final mediaManagerProvider = Provider<MediaManager>((_) => MediaManager());