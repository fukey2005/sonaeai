import 'package:flutter/material.dart';
import '../mock/demo_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/prototype.dart';
import 'points.dart';

typedef _Mission = ({
  IconData icon,
  UiCopy scene,
  UiCopy prompt,
  List<UiCopy> options,
  int correct,
  UiCopy explanation,
});

const _missions = <_Mission>[
  (
    icon: Icons.home_outlined,
    scene: ('団地の自宅', 'At home', 'だんちの いえ'),
    prompt: (
      '訓練に出る前に、家族と何を確認しますか？',
      'What should your household check before the drill?',
      'くんれんの まえに、かぞくと なにを たしかめますか？',
    ),
    options: [
      ('集合場所と連絡方法', 'Meeting point and contact plan', 'あつまる ばしょと れんらくの しかた'),
      ('帰宅してから考える', 'Decide after returning', 'かえってから かんがえる'),
    ],
    correct: 0,
    explanation: (
      '集合場所と連絡方法を事前に話し合う場面です。',
      'This scene practices planning a meeting point and how to stay in touch.',
      'あつまる ばしょと れんらくの しかたを さきに はなします。',
    ),
  ),
  (
    icon: Icons.groups_outlined,
    scene: ('団地の広場', 'At the estate plaza', 'だんちの ひろば'),
    prompt: (
      '集合後、安否を知らせる練習はどこから始めますか？',
      'Where do you start a practice safety report?',
      'あつまった あと、どこで ぶじを しらせる れんしゅうを しますか？',
    ),
    options: [
      ('ポイントのランキング', 'Points ranking', 'ポイントの じゅんい'),
      ('訓練用の安否確認', 'Safety check in drill mode', 'くんれんの ぶじの かくにん'),
    ],
    correct: 1,
    explanation: (
      '訓練用の安否確認で、状況を選んでから報告する流れを練習できます。',
      'Drill mode lets you practice selecting and reporting your status.',
      'くんれんで、いまの ようすを えらび、しらせる れんしゅうが できます。',
    ),
  ),
  (
    icon: Icons.assignment_outlined,
    scene: ('集会所で振り返り', 'Debrief at the community hall', 'しゅうかいじょで ふりかえり'),
    prompt: (
      '備蓄の見直しを続けるには、何を記録しますか？',
      'What should you record to keep track of supplies?',
      'そなえを みなおす ために、なにを きろくしますか？',
    ),
    options: [
      ('品名・数量・期限', 'Item, quantity and expiry date', 'なまえ、かず、きげん'),
      ('品物の色だけ', 'Only the color', 'いろ だけ'),
    ],
    correct: 0,
    explanation: (
      '備蓄品管理で品名・数量・期限を一覧にする体験ができます。',
      'Use the supplies screen to try listing names, quantities and expiration dates.',
      'もちものの なまえ、かず、きげんを いちらんに できます。',
    ),
  ),
];

class TrainingGameScreen extends StatefulWidget {
  const TrainingGameScreen({super.key});

  @override
  State<TrainingGameScreen> createState() => _TrainingGameScreenState();
}

class _TrainingGameScreenState extends State<TrainingGameScreen> {
  int mission = 0;
  int? selected;
  bool reviewed = false;

  void advance(DemoState s) {
    setState(() {
      mission++;
      selected = null;
      reviewed = false;
    });
    if (mission == _missions.length) {
      s.update(() => s.demoGameCompleted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final title = s.tr('防災ゲーム', 'Preparedness game', 'ぼうさい ゲーム');
    if (mission == _missions.length) {
      return PrototypePage(
        title: title,
        description: s.tr(
          '団地の防災ミッションを体験しました。',
          'You completed the estate’s practice missions.',
          'だんちの ぼうさい ミッションが おわりました。',
        ),
        children: [
          ActionStatus(s.tr('ミッション完了', 'Missions complete', 'ミッション クリア')),
          const SizedBox(height: 16),
          AppButton(
            label: s.tr('ポイントを見る', 'View points', 'ポイントを みる'),
            onPressed: () => openPage(context, const PointsScreen()),
          ),
          const SizedBox(height: 10),
          AppButton(
            label: s.tr('もう一度遊ぶ', 'Play again', 'もういちど あそぶ'),
            outlined: true,
            onPressed: () => setState(() => mission = 0),
          ),
        ],
      );
    }

    final current = _missions[mission];
    return PrototypePage(
      title: title,
      description: s.tr(
        '団地を舞台に、訓練の場面を選択式で体験します。',
        'Make choices in a practice drill set in the estate.',
        'だんちの くんれんで、どうするか えらびます。',
      ),
      footer: ActionPanel(
        primary: AppButton(
          label: !reviewed
              ? s.tr('答えを確認', 'Check answer', 'こたえを たしかめる')
              : mission + 1 < _missions.length
              ? s.tr('次の場面へ', 'Next scene', 'つぎの ばめんへ')
              : s.tr('体験を終える', 'Finish practice', 'れんしゅうを おえる'),
          onPressed: selected == null
              ? null
              : reviewed
              ? () => advance(s)
              : () => setState(() => reviewed = true),
        ),
      ),
      children: [
        Text(
          s.tr(
            'ミッション ${mission + 1} / ${_missions.length}',
            'Mission ${mission + 1} of ${_missions.length}',
            'ミッション ${mission + 1} / ${_missions.length}',
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (mission + 1) / _missions.length,
          color: ink,
          backgroundColor: line,
        ),
        const SizedBox(height: 14),
        SurfaceCard(
          color: const Color(0xFFFFF3A6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(current.icon, size: 36, color: ink),
              const SizedBox(height: 8),
              Text(
                current.scene.forDemo(s),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                current.prompt.forDemo(s),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (reviewed) ...[
          ActionStatus(
            selected == current.correct
                ? s.tr('正解です', 'Correct', 'せいかい')
                : s.tr('答えを振り返ろう', 'Review the answer', 'こたえを みてみよう'),
            tone: selected == current.correct
                ? StatusTone.complete
                : StatusTone.pending,
          ),
          const SizedBox(height: 10),
          Text(
            current.options[current.correct].forDemo(s),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            current.explanation.forDemo(s),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ] else
          for (var i = 0; i < current.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ChoiceTile(
                label: current.options[i].forDemo(s),
                selected: selected == i,
                onTap: () => setState(() => selected = i),
              ),
            ),
      ],
    );
  }
}
