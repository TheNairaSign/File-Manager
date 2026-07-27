import 'package:file_manager/features/browser/presentation/pages/folder_page.dart';
import 'package:flutter/material.dart';

class BreadcrumbSegment {
  final String label;
  final String path;
  final bool isRoot;

  const BreadcrumbSegment({
    required this.label,
    required this.path,
    this.isRoot = false,
  });
}

class BreadcrumbsBar extends StatefulWidget {
  final String currentPath;
  final int maxVisibleItems;

  const BreadcrumbsBar({
    super.key,
    required this.currentPath,
    this.maxVisibleItems = 4,
  });

  @override
  State<BreadcrumbsBar> createState() => _BreadcrumbsBarState();
}

class _BreadcrumbsBarState extends State<BreadcrumbsBar> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollToEnd();
  }

  @override
  void didUpdateWidget(covariant BreadcrumbsBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPath != widget.currentPath) {
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<BreadcrumbSegment> _parseSegments(String rawPath) {
    if (rawPath.isEmpty) {
      return [
        const BreadcrumbSegment(label: 'Home', path: '', isRoot: true),
      ];
    }

    final segments = <BreadcrumbSegment>[];
    const internalStorageRoot = '/storage/emulated/0';

    if (rawPath == internalStorageRoot || rawPath.startsWith('$internalStorageRoot/')) {
      segments.add(const BreadcrumbSegment(
        label: 'Home',
        path: internalStorageRoot,
        isRoot: true,
      ));

      if (rawPath.length > internalStorageRoot.length) {
        final subPath = rawPath.substring(internalStorageRoot.length);
        final parts = subPath.split('/').where((p) => p.isNotEmpty).toList();

        String accumulated = internalStorageRoot;
        for (final part in parts) {
          accumulated += '/$part';
          segments.add(BreadcrumbSegment(
            label: part,
            path: accumulated,
          ));
        }
      }
    } else {
      final parts = rawPath.split('/').where((p) => p.isNotEmpty).toList();
      String accumulated = '';

      segments.add(const BreadcrumbSegment(
        label: 'Home',
        path: '/',
        isRoot: true,
      ));

      for (final part in parts) {
        accumulated += '/$part';
        segments.add(BreadcrumbSegment(
          label: part,
          path: accumulated,
        ));
      }
    }

    return segments;
  }

  void _navigateToSegment(BuildContext context, BreadcrumbSegment segment) {
    if (segment.path == widget.currentPath) return;

    bool foundInStack = false;
    Navigator.popUntil(context, (route) {
      if (route.settings.name == segment.path) {
        foundInStack = true;
        return true;
      }
      if (route.isFirst) {
        if (segment.isRoot) {
          foundInStack = true;
        }
        return true;
      }
      return false;
    });

    if (!foundInStack) {
      if (segment.isRoot) {
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FolderPage(path: segment.path),
            settings: RouteSettings(name: segment.path),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final segments = _parseSegments(widget.currentPath);

    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: _buildBreadcrumbList(context, segments),
        ),
      ),
    );
  }

  List<Widget> _buildBreadcrumbList(
    BuildContext context,
    List<BreadcrumbSegment> segments,
  ) {
    final widgets = <Widget>[];

    // Check if path exceeds max visible items and needs ellipsis truncation
    if (segments.length > widget.maxVisibleItems) {
      // First segment (Root / Home)
      widgets.add(_buildSegmentItem(context, segments.first, isLast: false));
      widgets.add(_buildSeparator());

      // Dropdown menu for hidden intermediate segments
      final hiddenSegments = segments.sublist(1, segments.length - 2);
      widgets.add(_buildEllipsisDropdown(context, hiddenSegments));
      widgets.add(_buildSeparator());

      // Last 2 segments
      final tailSegments = segments.sublist(segments.length - 2);
      for (int i = 0; i < tailSegments.length; i++) {
        if (i > 0) widgets.add(_buildSeparator());
        final isLast = i == tailSegments.length - 1;
        widgets.add(_buildSegmentItem(context, tailSegments[i], isLast: isLast));
      }
    } else {
      // Render all segments without truncation
      for (int i = 0; i < segments.length; i++) {
        if (i > 0) widgets.add(_buildSeparator());
        final isLast = i == segments.length - 1;
        widgets.add(_buildSegmentItem(context, segments[i], isLast: isLast));
      }
    }

    return widgets;
  }

  Widget _buildSeparator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: Color(0xFF94A3B8),
      ),
    );
  }

  Widget _buildSegmentItem(
    BuildContext context,
    BreadcrumbSegment segment, {
    required bool isLast,
  }) {
    final theme = Theme.of(context);

    final mutedColor = theme.brightness == Brightness.dark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    final activeColor = theme.brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF0F172A);

    final color = isLast ? activeColor : mutedColor;

    return InkWell(
      onTap: () => _navigateToSegment(context, segment),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (segment.isRoot) ...[
              Icon(
                Icons.home_outlined,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              segment.label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEllipsisDropdown(
    BuildContext context,
    List<BreadcrumbSegment> hiddenSegments,
  ) {
    final theme = Theme.of(context);
    final mutedColor = theme.brightness == Brightness.dark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return PopupMenuButton<BreadcrumbSegment>(
      onSelected: (segment) => _navigateToSegment(context, segment),
      tooltip: 'Show hidden folders',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => hiddenSegments.map((segment) {
        return PopupMenuItem<BreadcrumbSegment>(
          value: segment,
          child: Row(
            children: [
              const Icon(Icons.folder_outlined, size: 18, color: Color(0xFF64748B)),
              const SizedBox(width: 10),
              Text(
                segment.label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      }).toList(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          '•••',
          style: TextStyle(
            color: mutedColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
