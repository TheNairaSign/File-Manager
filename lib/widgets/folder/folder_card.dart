import 'package:flutter/material.dart';

/// Visual state of the [FolderCard].
enum FolderCardState {
  /// Shows the stacked white file/paper illustration in the header.
  filled,

  /// Header shows only the gradient background — no files illustration.
  empty,
}

class FolderCard extends StatelessWidget {
  const FolderCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.fileCount,
    required this.gradientColors,
    this.state = FolderCardState.filled,
    this.width = 260,
    this.height = 340,
    this.onTap,
    this.onMorePressed,
  });

  final String title;
  final String subtitle;
  final int fileCount;

  /// Colors used for the header's gradient background.
  final List<Color> gradientColors;

  final FolderCardState state;
  final double width;
  final double height;
  final VoidCallback? onTap;
  final VoidCallback? onMorePressed;

  String get _formattedCount {
    // Formats e.g. 2386 -> "2 386" to match the design.
    final s = fileCount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final posFromEnd = s.length - i;
      buffer.write(s[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buffer.write(' ');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    const cardRadius = 28.0;
    const darkColor = Color(0xFF1C1C1E);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cardRadius),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black.withValues(alpha: 0.25),
          //     blurRadius: 24,
          //     offset: const Offset(0, 12),
          //   ),
          // ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Gradient header
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: gradientColors,
                  ),
                ),
              ),
            ),

            // Stacked paper illustration — only in the filled state.
            if (state == FolderCardState.filled)
              Positioned(
                left: 24,
                right: 24,
                top: height * 0.14,
                height: height * 0.40,
                child: const _StackedFiles(),
              ),

            // Dark panel: a "folder tab" shape — flat baseline across most
            // of the width, with a small step UP on the left where the
            // title sits. Built as a union of two RRects so there's no
            // hand-rolled bezier math that can self-intersect.
            Positioned.fill(
              child: ClipPath(
                clipper: _FolderTabClipper(
                  tabWidth: width * 0.86,
                  mainTopFraction: 0.60,
                  tabRiseFraction: 0.12,
                  cornerRadius: cardRadius,
                  tabCornerRadius: 16,
                ),
                child: ColoredBox(color: darkColor),
              ),
            ),

            // Text content, positioned to start inside the raised tab area.
            Positioned(
              left: 20,
              right: 16,
              top: height * (0.60 - 0.12) + 18,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: onMorePressed,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.more_horiz,
                            color: Colors.white54,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.folder_copy_outlined,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$_formattedCount Files',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three overlapping / fanned-out white sheets, used only in the
/// [FolderCardState.filled] state.
class _StackedFiles extends StatelessWidget {
  const _StackedFiles();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        _sheet(rotation: 0.28, dx: 30, height: 0.82),
        _sheet(rotation: 0.12, dx: 12, height: 0.92),
        _sheet(rotation: -0.05, dx: -6, height: 1.0),
      ],
    );
  }

  Widget _sheet({
    required double rotation,
    required double dx,
    required double height,
  }) {
    return Transform.translate(
      offset: Offset(dx, 0),
      child: Transform.rotate(
        angle: rotation,
        child: FractionallySizedBox(
          heightFactor: height,
          child: Container(
            width: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(5, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    height: 3,
                    width: i.isEven ? 70 : 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

/// Clips the dark panel into a "folder tab" shape:
///
///  * a flat baseline running the full width, starting at
///    `size.height * mainTopFraction`, and
///  * a shorter, narrower rectangle on the left (width = [tabWidth]) that
///    rises above that baseline by `size.height * tabRiseFraction`, giving
///    the title room to breathe.
///
/// Built as the union of two independently-rounded [RRect]s rather than
/// hand-written bezier curves, so the geometry can't self-intersect no
/// matter what size the card ends up being.
class _FolderTabClipper extends CustomClipper<Path> {
  _FolderTabClipper({
    required this.tabWidth,
    required this.mainTopFraction,
    required this.tabRiseFraction,
    required this.cornerRadius,
    required this.tabCornerRadius,
  });

  /// Width of the raised tab, in logical pixels (not a fraction).
  final double tabWidth;

  /// Where the flat baseline sits, as a fraction of the card's height.
  final double mainTopFraction;

  /// How far above the baseline the tab rises, as a fraction of height.
  final double tabRiseFraction;

  /// Corner radius for the panel's bottom corners (should match the card's
  /// own outer radius so there's no visible seam against the outer clip).
  final double cornerRadius;

  /// Corner radius for the tab's own top corners.
  final double tabCornerRadius;

  @override
  Path getClip(Size size) {
    final mainTop = size.height * mainTopFraction;
    final tabTop = mainTop - size.height * tabRiseFraction;

    // Main body: flat baseline across the full width, rounded bottom
    // corners only (top corners are square — they're covered by the tab
    // on the left, and by the gradient header on the right).
    final mainRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, mainTop, size.width, size.height - mainTop),
      bottomLeft: Radius.circular(cornerRadius),
      bottomRight: Radius.circular(cornerRadius),
    );

    // Tab: narrower rect that rises above the baseline. Extend it a bit
    // past `mainTop` (rather than stopping exactly there) so the union
    // merges cleanly with no seam.
    final tabRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, tabTop, tabWidth, size.height - tabTop),
      topLeft: Radius.circular(tabCornerRadius),
      topRight: Radius.circular(tabCornerRadius),
    );

    return Path.combine(
      PathOperation.union,
      Path()..addRRect(mainRect),
      Path()..addRRect(tabRect),
    );
  }

  @override
  bool shouldReclip(covariant _FolderTabClipper oldClipper) {
    return oldClipper.tabWidth != tabWidth ||
        oldClipper.mainTopFraction != mainTopFraction ||
        oldClipper.tabRiseFraction != tabRiseFraction ||
        oldClipper.cornerRadius != cornerRadius ||
        oldClipper.tabCornerRadius != tabCornerRadius;
  }
}