/// Broad categories of files the preview service knows how to render.
enum PreviewFileType {
  image,
  video,
  audio,
  pdf,
  text,
  code,
  spreadsheet,
  presentation,
  archive,
  unknown,
}

/// Maps file extensions to a [PreviewFileType].
///
/// This is intentionally extension-based (fast, offline, no I/O) rather than
/// magic-byte sniffing. If you need higher confidence (e.g. a renamed file),
/// pair this with `package:mime`'s `lookupMimeType` and cross-check.
class PreviewFileTypeResolver {
  PreviewFileTypeResolver._();

  static const _imageExt = {
    'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'heif', 'svg'
  };
  static const _videoExt = {
    'mp4', 'mov', 'avi', 'mkv', 'webm', 'm4v', '3gp'
  };
  static const _audioExt = {
    'mp3', 'wav', 'aac', 'm4a', 'flac', 'ogg', 'wma'
  };
  static const _pdfExt = {'pdf'};
  static const _codeExt = {
    'dart', 'js', 'ts', 'py', 'java', 'kt', 'swift', 'c', 'cpp', 'h', 'cs',
    'go', 'rs', 'rb', 'php', 'sh', 'yaml', 'yml', 'json', 'xml', 'html',
    'css', 'sql'
  };
  static const _textExt = {'txt', 'md', 'log', 'csv', 'rtf'};
  static const _spreadsheetExt = {'xls', 'xlsx', 'ods'};
  static const _presentationExt = {'ppt', 'pptx', 'odp'};
  static const _archiveExt = {'zip', 'rar', '7z', 'tar', 'gz', 'bz2'};

  static String extensionOf(String pathOrName) {
    final name = pathOrName.split('/').last;
    final dot = name.lastIndexOf('.');
    if (dot == -1 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  static PreviewFileType resolve(String pathOrName) {
    final ext = extensionOf(pathOrName);
    if (_imageExt.contains(ext)) return PreviewFileType.image;
    if (_videoExt.contains(ext)) return PreviewFileType.video;
    if (_audioExt.contains(ext)) return PreviewFileType.audio;
    if (_pdfExt.contains(ext)) return PreviewFileType.pdf;
    if (_codeExt.contains(ext)) return PreviewFileType.code;
    if (_textExt.contains(ext)) return PreviewFileType.text;
    if (_spreadsheetExt.contains(ext)) return PreviewFileType.spreadsheet;
    if (_presentationExt.contains(ext)) return PreviewFileType.presentation;
    if (_archiveExt.contains(ext)) return PreviewFileType.archive;
    return PreviewFileType.unknown;
  }
}