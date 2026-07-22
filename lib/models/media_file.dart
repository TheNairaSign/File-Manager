class MediaFile {
  final int id;
  final String name;
  final String path;
  final String mimeType;
  final int size;
  final int dateModified;

  // Video
  final int? duration;
  final int? width;
  final int? height;

  // Audio
  final String? artist;
  final String? album;

  const MediaFile({
    required this.id,
    required this.name,
    required this.path,
    required this.mimeType,
    required this.size,
    required this.dateModified,
    this.duration,
    this.width,
    this.height,
    this.artist,
    this.album,
  });

  factory MediaFile.fromJson(Map<dynamic, dynamic> json) {
    return MediaFile(
      id: json['id'],
      name: json['name'],
      path: json['path'],
      mimeType: json['mimeType'],
      size: json['size'],
      dateModified: json['dateModified'],
      duration: json['duration']?.toInt(),
      width: json['width']?.toInt(),
      height: json['height']?.toInt(),
      artist: json['artist'],
      album: json['album'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'mimeType': mimeType,
      'size': size,
      'dateModified': dateModified,
      'duration': duration,
      'width': width,
      'height': height,
      'artist': artist,
      'album': album,
    };
  }
}