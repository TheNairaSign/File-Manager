import 'package:flutter/material.dart';

/// A horizontally-paged section that lays items out in a 2-column grid
/// (2 rows × 2 cols = 4 items per page) with page indicator dots below.
///
/// Generic so it can be used for both scapes and digitizers.
class PagedTwoColumnSection<T> extends StatefulWidget {
  const PagedTwoColumnSection({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.itemHeight = 88,
    this.horizontalPadding = 16.0,
    this.crossAxisSpacing = 12.0,
    this.mainAxisSpacing = 12.0,
    this.rowsPerPage = 2,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Fixed height for each item card.
  final double itemHeight;

  final double horizontalPadding;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  /// How many rows to show per page (default 2 → 4 items per page).
  final int rowsPerPage;

  @override
  State<PagedTwoColumnSection<T>> createState() =>
      _PagedTwoColumnSectionState<T>();
}

class _PagedTwoColumnSectionState<T>
    extends State<PagedTwoColumnSection<T>> {
  late final PageController _pageController;
  int _currentPage = 0;

  int get _itemsPerPage => widget.rowsPerPage * 2; // 2 columns

  int get _pageCount => (widget.items.length / _itemsPerPage).ceil();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    // Total height = rows * itemHeight + (rows-1) * mainAxisSpacing
    final gridHeight = widget.rowsPerPage * widget.itemHeight +
        (widget.rowsPerPage - 1) * widget.mainAxisSpacing;

    return Column(
      children: [
        SizedBox(
          height: gridHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _pageCount,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemBuilder: (context, pageIndex) {
              final start = pageIndex * _itemsPerPage;
              final end = (start + _itemsPerPage).clamp(0, widget.items.length);
              final pageItems = widget.items.sublist(start, end);

              return Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: widget.horizontalPadding),
                child: _buildGrid(context, pageItems),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _PageDots(
          count: _pageCount,
          current: _currentPage,
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, List<T> pageItems) {
    // Build rows of 2
    final rows = <Widget>[];
    for (var row = 0; row < widget.rowsPerPage; row++) {
      final left = row * 2;
      final right = left + 1;

      rows.add(
        Row(
          children: [
            if (left < pageItems.length)
              Expanded(
                child: SizedBox(
                  height: widget.itemHeight,
                  child: widget.itemBuilder(context, pageItems[left]),
                ),
              )
            else
              const Expanded(child: SizedBox.shrink()),
            SizedBox(width: widget.crossAxisSpacing),
            if (right < pageItems.length)
              Expanded(
                child: SizedBox(
                  height: widget.itemHeight,
                  child: widget.itemBuilder(context, pageItems[right]),
                ),
              )
            else
              const Expanded(child: SizedBox.shrink()),
          ],
        ),
      );

      if (row < widget.rowsPerPage - 1) {
        rows.add(SizedBox(height: widget.mainAxisSpacing));
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: rows,
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 10 : 8,
          height: isActive ? 10 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? Colors.blue
                : Colors.grey[300],
          ),
        );
      }),
    );
  }
}
