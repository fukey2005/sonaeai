import 'package:flutter/material.dart';
import '../mock/demo_state.dart';
import '../theme/app_theme.dart';

Future<T?> openPage<T>(BuildContext context, Widget page) {
  ScaffoldMessenger.maybeOf(context)?.removeCurrentSnackBar();
  return Navigator.of(
    context,
  ).push<T>(MaterialPageRoute<T>(builder: (_) => page));
}

Color secondaryText(BuildContext context) =>
    DemoScope.of(context).highContrast ? ink : muted;
void showNotice(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFE8F3EB),
        content: Text(text, style: const TextStyle(color: green)),
        duration: const Duration(seconds: 4),
      ),
    );
}

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool dark, outlined, danger;
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.dark = true,
    this.outlined = false,
    this.danger = false,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: outlined
            ? Colors.white
            : danger
            ? red
            : dark
            ? ink
            : yellow,
        foregroundColor: outlined
            ? (danger ? red : ink)
            : dark || danger
            ? Colors.white
            : ink,
        disabledBackgroundColor: const Color(0xFFE7E7E7),
        disabledForegroundColor: const Color(0xFF5A5A5A),
        minimumSize: const Size(48, 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: outlined
              ? BorderSide(color: danger ? red : ink, width: 1.3)
              : BorderSide.none,
        ),
      ),
      child: Text(label, textAlign: TextAlign.center),
    ),
  );
}

class SurfaceCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final EdgeInsets padding;
  const SurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(16),
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline,
          width: DemoScope.of(context).highContrast ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

class AppBadge extends StatelessWidget {
  final String label;
  final Color color, background;
  const AppBadge(
    this.label, {
    super.key,
    this.color = ink,
    this.background = const Color(0xFFF2F2F2),
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 14,
        color: color,
        fontWeight: FontWeight.w600,
        height: 1.5,
      ),
    ),
  );
}

class LocalRecordNote extends StatelessWidget {
  const LocalRecordNote({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Text(
      DemoScope.of(context).tr(
        'この記録は端末内に保存されます。',
        'This record stays on your device.',
        'この きろくは たんまつに のこります。',
      ),
      style: TextStyle(
        fontSize: 14,
        height: 1.7,
        color: secondaryText(context),
      ),
    ),
  );
}

class PageHeader extends StatelessWidget {
  final String title;
  const PageHeader({super.key, required this.title});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
  );
}

enum StatusTone { complete, pending, neutral }

/// Persistent feedback at the point where the action took place.
class ActionStatus extends StatelessWidget {
  final String label;
  final StatusTone tone;
  final Widget? action;
  const ActionStatus(
    this.label, {
    super.key,
    this.tone = StatusTone.complete,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      StatusTone.complete => (const Color(0xFFE8F3EB), green),
      StatusTone.pending => (const Color(0xFFFFF3A6), ink),
      StatusTone.neutral => (const Color(0xFFF0F0F0), ink),
    };
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: action == null ? 10 : 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: DemoScope.of(context).highContrast
            ? Border.all(color: foreground)
            : null,
      ),
      child: Wrap(
        spacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Semantics(
            liveRegion: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tone == StatusTone.complete) ...[
                  CustomPaint(
                    size: const Size.square(18),
                    painter: _StatusCheck(foreground),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

class _StatusCheck extends CustomPainter {
  final Color color;
  const _StatusCheck(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final mark = Path()
      ..moveTo(size.width * .18, size.height * .50)
      ..lineTo(size.width * .42, size.height * .74)
      ..lineTo(size.width * .84, size.height * .27);
    canvas.drawPath(
      mark,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_StatusCheck oldDelegate) => color != oldDelegate.color;
}

class ActionPanel extends StatelessWidget {
  final Widget primary;
  final Widget? secondary;
  final Widget? status;
  final String? hint;
  final bool safeBottom;
  const ActionPanel({
    super.key,
    required this.primary,
    this.secondary,
    this.status,
    this.hint,
    this.safeBottom = true,
  });
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border(
        top: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
    ),
    child: SafeArea(
      top: false,
      bottom: safeBottom,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status != null) ...[status!, const SizedBox(height: 8)],
            if (hint != null) ...[
              Text(
                hint!,
                style: TextStyle(fontSize: 14, color: secondaryText(context)),
              ),
              const SizedBox(height: 8),
            ],
            primary,
            if (secondary != null) ...[const SizedBox(height: 8), secondary!],
          ],
        ),
      ),
    ),
  );
}

