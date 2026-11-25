import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../mock/demo_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/prototype.dart';

typedef _SupplyChange = ({DemoSupply? item});

class SuppliesScreen extends StatefulWidget {
  const SuppliesScreen({super.key});

  @override
  State<SuppliesScreen> createState() => _SuppliesScreenState();
}

class _SuppliesScreenState extends State<SuppliesScreen> {
  bool expiringOnly = false;

  Future<void> edit({int? index, DemoSupply? example}) async {
    final s = DemoScope.of(context);
    final result = await openPage<_SupplyChange>(
      context,
      _SupplyForm(
        initial: index == null ? example : s.supplies[index],
        editing: index != null,
      ),
    );
    if (result == null || !mounted) return;
    final item = result.item;
    s.update(() {
      if (item == null && index != null) {
        s.supplies.removeAt(index);
      } else if (index == null && item != null) {
        s.supplies.add(item);
        expiringOnly = false;
      } else if (index != null && item != null) {
        s.supplies[index] = item;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final items = s.supplies;
    final today = DateUtils.dateOnly(DateTime.now());
    final cutoff = DateUtils.addDaysToDate(today, 7);
    final noExpiry = DateTime(2200);
    final samples = <DemoSupply>[
      (
        name: s.tr('飲料水 2L', 'Drinking water 2 L', 'のみみず 2L'),
        quantity: 6,
        expiry: DateUtils.addDaysToDate(today, 4),
      ),
      (
        name: s.tr('レトルトごはん', 'Shelf-stable rice', 'レトルト ごはん'),
        quantity: 8,
        expiry: DateUtils.addDaysToDate(today, -2),
      ),
      (
        name: s.tr('携帯トイレ', 'Emergency toilet bags', 'けいたい トイレ'),
        quantity: 20,
        expiry: null,
      ),
    ];
    final visible = List.generate(items.length, (index) => index)
      ..removeWhere(
        (i) => expiringOnly && (items[i].expiry ?? noExpiry).isAfter(cutoff),
      )
      ..sort(
        (a, b) => (items[a].expiry ?? noExpiry).compareTo(
          items[b].expiry ?? noExpiry,
        ),
      );
    return PrototypePage(
      title: s.tr('備蓄品管理', 'Supplies', 'そなえの もちもの'),
      footer: ActionPanel(
        primary: AppButton(
          label: s.tr('備蓄品を追加', 'Add supplies', 'もちものを たす'),
          onPressed: () => edit(),
        ),
      ),
      children: [
        FilterTabs(
          labels: [
            s.tr('すべて', 'All'),
            s.tr('期限が近い・期限切れ', 'Expiring or expired', 'きげんが ちかい・すぎた'),
          ],
          selected: expiringOnly ? 1 : 0,
          onChanged: (i) => setState(() => expiringOnly = i == 1),
        ),
        const SizedBox(height: 16),
        if (items.isNotEmpty && visible.isEmpty)
          Text(
            s.tr(
              '期限が近い備蓄品はありません。',
              'No expiring supplies.',
              'きげんが ちかい ものは ありません。',
            ),
          ),
        for (final index in visible) ...[
          _SupplyCard(
            item: items[index],
            today: today,
            onTap: () => edit(index: index),
          ),
          const SizedBox(height: 10),
        ],
        if (items.isEmpty) ...[
          PageHeader(title: s.tr('備蓄品の登録例', 'Example supplies', 'そなえの れい')),
          Text(
            s.tr(
              '品目を選ぶと、自分の備蓄として登録できます。',
              'Choose an example to add it to your supplies.',
              'えらんだ ものを じぶんの そなえに とうろくできます。',
            ),
          ),
          const SizedBox(height: 12),
          for (final sample in samples.where(
            (item) =>
                !expiringOnly || !(item.expiry ?? noExpiry).isAfter(cutoff),
          )) ...[
            _SupplyCard(
              item: sample,
              today: today,
              onTap: () => edit(example: sample),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

class _SupplyCard extends StatelessWidget {
  final DemoSupply item;
  final DateTime today;
  final VoidCallback onTap;
  const _SupplyCard({
    required this.item,
    required this.today,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final expiry = item.expiry;
    final expired = expiry != null && expiry.isBefore(today);
    final near =
        expiry != null &&
        !expired &&
        !expiry.isAfter(DateUtils.addDaysToDate(today, 7));
    return SurfaceCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(item.name, style: Theme.of(context).textTheme.titleMedium),
              if (expired || near)
                AppBadge(
                  expired
                      ? s.tr('期限切れ', 'Expired', 'きげんが すぎた')
                      : s.tr('期限が近い', 'Expiring soon', 'きげんが ちかい'),
                  color: expired ? red : ink,
                  background: expired
                      ? const Color(0xFFFFEAE5)
                      : const Color(0xFFFFF3A6),
                ),
            ],
          ),
          Text(
            s.tr(
              '数量 ${item.quantity}',
              'Quantity ${item.quantity}',
              '${item.quantity}こ',
            ),
          ),
          if (expiry != null)
            Text(
              s.tr(
                '期限 ${MaterialLocalizations.of(context).formatCompactDate(expiry)}',
                'Expires ${MaterialLocalizations.of(context).formatCompactDate(expiry)}',
                'きげん ${MaterialLocalizations.of(context).formatCompactDate(expiry)}',
              ),
            ),
        ],
      ),
    );
  }
}

class _SupplyForm extends StatefulWidget {
  final DemoSupply? initial;
  final bool editing;
  const _SupplyForm({this.initial, required this.editing});

  @override
  State<_SupplyForm> createState() => _SupplyFormState();
}

class _SupplyFormState extends State<_SupplyForm> {
  late final name = TextEditingController(text: widget.initial?.name);
  late final quantity = TextEditingController(
    text: (widget.initial?.quantity ?? 1).toString(),
  );
  late DateTime? expiry = widget.initial?.expiry;
  final form = GlobalKey<FormState>();
  bool submitted = false;

  @override
  void dispose() {
    name.dispose();
    quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final date = expiry;
    return PrototypePage(
      title: widget.editing
          ? s.tr('備蓄品を編集', 'Edit supplies', 'もちものを なおす')
          : s.tr('備蓄品を追加', 'Add supplies', 'もちものを たす'),
      children: [
        Form(
          key: form,
          child: Column(
            children: [
              TextFormField(
                controller: name,
                maxLength: 35,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: s.tr('品名', 'Item name', 'なまえ'),
                ),
                validator: (value) => value!.trim().isEmpty
                    ? s.tr(
                        '品名を入力してください。',
                        'Enter an item name.',
                        'なまえを いれて ください。',
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: quantity,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 2,
                decoration: InputDecoration(
                  labelText: s.tr('数量', 'Quantity', 'かず'),
                ),
                validator: (value) => (int.tryParse(value ?? '') ?? 0) < 1
                    ? s.tr(
                        '1以上の数量を入力してください。',
                        'Enter a quantity of at least 1.',
                        '1いじょうの かずを いれて ください。',
                      )
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        FeatureLink(
          title: s.tr('期限を設定', 'Set expiration date', 'きげんを きめる'),
          description: date == null
              ? s.tr('任意', 'Optional', 'いれなくても だいじょうぶ')
              : MaterialLocalizations.of(context).formatCompactDate(date),
          onTap: () async {
            FocusManager.instance.primaryFocus?.unfocus();
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateUtils.dateOnly(DateTime.now()),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (mounted && picked != null) setState(() => expiry = picked);
          },
        ),
        if (date != null)
          TextButton(
            onPressed: () => setState(() => expiry = null),
            child: Text(s.tr('期限を外す', 'Remove expiration date', 'きげんを けす')),
          ),
        const SizedBox(height: 18),
        AppButton(
          label: s.tr('保存する', 'Save', 'ほぞんする'),
          onPressed: () {
            if (submitted || !form.currentState!.validate()) return;
            submitted = true;
            Navigator.pop<_SupplyChange>(context, (
              item: (
                name: name.text.trim(),
                quantity: int.parse(quantity.text),
                expiry: date,
              ),
            ));
          },
        ),
        if (widget.editing)
          TextButton(
            onPressed: () async {
              final confirmed = await confirmAction(
                context,
                title: s.tr(
                  '備蓄品を削除しますか？',
                  'Remove this item?',
                  'この もちものを けしますか？',
                ),
                message: widget.initial!.name,
                confirmLabel: s.tr('削除する', 'Remove', 'けす'),
                danger: true,
              );
              if (context.mounted && confirmed) {
                Navigator.pop<_SupplyChange>(context, (item: null));
              }
            },
            child: Text(
              s.tr('この品目を削除', 'Remove this item', 'この もちものを けす'),
              style: const TextStyle(color: red),
            ),
          ),
      ],
    );
  }
}
