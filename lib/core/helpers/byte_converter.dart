import 'dart:math';

String formatBytes(int bytes, {int decimals = 1, bool showFullUnit = false}) {
  if (bytes <= 0) return "0 B";

  const suffixes = ["B", "KB", "MB", "GB", "TB"];
  const fullSuffixes = ["Bytes", "Kilobytes", "Megabytes", "Gigabytes", "Terabytes"];
  
  var i = (log(bytes) / log(1024)).floor();
  i = i.clamp(0, suffixes.length - 1);
  
  var value = bytes / pow(1024, i);

  String unit = showFullUnit 
      ? fullSuffixes[i] 
      : suffixes[i];

  return '${value.toStringAsFixed(decimals)} $unit';
}