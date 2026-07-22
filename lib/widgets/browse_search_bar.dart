import 'package:file_manager/features/browser/presentation/providers/browser_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BrowseSearchBar extends ConsumerWidget {
  const BrowseSearchBar({
    super.key,
    required this.onSubmitted,
    required this.controller,
    this.hintText,
    required this.path,
  });
  final String? hintText;
  final TextEditingController controller;
  final Function(String) onSubmitted;
  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(browserProviderFor(path).notifier);
    return  Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: controller,
        onSubmitted: (query) {
          notifier.search(query);
        },
        decoration: const InputDecoration(
          hintText: 'Search',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}