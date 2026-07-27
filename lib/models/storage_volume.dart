class StorageVolume {
  final String uuid;
  final String description;
  final String path;
  final bool isPrimary;
  final bool isRemovable;
  final String state;
  final int totalBytes;
  final int availableBytes;
  final int usedBytes;

  StorageVolume({
    required this.uuid,
    required this.description,
    required this.path,
    required this.isPrimary,
    required this.isRemovable,
    required this.state,
    required this.totalBytes,
    required this.availableBytes,
    required this.usedBytes,
  });

  /// Helper getter to verify if the drive is safe to read/write
  bool get isMounted => state == 'mounted' && path.isNotEmpty;

  /// Usage percentage for rendering UI progress bars (0.0 to 1.0)
  double get usageRatio {
    if (totalBytes <= 0) return 0.0;
    return usedBytes / totalBytes;
  }

  factory StorageVolume.fromMap(Map<String, dynamic> map) {
    return StorageVolume(
      uuid: map['uuid'] as String? ?? 'primary',
      description: map['description'] as String? ?? 'Storage',
      path: map['path'] as String? ?? '',
      isPrimary: map['isPrimary'] as bool? ?? false,
      isRemovable: map['isRemovable'] as bool? ?? false,
      state: map['state'] as String? ?? 'unknown',
      totalBytes: (map['totalBytes'] as num?)?.toInt() ?? 0,
      availableBytes: (map['availableBytes'] as num?)?.toInt() ?? 0,
      usedBytes: (map['usedBytes'] as num?)?.toInt() ?? 0,
    );
  }
}