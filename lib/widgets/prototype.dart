import 'package:flutter/material.dart';
import '../mock/demo_state.dart';
import 'common.dart';

typedef UiCopy = (String japanese, String english, String easy);

extension LocalizedCopy on UiCopy {
  String forDemo(DemoState state) => state.tr($1, $2, $3);
}

class PrototypePage extends StatelessWidget {
  final String title;
  final String? description;
  final List<Widget> children;
  final Widget? footer;
  final ScrollController? controller;

  const PrototypePage({
    super.key,
    required this.title,
    this.description,
    required this.children,
    this.footer,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return DetailPage(
      title: title,
      child: TaskBody(
        footer: footer,
        controller: controller,
        children: [
          if (description != null) ...[
            Text(description!, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
          ],
          ...children,
        ],
      ),
    );
  }
}

class FeatureLink extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onTap;

  const FeatureLink({
    super.key,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => SurfaceCard(
    onTap: onTap,
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(
                description,
                style: TextStyle(fontSize: 14, color: secondaryText(context)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const ExcludeSemantics(
          child: Icon(Icons.chevron_right_rounded, size: 22),
        ),
      ],
    ),
  );
}
