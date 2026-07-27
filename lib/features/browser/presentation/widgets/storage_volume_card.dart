import 'package:file_manager/core/helpers/byte_converter.dart';
import 'package:file_manager/models/storage_volume.dart';
import 'package:flutter/material.dart';

class StorageVolumeCard extends StatelessWidget {
  final StorageVolume volume;
  final bool isSelected;
  final VoidCallback onTap;

  const StorageVolumeCard({
    super.key,
    required this.volume,
    required this.isSelected,
    required this.onTap,
  });

  String _getVolumeTitle() {
    if (volume.isPrimary) {
      return 'Internal Storage';
    }
    if (volume.description.isNotEmpty && volume.description != 'Storage') {
      return volume.description;
    }
    return 'External Storage';
  }

  IconData _getVolumeIcon() {
    if (volume.isPrimary) {
      return Icons.smartphone_rounded;
    }
    if (volume.isRemovable) {
      return Icons.sd_card_rounded;
    }
    return Icons.storage_rounded;
  }

  Color _getProgressColor(double ratio, BuildContext context) {
    if (ratio >= 0.90) return Colors.redAccent;
    if (ratio >= 0.75) return Colors.orangeAccent;
    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = volume.usageRatio.clamp(0.0, 1.0);
    final percentText = (ratio * 100).toInt();

    final cardBg = isSelected
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.25)
        : theme.colorScheme.surface;

    final borderColor = isSelected
        ? theme.colorScheme.primary
        : theme.dividerColor.withValues(alpha: 0.15);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 220,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Icon + Title + Selected Indicator
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getVolumeIcon(),
                        size: 22,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _getVolumeTitle(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Middle: Capacity Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      volume.totalBytes > 0
                          ? '${formatBytes(volume.usedBytes)} / ${formatBytes(volume.totalBytes)}'
                          : 'Storage',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                      ),
                    ),
                    if (volume.totalBytes > 0)
                      Text(
                        '$percentText%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _getProgressColor(ratio, context),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),

                // Bottom: Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: theme.dividerColor.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(ratio, context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
