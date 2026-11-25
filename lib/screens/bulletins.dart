import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../mock/demo_state.dart';
import '../mock/easy_japanese.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'safety.dart';

List<Bulletin> orderedBulletins(Iterable<Bulletin> source) =>
    source.toList()..sort((a, b) {
      final priority = (b.category == 1 ? 1 : 0) - (a.category == 1 ? 1 : 0);
      return priority != 0 ? priority : b.date.compareTo(a.date);
    });

List<Bulletin> visibleBulletins(DemoState s, {bool onlyUnread = false}) =>
    orderedBulletins(
      bulletins.where(
        (b) =>
            (s.bulletinFilter == 0 || b.category == s.bulletinFilter) &&
            (!(s.unreadOnly || onlyUnread) || !s.readBulletins.contains(b.id)),
      ),
    );

class BulletinListScreen extends StatelessWidget {
  const BulletinListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context),
        items = visibleBulletins(DemoScope.of(context));
    return ColoredBox(
      color: paper,
      child: TaskBody(
        controls: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FilterTabs(
              labels: [
                s.tr('すべて', 'All'),
                s.tr('重要', 'Important'),
                s.tr('防災訓練', 'Drills'),
              ],
              selected: s.bulletinFilter,
              onChanged: (v) => s.update(() => s.bulletinFilter = v),
            ),
            const SizedBox(height: 8),
            FilterChip(
              label: Text(s.tr('未確認のみ', 'Unread only', 'まだ よんでいないもの')),
              selected: s.unreadOnly,
              onSelected: (v) => s.update(() => s.unreadOnly = v),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            ),
          ],
        ),
        children: [
          Text(
            s.tr(
              '${items.length}件 · 重要・新着順',
              '${items.length} updates · Important first',
              '${items.length}けん · だいじなものから',
            ),
            style: TextStyle(fontSize: 14, color: secondaryText(context)),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            EmptyState(
              title: s.tr(
                '未確認のお知らせはありません',
                'No unread updates',
                'まだ よんでいない おしらせは ありません',
              ),
              message: s.tr(
                '確認済みのお知らせも、いつでも読み返せます。',
                'You can still read updates you have already checked.',
                'よんだ おしらせも、もういちど よめます。',
              ),
              action: AppButton(
                label: s.tr('すべてのお知らせを見る', 'Show all updates', 'ぜんぶの おしらせを みる'),
                outlined: true,
                onPressed: () => s.update(() {
                  s.unreadOnly = false;
                  s.bulletinFilter = 0;
                }),
              ),
            ),
          ...items.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: BulletinCard(bulletin: b),
            ),
          ),
        ],
      ),
    );
  }
}

