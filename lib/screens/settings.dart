import 'package:flutter/material.dart';
import '../mock/demo_state.dart';
import '../widgets/common.dart';
import 'onboarding.dart';
import 'safety.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    return DetailPage(
      title: s.tr('設定', 'Settings', 'せってい'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Group(
              title: s.tr('表示モード', 'Display mode', 'がめんの モード'),
              children: [
                ChoiceTile(
                  label: s.tr('通常時', 'Everyday', 'ふだん'),
                  selected: !s.isEmergency,
                  onTap: () => s.setEmergency(false),
                ),
                ChoiceTile(
                  label: s.tr('非常時の訓練', 'Emergency practice', 'さいがい の れんしゅう'),
                  description: s.tr(
                    '安否確認と助け合いの手順を練習できます。',
                    'Practice checking in and asking for help.',
                    'ホームと したの メニューに ぶじの かくにんが でます。',
                  ),
                  selected: s.isEmergency,
                  onTap: () => s.setEmergency(true),
                ),
                AppButton(
                  label: s.tr(
                    '安否確認の訓練を開く',
                    'Open safety check drill',
                    'ぶじの かくにんの くんれんを ひらく',
                  ),
                  outlined: true,
                  onPressed: () => openPage(context, const SafetyDrillScreen()),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _Group(
              title: s.tr('表示言語', 'Language', 'ことば'),
              children: AppLanguage.values
                  .map(
                    (language) => ChoiceTile(
                      label: ['日本語', 'やさしい日本語', 'English'][language.index],
                      selected: s.language == language,
                      onTap: () => s.update(() => s.language = language),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            _Group(
              title: s.tr('文字サイズ', 'Text size', 'もじの おおきさ'),
              children: [
                FilterTabs(
                  labels: [
                    s.tr('標準', 'Standard', 'ふつう'),
                    s.tr('大きい', 'Large', 'おおきい'),
                    s.tr('特大', 'Extra large', 'とても おおきい'),
                  ],
                  selected: [1.0, 1.3, 1.6].indexOf(s.fontScale),
                  onChanged: (i) =>
                      s.update(() => s.fontScale = [1.0, 1.3, 1.6][i]),
                ),
                SurfaceCard(
                  child: Text(
                    s.tr(
                      'この大きさで表示します。',
                      'This is how your text will look.',
                      'この おおきさで みえます。',
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                Text(
                  s.tr(
                    '端末の文字サイズ設定も反映します。',
                    'Your device’s text-size setting is also respected.',
                    'たんまつの もじの おおきさも はんえいします。',
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.7,
                    color: secondaryText(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _Group(
              title: s.tr('コントラスト', 'Contrast', 'みえかた'),
              children: [
                ChoiceTile(
                  label: s.tr('標準', 'Standard', 'ふつう'),
                  selected: !s.highContrast,
                  onTap: () => s.update(() => s.highContrast = false),
                ),
                ChoiceTile(
                  label: s.tr('高コントラスト', 'High contrast', 'はっきり'),
                  description: s.tr(
                    '補足の文字と枠線を、はっきり表示します。',
                    'Darker supporting text and stronger outlines.',
                    'もじや わくを はっきり みせます。',
                  ),
                  selected: s.highContrast,
                  onTap: () => s.update(() => s.highContrast = true),
                ),
              ],
            ),
            const SizedBox(height: 24),
            AppButton(
              label: s.tr('使い方を見る', 'How to use Sonaeai', 'つかいかたを みる'),
              outlined: true,
              onPressed: () => openPage(context, const OnboardingScreen()),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: s.tr('端末内の記録を消去', 'Clear local records', 'れんしゅうの きろくを けす'),
              outlined: true,
              onPressed: () async {
                final ok = await confirmAction(
                  context,
                  title: s.tr(
                    '端末内の記録を消去しますか？',
                    'Clear the records on this device?',
                    'れんしゅうの きろくを けしますか？',
                  ),
                  message: s.tr(
                    '点検、備蓄、投稿と写真、訓練の記録などを消去します。表示設定は残ります。',
                    'Clears checks, supplies, posts and photos, and practice records. Display settings are kept.',
                    'おしらせや、ぶじの ほうこく、とうこう、かきかけを けします。ことばや もじの おおきさは かえません。',
                  ),
                  confirmLabel: s.tr('記録をリセットする', 'Reset records', 'きろくを けす'),
                  danger: true,
                );
                if (ok && context.mounted) {
                  s.resetRecords();
                  showNotice(
                    context,
                    s.tr(
                      '端末内の記録を消去しました',
                      'Local records cleared',
                      'れんしゅうの きろくを けしました',
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 24),
            Text(
              s.tr(
                '備蓄・点検・投稿の記録はこの端末に保存します。安否確認と助け合いは訓練用です。',
                'Supplies, checks and posts are stored on this device. Safety check and mutual help are for practice.',
                'そなえの きろくや とうこうは この たんまつに のこります。ぶじの かくにんと たすけあいは れんしゅうです。',
              ),
              style: TextStyle(
                fontSize: 14,
                height: 1.8,
                color: secondaryText(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Group({required this.title, required this.children});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(
        header: true,
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      const SizedBox(height: 12),
      ...children.expand((child) => [child, const SizedBox(height: 10)]),
    ],
  );
}
