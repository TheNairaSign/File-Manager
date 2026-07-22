import 'package:flutter/material.dart';

enum MediaTypeItemType {
  audio,
  video,
  image,
  document,
}

class MediaCategory {
  final String title;
  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback onTap;
  final MediaTypeItemType type;

  const MediaCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.count,
    required this.onTap,
    required this.type,
  });

  List<MediaCategory> get categories => [
    MediaCategory(
      title: 'Audio',
      icon: Icons.music_note,
      color: Colors.red,
      count: 100,
      onTap: () {},
      type: MediaTypeItemType.audio,
    ),
    MediaCategory(
      title: 'Video',
      icon: Icons.video_call,
      color: Colors.blue,
      count: 200,
      onTap: () {},
      type: MediaTypeItemType.video,
    ),
    MediaCategory(
      title: 'Image',
      icon: Icons.image,
      color: Colors.green,
      count: 300,
      onTap: () {},
      type: MediaTypeItemType.image,
    ),
    MediaCategory(
      title: 'Document',
      icon: Icons.file_download,
      color: Colors.yellow,
      count: 400,
      onTap: () {},
      type: MediaTypeItemType.document,
    ),
  ];
}