class BulletinCard extends StatelessWidget {
  final Bulletin bulletin;
  final bool compact;
  const BulletinCard({super.key, required this.bulletin, this.compact = false});
  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context), b = bulletin;
    final read = s.readBulletins.contains(b.id);
    return SurfaceCard(
      color: read ? wash : paper,
      onTap: () => openPage(context, BulletinDetailScreen(bulletin: b)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!compact || !read)
                AppBadge(
                  s.tr(
                    ['お知らせ', '重要', '防災訓練'][b.category],
                    ['News', 'Important', 'Drill'][b.category],
                  ),
                  color: b.category == 1 ? paper : ink,
                  background: b.category == 1 ? ink : wash,
                ),
              if (!compact || read)
                AppBadge(
                  read
                      ? s.tr('確認済み', 'Read', 'よみました')
                      : s.tr('未確認', 'Unread', 'まだ よんでいません'),
                  color: read ? green : ink,
                  background: read ? const Color(0xFFE8F3EB) : paleYellow,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            s.tr(b.title, b.titleEn),
            style: TextStyle(
              fontSize: 18,
              fontWeight: read ? FontWeight.w600 : FontWeight.w700,
              height: 1.6,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 8),
            Text(
              b.date,
              style: TextStyle(fontSize: 14, color: secondaryText(context)),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            read
                ? s.tr('読み返す', 'Read again', 'もういちど よむ')
                : s.tr('お知らせを読む', 'Read update', 'おしらせを よむ'),
            style: const TextStyle(
              fontSize: 15,
              color: blue,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }
}

class BulletinDetailScreen extends StatelessWidget {
  final Bulletin bulletin;
  final String? backLabel;
  const BulletinDetailScreen({
    super.key,
    required this.bulletin,
    this.backLabel,
  });
  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context), b = bulletin;
    final read = s.readBulletins.contains(b.id);
    final remaining = visibleBulletins(
      s,
      onlyUnread: true,
    ).where((item) => item.id != b.id).toList();
    return DetailPage(
      title: s.tr('お知らせ', 'Community update', 'おしらせ'),
      backLabel:
          backLabel ??
          switch (s.tab) {
            0 => s.tr('ホームに戻る', 'Back to home'),
            1 => s.tr('回覧板に戻る', 'Back to updates'),
            _ => s.tr('戻る', 'Back'),
          },
      footer: ActionPanel(
        status: read
            ? ActionStatus(
                s.tr('確認済み', 'Read', 'よみました'),
                action: TextButton(
                  onPressed: () => s.update(() => s.readBulletins.remove(b.id)),
                  child: Text(
                    s.tr('未確認に戻す', 'Mark as unread', 'まだ よんでいない に もどす'),
                  ),
                ),
              )
            : null,
        primary: AppButton(
          label: !read
              ? s.tr('確認済みにする', 'Mark as read', 'よんだことを きろくする')
              : remaining.isNotEmpty
              ? s.tr('次の未確認を見る', 'Read next unread update', 'つぎの おしらせを よむ')
              : s.tr('回覧板一覧に戻る', 'Back to all updates', 'おしらせの いちらんに もどる'),
          outlined: read,
          onPressed: () {
            if (!read) {
              s.update(() => s.readBulletins.add(b.id));
            } else if (remaining.isNotEmpty) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => BulletinDetailScreen(
                    bulletin: remaining.first,
                    backLabel: backLabel,
                  ),
                ),
              );
            } else {
              s.update(() {
                s.tab = 1;
                s.communitySection = 1;
                s.bulletinFilter = 0;
                s.unreadOnly = false;
              });
              Navigator.popUntil(context, (route) => route.isFirst);
            }
          },
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppBadge(
                  s.tr(
                    ['お知らせ', '重要', '防災訓練'][b.category],
                    ['News', 'Important', 'Drill'][b.category],
                  ),
                  background: b.category == 1 ? ink : wash,
                  color: b.category == 1 ? Colors.white : ink,
                ),
                AppBadge(
                  read
                      ? s.tr('確認済み', 'Read', 'よみました')
                      : s.tr('未確認', 'Unread', 'まだ よんでいません'),
                  color: read ? green : ink,
                  background: read
                      ? const Color(0xFFE8F3EB)
                      : const Color(0xFFFFF3A6),
                ),
              ],
            ),
            const SizedBox(height: 16),
            PageHeader(title: s.tr(b.title, b.titleEn)),
            Text(
              b.date,
              style: TextStyle(
                fontSize: 14,
                color: secondaryText(context),
                height: 1.8,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              s.tr(b.body, b.bodyEn, easyBulletinBodies[b.id]),
              style: const TextStyle(fontSize: 16, height: 1.9),
            ),
            if (b.id == 'festival') ...[
              const SizedBox(height: 20),
              AppButton(
                label: s.tr(
                  '江東区の防災ポータルを開く',
                  'Open Koto City’s disaster portal',
                  'こうとうくの おしらせを ひらく',
                ),
                outlined: true,
                onPressed: () async {
                  final opened = await launchUrl(
                    Uri.parse('https://bosai.city.koto.lg.jp/'),
                  );
                  if (!opened && context.mounted) {
                    showNotice(
                      context,
                      s.tr('リンクを開けませんでした', 'Could not open this link'),
                    );
                  }
                },
              ),
            ],
            if (b.category == 2) ...[
              const SizedBox(height: 24),
              AppButton(
                label: s.tr(
                  '訓練モードで安否確認へ',
                  'Open safety check in drill mode',
                  'くんれんで ぶじの かくにんを ひらく',
                ),
                outlined: true,
                onPressed: () => openPage(context, const SafetyDrillScreen()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
