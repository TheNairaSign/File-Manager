import 'package:flutter/material.dart';
import '../../../../../models/storage_info.dart';
import '../../../../../core/helpers/byte_converter.dart';

class StorageInfoContainer extends StatefulWidget {
  final StorageInfo storageInfo;

  const StorageInfoContainer({
    super.key,
    required this.storageInfo,
  });

  @override
  State<StorageInfoContainer> createState() => _StorageInfoContainerState();
}

class _StorageInfoContainerState extends State<StorageInfoContainer> {
  @override
  Widget build(BuildContext context) {
    final double usedPercentage = widget.storageInfo.total > 0
        ? (widget.storageInfo.used / widget.storageInfo.total)
        : 0.0;
        
    final int percentageText = (usedPercentage * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Circular Progress Indicator
          SizedBox(
            width: 85,
            height: 85,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: usedPercentage),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: value,
                        strokeWidth: 9,
                        backgroundColor: const Color(0xFFE2E6EE),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: percentageText.toDouble()),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (context, val, child) {
                        return Text(
                          "${val.round()}%",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D3142),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 24),
          // Storage Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Used Storage",
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF8C96A8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "${formatBytes(widget.storageInfo.used)} of ${formatBytes(widget.storageInfo.total)} used",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    // Action for Manage Storage
                  },
                  child: const Text(
                    "Manage Storage",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}