class FolderModel {
  final String name;
  final int fileCount;
  final bool isSelected;

  const FolderModel({
    required this.name,
    required this.fileCount,
    this.isSelected = false,
  });
}