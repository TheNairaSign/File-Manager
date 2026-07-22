// media_provider.dart
import 'package:file_manager/core/platform/media_manager.dart';
import 'package:file_manager/features/browser/media_category.dart';
import 'package:file_manager/models/media_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _unset = Object();

class MediaState {
  final bool isLoading;
  final List<MediaFile> files;
  final String? error;

  MediaState({
    required this.isLoading,
    this.files = const [],
    this.error,
  });

  factory MediaState.initial() => MediaState(isLoading: true);

  MediaState copyWith({
    bool? isLoading,
    List<MediaFile>? files,
    Object? error = _unset,
  }) {
    return MediaState(
      isLoading: isLoading ?? this.isLoading,
      files: files ?? this.files,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }
}

class MediaProvider extends Notifier<MediaState> {
  final MediaTypeItemType type;
  MediaProvider(this.type);

  late final MediaManager _mediaManager;

  @override
  MediaState build() {
    _mediaManager = ref.watch(mediaManagerProvider);
    Future.microtask(() => _loadFiles(type));
    return MediaState.initial();
  }

  Future<void> refresh() => _loadFiles(type);

  Future<void> _loadFiles(MediaTypeItemType type) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = switch (type) {
      MediaTypeItemType.audio => await _mediaManager.getAudioFiles(),
      MediaTypeItemType.video => await _mediaManager.getVideoFiles(),
      MediaTypeItemType.image => await _mediaManager.getImageFiles(),
      MediaTypeItemType.document => await _mediaManager.getDocumentFiles(),
    };

    result.fold(
      (error) => state = state.copyWith(isLoading: false, error: error.message),
      (files) => state = state.copyWith(isLoading: false, files: files, error: null),
    );
  }
}

/// Manual "family": one cached NotifierProvider per MediaTypeItemType.
final _mediaProviderCache = <MediaTypeItemType, NotifierProvider<MediaProvider, MediaState>>{};

NotifierProvider<MediaProvider, MediaState> mediaProviderFor(MediaTypeItemType type) {
  return _mediaProviderCache.putIfAbsent(
    type,
    () => NotifierProvider<MediaProvider, MediaState>(() => MediaProvider(type)),
  );
}