class TaskBody extends StatelessWidget {
  final List<Widget> children;
  final Widget? controls, footer;
  final ScrollController? controller;
  const TaskBody({
    super.key,
    required this.children,
    this.controls,
    this.footer,
    this.controller,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final reflowControls =
          MediaQuery.textScalerOf(context).scale(1) >= 1.4 ||
          box.maxHeight < 480;
      final scrollFooter = box.maxHeight < 340;
      Widget controlPanel() => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        child: controls,
      );
      return Column(
        children: [
          if (controls != null && !reflowControls) controlPanel(),
          Expanded(
            child: SingleChildScrollView(
              controller: controller,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (controls != null && reflowControls) controlPanel(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children,
                    ),
                  ),
                  if (footer != null && scrollFooter) footer!,
                ],
              ),
            ),
          ),
          if (footer != null && !scrollFooter) footer!,
        ],
      );
    },
  );
}

class FilterTabs extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  const FilterTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: List.generate(
      labels.length,
      (i) => ChoiceChip(
        label: Text(labels[i]),
        selected: selected == i,
        onSelected: (_) => onChanged(i),
        showCheckmark: true,
        backgroundColor: Colors.white,
        selectedColor: paleYellow,
        side: BorderSide(
          color: selected == i ? ink : Theme.of(context).colorScheme.outline,
          width: selected == i ? 1.5 : 1,
        ),
        labelStyle: TextStyle(
          color: ink,
          fontSize: 15,
          fontWeight: selected == i ? FontWeight.w700 : FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}

class ChoiceTile extends StatelessWidget {
  final String label;
  final String? description;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  const ChoiceTile({
    super.key,
    required this.label,
    this.description,
    required this.selected,
    required this.onTap,
    this.color = ink,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    checked: selected,
    inMutuallyExclusiveGroup: true,
    child: Material(
      color: selected ? paleYellow : paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? ink : Theme.of(context).colorScheme.outline,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Container(
                  width: 23,
                  height: 23,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? ink : muted,
                      width: 1.5,
                    ),
                  ),
                  child: selected
                      ? const DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ink,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        description!,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: secondaryText(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class DetailPage extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? footer;
  final VoidCallback? onBack;
  final String? backLabel;
  final Color background;
  const DetailPage({
    super.key,
    required this.title,
    required this.child,
    this.footer,
    this.onBack,
    this.backLabel,
    this.background = paper,
  });
  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    onPopInvokedWithResult: (didPop, _) {
      if (didPop && context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.removeCurrentSnackBar();
      }
    },
    child: Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        toolbarHeight:
            52 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 2),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          maxLines: 2,
        ),
        leading: IconButton(
          tooltip: backLabel ?? DemoScope.of(context).tr('戻る', 'Back'),
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: onBack ?? () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(top: false, bottom: footer == null, child: child),
      bottomNavigationBar: footer == null
          ? null
          : Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: footer,
            ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  final String title, message;
  final Widget? action;
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.action,
  });
  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: secondaryText(context),
              height: 1.8,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    ),
  );
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool danger = false,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  var handled = false;
  final s = DemoScope.of(context);
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setLocalState) => AlertDialog(
            scrollable: true,
            title: Text(title),
            content: Text(
              message,
              style: const TextStyle(fontSize: 16, height: 1.8),
            ),
            actions: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(
                    label: confirmLabel,
                    danger: danger,
                    onPressed: handled
                        ? null
                        : () {
                            if (handled) return;
                            setLocalState(() => handled = true);
                            Navigator.pop(dialogContext, true);
                          },
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    label: s.tr('やめる', 'Cancel', 'やめる'),
                    outlined: true,
                    onPressed: handled
                        ? null
                        : () {
                            handled = true;
                            Navigator.pop(dialogContext, false);
                          },
                  ),
                ],
              ),
            ],
          ),
        ),
      ) ??
      false;
}
