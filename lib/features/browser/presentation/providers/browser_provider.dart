import 'package:file_manager/core/platform/permission/permission_service.dart';
import 'package:file_manager/core/platform/permission/permission_state.dart';
import 'package:file_manager/models/file_item.dart';
import 'package:file_manager/models/storage_volume.dart';
import 'package:file_manager/core/platform/file_channel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class BrowserState {
  final String currentPath;
  final List<FileItem> items;
  final bool isLoading;
  final String? error;
  final FileItem? clipboardItem;
  final bool isCopying;
  final bool isGridView;

  BrowserState({
    required this.currentPath,
    required this.items,
    this.isLoading = false,
    this.error,
    this.clipboardItem,
    this.isCopying = true,
    this.isGridView = false,
  });

  BrowserState copyWith({
    String? currentPath,
    List<FileItem>? items,
    bool? isLoading,
    String? error,
    FileItem? clipboardItem,
    bool? isCopying,
    bool clearClipboard = false,
    bool? isGridView,
  }) {
    return BrowserState(
      currentPath: currentPath ?? this.currentPath,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      clipboardItem: clearClipboard ? null : (clipboardItem ?? this.clipboardItem),
      isCopying: isCopying ?? this.isCopying,
      isGridView: isGridView ?? this.isGridView,
    );
  }
}

class BrowserNotifier extends StateNotifier<BrowserState> {
  final FileChannel _fileChannel;
  final String initialPath;

  BrowserNotifier(
    this._fileChannel, 
    this.initialPath,
  ) : super(BrowserState(currentPath: initialPath, items: [])) {
    _init();
  }

  Future<void> _init() async {
    await checkAndLoadIfGranted();
  }

  Future<void> checkAndLoadIfGranted() async {
    state = state.copyWith(isLoading: true);
    final check = await PermissionService.checkPermissionStatus();
    check.fold(
      (error) {
        state = state.copyWith(isLoading: false, error: error.message);
      },
      (permState) async {
        if (permState.status == StoragePermissionStatus.granted) {
          await _loadStorageAndDirectory();
        } else {
          state = state.copyWith(
            isLoading: false,
            error: 'Storage permission is required to browse files.',
          );
        }
      },
    );
  }

  Future<void> loadStorageAndDirectory() async {
    state = state.copyWith(isLoading: true, error: null);
    await _loadStorageAndDirectory();
  }

  Future<void> _loadStorageAndDirectory() async {
    if (initialPath.isEmpty) {
      final result = await _fileChannel.getStoragePath();
      result.fold(
        (error) => state = state.copyWith(isLoading: false, error: error.toString()),
        (path) {
          state = state.copyWith(currentPath: path);
          loadDirectory(path);
        },
      );
    } else {
      loadDirectory(initialPath);
    }
  }

  Future<void> openAppSettings() async {
    await _fileChannel.openAppSettings();
  }

  Future<void> loadDirectory(String path) async {
    state = state.copyWith(isLoading: true, currentPath: path);
    // Note: page: 0 is used here for simplicity. Pagination can be added later.
    final result = await _fileChannel.listDirectory(path: path, page: 0);
    result.fold(
      (error) => state = state.copyWith(isLoading: false, error: error.toString()),
      (items) => state = state.copyWith(isLoading: false, items: items),
    );
  }

  Future<void> refresh() async {
    if (state.currentPath.isNotEmpty) {
      await loadDirectory(state.currentPath);
    } else {
      await _init();
    }
  }

  Future<void> deleteItem(FileItem item) async {
    final result = await _fileChannel.deleteEntry(item.path);
    result.fold(
      (error) => state = state.copyWith(error: error.toString()),
      (_) => refresh(),
    );
  }

