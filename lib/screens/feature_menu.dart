import 'package:flutter/material.dart';
import '../mock/demo_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/prototype.dart';
import 'disaster_chat.dart';
import 'home_check.dart';
import 'points.dart';
import 'preparedness_map.dart';
import 'safety.dart';
import 'supplies.dart';
import 'training_game.dart';

class FeatureMenuScreen extends StatefulWidget {
  const FeatureMenuScreen({super.key});

  @override
  State<FeatureMenuScreen> createState() => _FeatureMenuScreenState();
}

class _FeatureMenuScreenState extends State<FeatureMenuScreen> {
  final search = TextEditingController();
  String query = '';

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final groups = [
      (
        title: s.tr('地域でつながる', 'Connect with neighbors', 'だんちで つながる'),
        links: [
          FeatureLink(
            title: s.tr('防災共有', 'Updates & resident board', 'おしらせ・けいじばん'),
            description: s.tr(
              '回覧板のお知らせと危険箇所の投稿',
              'Read notices and share local hazards',
              'おしらせや きけんな ばしょを みる',
            ),
            onTap: () => s.selectTab(1),
          ),
          FeatureLink(
            title: s.isEmergency
                ? s.tr('安否確認', 'Safety check', 'ぶじの かくにん')
                : s.tr('安否確認の訓練', 'Safety check drill', 'ぶじの かくにんの くんれん'),
            description: s.isEmergency
                ? s.tr(
                    '自分の状況を確認・報告',
                    'Check and report your status',
                    'じぶんの ようすを しらせる',
                  )
                : s.tr(
                    '訓練用の画面で報告を練習',
                    'Practice a safety report',
                    'ぶじを しらせる れんしゅうを する',
                  ),
            onTap: () {
              if (s.isEmergency) {
                s.selectTab(DemoState.safetyTab);
              } else {
                openPage(context, const SafetyDrillScreen());
              }
            },
          ),
          if (s.isEmergency)
            FeatureLink(
              title: s.tr('助け合い・防災チャット', 'Help & community chat', 'たすけあい・チャット'),
              description: s.tr(
                '支援の依頼・協力募集・連絡',
                'Ask for help, offer support or chat',
                'たすけを おねがいする、れんらくする',
              ),
              onTap: () => s.selectTab(DemoState.helpTab),
            ),
        ],
      ),
      (
        title: s.tr('日頃からそなえる', 'Prepare for emergencies', 'ふだんから そなえる'),
        links: [
          FeatureLink(
            title: s.tr('ハザードマップ', 'Hazard map', 'きけんな ばしょの ちず'),
            description: s.tr(
              '現在地と地震・洪水それぞれの避難先',
              'See your location and where to go for each hazard',
              'いまの ばしょと、じしん・こうずいの ときに にげる ばしょ',
            ),
            onTap: () => openPage(context, const PreparednessMapScreen()),
          ),
          FeatureLink(
            title: s.tr('備蓄品管理', 'Supplies', 'そなえの もちもの'),
            description: s.tr(
              '品物の数量と期限を確認',
              'Track supplies, quantities and expiry dates',
              'もちものの かずと きげんを みる',
            ),
            onTap: () => openPage(context, const SuppliesScreen()),
          ),
          FeatureLink(
            title: s.tr('自宅の防災診断', 'Home preparedness check', 'いえの そなえチェック'),
            description: s.tr(
              '写真で家具・出入口・棚上を点検',
              'Inspect furniture, entrances and shelves with photos',
              'かぐ・でいりぐち・たなの うえを しゃしんで たしかめる',
            ),
            onTap: () => openPage(context, const HomeCheckScreen()),
          ),
          FeatureLink(
            title: 'そなAI',
            description: s.tr(
              '備えや災害時の行動を調べる',
              'Find preparedness and disaster guidance',
              'そなえや さいがいの ときの こうどうを しらべる',
            ),
            onTap: () =>
                openPage(context, const DisasterChatScreen.assistant()),
          ),
        ],
      ),
      (
        title: s.tr('防災をまなぶ', 'Learn about preparedness', 'ぼうさいを まなぶ'),
        links: [
          FeatureLink(
            title: s.tr('防災ゲーム', 'Preparedness game', 'ぼうさい ゲーム'),
            description: s.tr(
              '団地の防災ミッションを体験',
              'Try a practice mission set in the estate',
              'だんちの ミッションに ちょうせん',
            ),
            onTap: () => openPage(context, const TrainingGameScreen()),
          ),
          FeatureLink(
            title: s.tr('ポイント・ランキング', 'Points & ranking', 'ポイントと じゅんい'),
            description: s.tr(
              '日ごろの活動記録と順位の表示例',
              'Preview rewards and a sample leaderboard',
              'かつどうの きろくと じゅんいの れい',
            ),
            onTap: () => openPage(context, const PointsScreen()),
          ),
        ],
      ),
    ];
    final term = query.trim().toLowerCase();
    final matches = [
      for (final group in groups)
        (
          title: group.title,
          links: group.links
              .where(
                (link) => '${link.title} ${link.description} ${group.title}'
                    .toLowerCase()
                    .contains(term),
              )
              .toList(),
        ),
    ].where((group) => group.links.isNotEmpty).toList();
    return ColoredBox(
      color: paper,
      child: TaskBody(
        controls: TextField(
          controller: search,
          key: const ValueKey('feature-query'),
          onChanged: (input) => setState(() => query = input),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: s.tr('機能を探す', 'Find a feature', 'きのうを さがす'),
            prefixIcon: const Icon(Icons.search_rounded, color: ink),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: s.tr('検索をクリア', 'Clear search', 'けんさくを けす'),
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      search.clear();
                      setState(() => query = '');
                    },
                  ),
          ),
        ),
        children: [
          if (matches.isEmpty)
            EmptyState(
              title: s.tr('機能が見つかりません', 'No matching features', 'きのうが みつかりません'),
              message: s.tr(
                '「備蓄」や「マップ」など、短い言葉で探せます。',
                'Try a shorter word such as “map” or “supplies”.',
                '「ちず」など みじかい ことばで さがせます。',
              ),
            ),
          for (final group in matches) ...[
            Semantics(
              header: true,
              child: Text(
                group.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 10),
            for (final link in group.links)
              Padding(padding: const EdgeInsets.only(bottom: 10), child: link),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}
