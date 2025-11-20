import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

/// Custom SectionHeader widget for MVP Builder
class SectionHeader extends StatelessWidget {
  final String text;

  const SectionHeader({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  /// Builder function for GenUI
  static Widget builder(CatalogItemContext itemContext) {
    final data = itemContext.data as Map<String, dynamic>;
    return SectionHeader(
      text: data['text'] as String? ?? '',
    );
  }
}