  Future<void> renameItem(FileItem item, String newName) async {
    final parentPath = item.path.substring(0, item.path.lastIndexOf('/'));
    final newPath = '$parentPath/$newName';
    final result = await _fileChannel.renameEntry(
      sourcePath: item.path,
      destinationPath: newPath,
    );
    result.fold(
      (error) => state = state.copyWith(error: error.toString()),
      (_) => refresh(),
    );
  }

  Future<void> createFolder(String name) async {
    if (state.currentPath.isEmpty) return;
    final newPath = '${state.currentPath}/$name';
    final result = await _fileChannel.createDirectory(newPath);
    result.fold(
      (error) => state = state.copyWith(error: error.toString()),
      (_) => refresh(),
    );
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      refresh();
      return;
    }
    state = state.copyWith(isLoading: true);
    final result = await _fileChannel.searchFiles(
      query: query,
      rootPath: state.currentPath.isEmpty ? '/' : state.currentPath,
    );
    result.fold(
      (error) => state = state.copyWith(isLoading: false, error: error.toString()),
      (items) => state = state.copyWith(isLoading: false, items: items),
    );
  }

  void copyItem(FileItem item) {
    state = state.copyWith(clipboardItem: item, isCopying: true);
  }

  void moveItem(FileItem item) {
    state = state.copyWith(clipboardItem: item, isCopying: false);
  }

  Future<void> paste() async {
    final item = state.clipboardItem;
    if (item == null) return;

    final destination = '${state.currentPath}/${item.name}';
    final result = state.isCopying
        ? await _fileChannel.copyEntry(sourcePath: item.path, destinationPath: destination)
        : await _fileChannel.moveEntry(sourcePath: item.path, destinationPath: destination);

    result.fold(
      (error) => state = state.copyWith(error: error.toString()),
      (_) {
        state = state.copyWith(clearClipboard: true);
        refresh();
      },
    );
  }

  void cancelPaste() {
    state = state.copyWith(clearClipboard: true);
  }

  void setGridView(bool isGrid) {
    state = state.copyWith(isGridView: isGrid);
  }

  void toggleViewMode() {
    state = state.copyWith(isGridView: !state.isGridView);
  }

  void navigateInto(FileItem item) {
    if (item.isDirectory) {
      loadDirectory(item.path);
    }
  }

  void navigateUp() {
    if (state.currentPath.isEmpty || state.currentPath == '/') return;
    
    final parts = state.currentPath.split('/');
    if (parts.length > 1) {
      parts.removeLast();
      String parentPath = parts.join('/');
      if (parentPath.isEmpty) parentPath = '/';
      loadDirectory(parentPath);
    }
  }
}

final browserProviderFor = StateNotifierProvider.family<BrowserNotifier, BrowserState, String>((ref, path) {
  final fileChannel = ref.watch(fileChannelProvider);
  return BrowserNotifier(fileChannel, path);
});

final storageVolumesProvider = FutureProvider<List<StorageVolume>>((ref) async {
  final fileChannel = ref.watch(fileChannelProvider);
  final volumes = await fileChannel.getStorageVolumes();
  if (volumes.isEmpty) {
    final pathResult = await fileChannel.getStoragePath();
    final primaryPath = pathResult.fold((_) => '/storage/emulated/0', (p) => p);
    try {
      final storageInfo = await fileChannel.getStorageInfo();
      return [
        StorageVolume(
          uuid: 'primary',
          description: 'Internal Storage',
          path: primaryPath,
          isPrimary: true,
          isRemovable: false,
          state: 'mounted',
          totalBytes: storageInfo.total,
          availableBytes: storageInfo.free,
          usedBytes: storageInfo.used,
        ),
      ];
    } catch (_) {
      return [
        StorageVolume(
          uuid: 'primary',
          description: 'Internal Storage',
          path: primaryPath,
          isPrimary: true,
          isRemovable: false,
          state: 'mounted',
          totalBytes: 0,
          availableBytes: 0,
          usedBytes: 0,
        ),
      ];
    }
  }
  return volumes;
});
