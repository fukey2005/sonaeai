import 'package:flutter/material.dart';
import '../mock/demo_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/prototype.dart';

class PointsScreen extends StatefulWidget {
  const PointsScreen({super.key});

  @override
  State<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends State<PointsScreen> {
  int section = 0;

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final myPoints = (s.dailyChecks * 5) + (s.demoGameCompleted ? 10 : 0);
    final ranking = [
      (name: s.tr('住民A', 'Resident A', 'だんちの ひとA'), points: 152, me: false),
      (name: s.tr('住民B', 'Resident B', 'だんちの ひとB'), points: 128, me: false),
      (name: s.tr('あなた', 'You', 'あなた'), points: myPoints, me: true),
      (name: s.tr('住民C', 'Resident C', 'だんちの ひとC'), points: 104, me: false),
    ]..sort((a, b) => b.points.compareTo(a.points));

    return PrototypePage(
      title: s.tr('ポイント・ランキング', 'Points & ranking', 'ポイントと じゅんい'),
      children: [
        FilterTabs(
          labels: [
            s.tr('マイポイント', 'My points', 'じぶんの ポイント'),
            s.tr('ランキング', 'Ranking', 'じゅんい'),
          ],
          selected: section,
          onChanged: (value) => setState(() => section = value),
        ),
        const SizedBox(height: 16),
        if (section == 0) ...[
          SurfaceCard(
            color: const Color(0xFFFFF3A6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.tr('保有ポイント', 'Points balance', 'いまの ポイント')),
                Text(
                  '$myPoints pt',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            s.tr('今日の活動', 'Today’s activity', 'きょうの かつどう'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          if (s.checkedInToday)
            ActionStatus(
              s.tr(
                '今日の利用を記録済み · +5 pt',
                'Daily visit recorded · +5 pt',
                'きょうは きろくずみ · +5 pt',
              ),
            )
          else
            AppButton(
              label: s.tr(
                '今日の利用を記録',
                'Record today’s visit',
                'きょうの りようを きろくする',
              ),
              onPressed: s.checkIn,
            ),
          const SizedBox(height: 10),
          if (s.demoGameCompleted)
            ActionStatus(
              s.tr(
                '防災ゲームをクリア · +10 pt',
                'Game completed · +10 pt',
                'ゲームを クリア · +10 pt',
              ),
            )
          else
            Text(
              s.tr(
                '防災ゲームを体験すると、クリアの記録がここに表示されます。',
                'Finish the sample game to see its activity here.',
                'ゲームを おえると、ここに きろくが でます。',
              ),
            ),
        ] else ...[
          Text(
            s.tr('ランキングの見本', 'Example ranking', 'こんしゅうの じゅんいの れい'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < ranking.length; i++) ...[
            SurfaceCard(
              color: ranking[i].me ? const Color(0xFFFFF3A6) : paper,
              child: Wrap(
                spacing: 12,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AppBadge(s.tr('${i + 1}位', '#${i + 1}', '${i + 1}い')),
                  Text(
                    ranking[i].name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text('${ranking[i].points} pt'),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}
