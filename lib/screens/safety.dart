import 'package:flutter/material.dart';
import '../mock/demo_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/prototype.dart';
import 'help.dart';

const _colors = [green, red, blue];

class SafetyDrillScreen extends StatelessWidget {
  const SafetyDrillScreen({super.key});

  @override
  Widget build(BuildContext context) => DetailPage(
    title: DemoScope.of(
      context,
    ).tr('安否確認の訓練', 'Safety check drill', 'ぶじの かくにんの くんれん'),
    child: const SafetyScreen(drill: true),
  );
}

class SafetyScreen extends StatelessWidget {
  final bool drill;
  const SafetyScreen({super.key, this.drill = false});
  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context),
        d = DemoScope.of(context).safetyDraft(drill: drill);
    final report = s.safetyReport(drill: drill);
    final hasChanges = s.safetyChanged(drill: drill);
    return TaskBody(
      footer: ActionPanel(
        safeBottom: false,
        status: report == null
            ? null
            : ActionStatus(
                hasChanges
                    ? s.tr(
                        '変更は未確定です',
                        'Changes not reported',
                        'へんこうは まだ しらせていません',
                      )
                    : s.tr('報告済み', 'Reported', 'しらせました'),
                tone: hasChanges ? StatusTone.pending : StatusTone.complete,
                action: hasChanges
                    ? TextButton(
                        onPressed: () => s.restoreSafetyDraft(drill: drill),
                        child: Text(
                          s.tr('変更を取り消す', 'Discard changes', 'へんこうを とりけす'),
                        ),
                      )
                    : null,
              ),
        hint: d.status == null
            ? s.tr(
                'ご自身の状況を1つ選んでください。',
                'Choose your own situation to continue.',
                'じぶんの ようすを ひとつ えらんでください。',
              )
            : null,
        primary: AppButton(
          outlined: report != null && !hasChanges,
          label: report != null && !hasChanges
              ? s.tr('報告した内容を見る', 'View my report', 'しらせた ないようを みる')
              : s.tr('報告内容を確認する', 'Review my report', 'しらせる ないようを みる'),
          onPressed: d.status == null
              ? null
              : () => openPage(
                  context,
                  report != null && !hasChanges
                      ? SafetyResultScreen(drill: drill)
                      : SafetyConfirmScreen(drill: drill),
                ),
        ),
      ),
      children: [
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppBadge(
              drill
                  ? s.tr('訓練用の報告', 'Drill report', 'くんれんの れんしゅう')
                  : s.tr('非常時の訓練', 'Emergency practice', 'さいがい の れんしゅう'),
              background: const Color(0xFFFFF3A6),
            ),
            if (!drill)
              TextButton(
                onPressed: () => s.setEmergency(false),
                child: Text(
                  s.tr('通常時に戻す', 'Return to everyday mode', 'ふつうの ときに もどす'),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (!drill) ...[
          Wrap(children: const [QuickSafetyReport(), SafetyContactsLink()]),
          const SizedBox(height: 8),
        ],
        if (report != null) ...[
          SurfaceCard(
            onTap: () => openPage(context, SafetyResultScreen(drill: drill)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${s.tr('報告済み', 'Reported', 'しらせました')} ${timeLabel(report.time)}',
                  style: TextStyle(fontSize: 14, color: secondaryText(context)),
                ),
                const SizedBox(height: 6),
                Text(
                  safetyLabel(s, report.status),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _colors[report.status],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  s.tr('報告内容を見る', 'View report', 'ないようを みる'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        Text(
          s.tr('今の状況を選んでください', 'How are you right now?', 'いまの ようすを えらんでください'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 14),
        ...List.generate(
          3,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ChoiceTile(
              label: safetyLabel(s, i),
              selected: d.status == i,
              color: _colors[i],
              description: s.tr(
                [
                  'けががなく、安全な場所にいます。',
                  'けがや困りごとがあり、支援が必要です。',
                  'ご自身の安全をまだ確認できていません。',
                ][i],
                [
                  'I am uninjured and in a safe place.',
                  'I have an injury or need assistance.',
                  'I have not yet confirmed my own safety.',
                ][i],
                [
                  'けがは ありません。あんぜんです。',
                  'けがや こまったことが あります。',
                  'じぶんが あんぜんか、まだ わかりません。',
                ][i],
              ),
              onTap: () => s.update(() {
                d.status = i;
                if (i == 0) d.tags.remove(0);
              }),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ExpansionTile(
          key: ValueKey('safety-options-$drill'),
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 16),
          initiallyExpanded: d.place != null || d.tags.isNotEmpty,
          title: Text(
            s.tr(
              '場所・補足を追加（任意）',
              'Add location / details (optional)',
              'ばしょなどを くわえる（えらばなくても いいです）',
            ),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                s.tr('今いる場所', 'Current location', 'いま いる ばしょ'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  3,
                  (i) => ChoiceChip(
                    label: Text(placeLabel(s, i)),
                    selected: d.place == i,
                    onSelected: (selected) =>
                        s.update(() => d.place = selected ? i : null),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  2,
                  (i) => i == 0 && d.status != 1
                      ? const SizedBox.shrink()
                      : FilterChip(
                          label: Text(tagLabel(s, i)),
                          selected: d.tags.contains(i),
                          onSelected: (selected) => s.update(() {
                            selected ? d.tags.add(i) : d.tags.remove(i);
                          }),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class SafetySummary extends StatelessWidget {
  final int status;
  final int? place;
  final Set<int> tags;
  const SafetySummary({
    super.key,
    required this.status,
    this.place,
    required this.tags,
  });
  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            safetyLabel(s, status),
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: _colors[status],
            ),
          ),
          if (place != null || tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (place != null) AppBadge(placeLabel(s, place!)),
                ...tags.map((i) => AppBadge(tagLabel(s, i))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class QuickSafetyReport extends StatelessWidget {
  final bool prominent;
  const QuickSafetyReport({super.key, this.prominent = false});

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    if (!s.isEmergency || s.safetyReport() != null || s.safetyChanged()) {
      return const SizedBox.shrink();
    }
    void record() {
      if (s.safetyReport() != null || s.safetyChanged()) return;
      s.reportSafe();
      openPage(context, const SafetyResultScreen(justSaved: true));
    }

    final label = s.tr('無事と記録する', 'Record that I am safe', 'ぶじを きろくする');
    return prominent
        ? AppButton(label: label, onPressed: record)
        : TextButton(onPressed: record, child: Text(label));
  }
}

class SafetyContactsLink extends StatelessWidget {
  const SafetyContactsLink({super.key});

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    return TextButton.icon(
      onPressed: () => openPage(context, const SafetyContactsScreen()),
      icon: const Icon(Icons.people_outline),
      label: Text(
        s.tr('家族・知人の安否を見る', 'Check family and friends', 'かぞくや しりあいの ようすを みる'),
      ),
    );
  }
}

class SafetyContactsScreen extends StatelessWidget {
  const SafetyContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final contacts = [
      (
        s.tr('母', 'Mother', 'おかあさん'),
        0,
        s.tr('14:32に報告', 'Reported at 14:32', '14:32に しらせました'),
      ),
      (
        s.tr('知人・山田さん', 'Friend · Yamada', 'しりあいの やまださん'),
        1,
        s.tr('14:28に報告', 'Reported at 14:28', '14:28に しらせました'),
      ),
      (
        s.tr('近所・佐藤さん', 'Neighbor · Sato', 'きんじょの さとうさん'),
        null,
        s.tr('まだ報告がありません', 'No report received yet', 'まだ ほうこくが ありません'),
      ),
    ];
    return PrototypePage(
      title: s.tr('家族・知人の安否', 'Family and friends', 'かぞくや しりあいの ようす'),
      description: s.tr(
        '訓練用の安否一覧です。',
        'This list shows sample reports.',
        'れいの ほうこくを みる がめんです。',
      ),
      children: [
        for (final (name, status, updated) in contacts) ...[
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                AppBadge(
                  status == null
                      ? s.tr('未報告', 'Not reported', 'まだ しらせていません')
                      : safetyLabel(s, status),
                  color: status == null ? ink : _colors[status],
                  background: switch (status) {
                    0 => const Color(0xFFE8F3EB),
                    1 => const Color(0xFFFFEAE5),
                    _ => wash,
                  },
                ),
                const SizedBox(height: 6),
                Text(updated),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        AppButton(
          outlined: true,
          label: s.tr('助け合いを見る', 'Browse help posts', 'たすけあいを みる'),
          onPressed: () => openPage(
            context,
            DetailPage(
              title: s.tr('助け合い', 'Mutual help', 'たすけあい'),
              child: const HelpListScreen(),
            ),
          ),
        ),
      ],
    );
  }
}

class SafetyConfirmScreen extends StatefulWidget {
  final bool drill;
  const SafetyConfirmScreen({super.key, this.drill = false});
  @override
  State<SafetyConfirmScreen> createState() => _SafetyConfirmScreenState();
}

class _SafetyConfirmScreenState extends State<SafetyConfirmScreen> {
  bool submitting = false;
  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context), drill = widget.drill;
    final d = s.safetyDraft(drill: drill);
    return DetailPage(
      title: s.tr('報告内容の確認', 'Review my report'),
      footer: ActionPanel(
        primary: AppButton(
          label: s.tr('この内容で記録する', 'Save this report', 'この ないようを きろくする'),
          onPressed: d.status == null || submitting
              ? null
              : () {
                  if (submitting) return;
                  setState(() => submitting = true);
                  s.saveSafety(drill: drill);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          SafetyResultScreen(justSaved: true, drill: drill),
                    ),
                  );
                },
        ),
        secondary: AppButton(
          label: s.tr('内容を変更する', 'Edit details', 'ないようを かえる'),
          outlined: true,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (drill) ...[
              AppBadge(s.tr('訓練用の報告', 'Drill report')),
              const SizedBox(height: 16),
            ],
            if (d.status != null)
              SafetySummary(status: d.status!, place: d.place, tags: d.tags),
            const LocalRecordNote(),
          ],
        ),
      ),
    );
  }
}

class SafetyResultScreen extends StatelessWidget {
  final bool justSaved;
  final bool drill;
  const SafetyResultScreen({
    super.key,
    this.justSaved = false,
    this.drill = false,
  });
  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context),
        report = DemoScope.of(context).safetyReport(drill: drill);
    final needsHelp = !drill && s.isEmergency && report?.status == 1;
    return DetailPage(
      title: justSaved
          ? s.tr('安否を記録しました', 'Safety status recorded', 'ぶじか どうかを きろくしました')
          : s.tr('報告した内容', 'My report', 'しらせた ないよう'),
      footer: ActionPanel(
        primary: AppButton(
          label: needsHelp
              ? s.tr(
                  '手伝える人の投稿を見る',
                  'Browse offers of help',
                  'てつだえる ひとの とうこうを みる',
                )
              : s.tr('内容を変更する', 'Update my report', 'ないようを かえる'),
          onPressed: () {
            if (needsHelp) {
              s.update(() {
                s.helpFilter = 2;
                s.helpCategoryFilter = null;
                s.tab = DemoState.helpTab;
              });
            } else if (!drill) {
              s.selectTab(DemoState.safetyTab);
            }
            Navigator.pop(context);
          },
        ),
        secondary: AppButton(
          label: drill
              ? s.tr('訓練を終える', 'Finish drill', 'くんれんを おえる')
              : s.tr('ホームに戻る', 'Back to home'),
          outlined: true,
          onPressed: () {
            final navigator = Navigator.of(context);
            if (drill) {
              // Return past the practice form to the page that launched it.
              navigator
                ..pop()
                ..pop();
            } else {
              s.selectTab(0);
              navigator.pop();
            }
          },
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (report != null) ...[
              Text(
                '${s.tr('訓練の記録', 'Practice record', 'くんれんの きろく')}  ·  ${MaterialLocalizations.of(context).formatShortDate(report.time)} ${timeLabel(report.time)}',
                style: TextStyle(fontSize: 14, color: secondaryText(context)),
              ),
              const SizedBox(height: 16),
              SafetySummary(
                status: report.status,
                place: report.place,
                tags: report.tags,
              ),
              if (!drill) ...[
                const SizedBox(height: 12),
                const SafetyContactsLink(),
              ],
            ],
            const LocalRecordNote(),
            if (needsHelp) ...[
              const SizedBox(height: 16),
              Text(
                s.tr(
                  '助け合いで、協力できる人の投稿を確認できます。ご自身の依頼を作成することもできます。',
                  'Browse nearby offers of help, or create a request of your own.',
                  'たすけあいで、てつだえる ひとの とうこうを みられます。じぶんの おねがいも かけます。',
                ),
                style: const TextStyle(fontSize: 16, height: 1.8),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: s.tr('内容を変更する', 'Update my report', 'ないようを かえる'),
                outlined: true,
                onPressed: () {
                  s.selectTab(DemoState.safetyTab);
                  Navigator.pop(context);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
