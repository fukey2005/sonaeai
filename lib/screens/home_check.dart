import 'package:flutter/material.dart';
import '../mock/demo_state.dart';
import '../room_inspection.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'room_photo.dart';
import 'supplies.dart';

final _example = (
  time: DateTime(2026, 11, 14),
  photos: <InspectionPhoto>[
    (
      area: RoomArea.tallFurniture,
      photoKey: 'assets/samples/cabinet.jpg',
      flagged: true,
      reviewed: false,
    ),
    (
      area: RoomArea.doorway,
      photoKey: 'assets/samples/hallway.jpg',
      flagged: true,
      reviewed: true,
    ),
    (
      area: RoomArea.upperShelf,
      photoKey: 'assets/samples/shelf.jpg',
      flagged: true,
      reviewed: true,
    ),
  ],
);

class HomeCheckScreen extends StatelessWidget {
  final bool inTab;
  const HomeCheckScreen({super.key, this.inTab = false});

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final text = Theme.of(context).textTheme;
    final dates = MaterialLocalizations.of(context);
    final due = s.supplies.where((item) {
      final expiry = item.expiry;
      return expiry != null &&
          !expiry.isAfter(DateUtils.addDaysToDate(DateTime.now(), 7));
    }).length;
    final body = TaskBody(
      children: [
        SurfaceCard(
          color: paleYellow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: s.tr(
                  '写真で自宅を点検',
                  'Inspect your home with photos',
                  'しゃしんで いえを てんけん',
                ),
              ),
              Text(
                s.tr(
                  '家具・出入口・棚上の3か所を、案内に沿って撮影します。',
                  'Follow the steps to photograph furniture, a doorway, and shelves.',
                  'かぐ・でいりぐち・たなの うえを、あんないに そって とります。',
                ),
              ),
              const SizedBox(height: 14),
              AppButton(
                label: s.tr('点検を始める', 'Start inspection', 'てんけんを はじめる'),
                onPressed: () => openPage(context, const RoomPhotoScreen()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        PageHeader(title: s.tr('点検履歴', 'Inspection history', 'てんけんの きろく')),
        for (final (index, inspection) in s.roomInspections.indexed)
          _HistoryRow(inspection: inspection, latest: index == 0),
        if (s.roomCheckedAt != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              dates.formatCompactDate(s.roomCheckedAt!),
              style: text.titleMedium,
            ),
            subtitle: Text(
              s.tr(
                '以前の点検 · 写真なし · ${s.roomCheckAnswers.length} 項目を確認済み',
                'Earlier check · No photos · ${s.roomCheckAnswers.length} reviewed',
                'まえの てんけん · しゃしんなし · ${s.roomCheckAnswers.length}こ かくにんした',
              ),
            ),
          ),
        _HistoryRow(inspection: _example, sample: true),
        const SizedBox(height: 14),
        const Divider(),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          title: Text(
            s.tr('備蓄品管理', 'Supplies', 'そなえの もちもの'),
            style: text.titleMedium,
          ),
          subtitle: Text(
            s.supplies.isEmpty
                ? s.tr(
                    '水・食料・防災用品を管理',
                    'Track water, food, and supplies',
                    'みず・たべもの・ぼうさいの もちもの',
                  )
                : due > 0
                ? s.tr(
                    '期限が近い・切れた品物が $due 件',
                    '$due items due or expired',
                    'きげんを みる ものが $due こ',
                  )
                : s.tr('${s.supplies.length} 品目', '${s.supplies.length} items'),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => openPage(context, const SuppliesScreen()),
        ),
      ],
    );
    return inTab
        ? body
        : DetailPage(
            title: s.tr('自宅の防災診断', 'Home preparedness', 'いえの そなえ'),
            child: body,
          );
  }
}

class _HistoryRow extends StatelessWidget {
  final RoomInspection inspection;
  final bool latest, sample;
  const _HistoryRow({
    required this.inspection,
    this.latest = false,
    this.sample = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final date = MaterialLocalizations.of(
      context,
    ).formatCompactDate(inspection.time);
    final timestamp = '$date ${timeLabel(inspection.time)}';
    final count = inspection.photos.where((item) => !item.reviewed).length;
    final photoCount = inspection.photos.length;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      title: Text(
        sample
            ? s.tr('過去のAI点検サンプル', 'Example AI inspection', 'まえの てんけんの れい')
            : latest
            ? s.tr(
                '前回の点検 · $timestamp',
                'Last inspection · $timestamp',
                'まえの てんけん · $timestamp',
              )
            : timestamp,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        count == 0
            ? s.tr(
                '写真$photoCount枚 · すべて確認済み',
                '$photoCount photos · All reviewed',
                'しゃしん $photoCount まい · ぜんぶ かくにんした',
              )
            : s.tr(
                '写真$photoCount枚 · 未確認$countか所',
                '$photoCount photos · $count to review',
                'しゃしん $photoCount まい · まだ $count かしょ',
              ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => openPage(
        context,
        RoomHistoryScreen(inspection: inspection, sample: sample),
      ),
    );
  }
}
