import 'package:flutter/material.dart';
import '../mock/demo_state.dart';
import '../widgets/common.dart';
import 'safety.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final titles = [
      s.tr('防災共有', 'Community updates'),
      s.tr('安否確認', 'Safety check'),
      s.tr('助け合い', 'Help'),
    ];
    final descriptions = [
      s.tr(
        '未確認・重要なお知らせを選んで読み、「確認済みにする」で記録できます。',
        'Read important or unread updates and mark them as read.',
        'まだ よんでいない、だいじな おしらせを よみます。「よみました」を おすと きろくします。',
      ),
      s.tr(
        '設定で「非常時の訓練」を選ぶと、ホームと下部タブに表示されます。通常時は訓練用の画面で練習できます。',
        'Emergency practice mode shows the safety check on Home and in the tab bar. You can practice in the separate drill screen.',
        'せっていで さいがいの れんしゅうを えらぶと、ホームと したの メニューに でます。ふだんは くんれんが できます。',
      ),
      s.tr(
        'ご近所の依頼や協力を確認できます。自分の投稿は、後から編集・募集終了もできます。',
        'Browse requests and offers nearby. You can edit and close your own posts.',
        'きんじょの たすけあいを みられます。じぶんの とうこうは、あとから なおしたり おわったり できます。',
      ),
    ];
    return DetailPage(
      title: s.tr('使い方', 'How to use Sonaeai', 'つかいかた'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...List.generate(
              s.isEmergency ? 3 : 2,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PageHeader(title: titles[i]),
                      Text(
                        descriptions[i],
                        style: const TextStyle(fontSize: 16, height: 1.9),
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        label: i == 1 && !s.isEmergency
                            ? s.tr(
                                '安否確認の訓練を開く',
                                'Open safety check drill',
                                'ぶじの かくにんの くんれんを ひらく',
                              )
                            : '${titles[i]}${s.tr('を開く', ' · Open', 'を ひらく')}',
                        outlined: true,
                        onPressed: () {
                          if (i == 1 && !s.isEmergency) {
                            openPage(context, const SafetyDrillScreen());
                            return;
                          }
                          s.selectTab(i + 1);
                          Navigator.popUntil(context, (r) => r.isFirst);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AppButton(
              label: s.tr('機能一覧を開く', 'Explore features', 'きのうを みる'),
              outlined: true,
              onPressed: () {
                s.selectTab(DemoState.menuTab);
                Navigator.popUntil(context, (r) => r.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }
}
