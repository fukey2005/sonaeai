import 'package:flutter/material.dart';
import '../mock/demo_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/prototype.dart';
import 'bulletins.dart';
import 'home_check.dart';
import 'preparedness_map.dart';
import 'supplies.dart';

typedef _Topic = ({UiCopy question, UiCopy answer, UiCopy action});

const _topics = <AssistantTopic, _Topic>{
  AssistantTopic.supplies: (
    question: ('備蓄の見直し', 'Review supplies', 'もちものを みなおす'),
    answer: (
      '備蓄品管理では、品物ごとの数量と期限を確認できます。「期限が近い・期限切れ」で見直すものを絞れます。',
      'In Supplies, check quantities and dates. Filter by expiring or expired items to see what needs attention.',
      'そなえの もちものでは、かずと きげんが みられます。きげんが ちかい ものを みてみましょう。',
    ),
    action: ('備蓄品管理を開く', 'Open supplies', 'そなえの もちものを みる'),
  ),
  AssistantTopic.shelters: (
    question: ('団地の近くの避難所', 'Shelters near the estate', 'だんちの ちかくの ひなんじょ'),
    answer: (
      '大島六丁目団地の周辺には第四大島小学校などの拠点避難所があります。災害の種類に合った避難先や開設状況は、江東区の案内で確かめてください。',
      'Daiyon Ojima Elementary is one of the base shelters near the estate. Check Koto City’s guidance for opening status and a place suited to the hazard.',
      'だんちの ちかくには だいよん おおじま しょうがっこうなどが あります。どこに にげるか、こうとうくの おしらせで みます。',
    ),
    action: ('防災マップを開く', 'Open disaster map', 'ぼうさい マップを みる'),
  ),
  AssistantTopic.homeCheck: (
    question: ('自宅の備え', 'Check home preparedness', 'いえの そなえ'),
    answer: (
      '自宅の防災診断では、家具・出入口・棚上を順番に撮影し、写真ごとに確認すべきところを見直せます。確認した内容と写真は点検履歴に残ります。',
      'Photograph furniture, a doorway, and shelves one by one. The inspection shows what to check in each photo and keeps the photos with your results.',
      'かぐ・でいりぐち・たなの うえを じゅんばんに とります。しゃしんごとに みる ところが わかり、しゃしんと きろくが のこります。',
    ),
    action: ('自宅の防災診断を開く', 'Open home inspection', 'いえの てんけんを みる'),
  ),
  AssistantTopic.drill: (
    question: ('訓練の準備', 'Prepare for a drill', 'くんれんの じゅんび'),
    answer: (
      '回覧板の訓練のお知らせから、訓練用の安否報告を体験できます。',
      'Open the drill notice on the bulletin board to try a practice safety report.',
      'くんれんの おしらせから、ぶじか どうかを しらせる れんしゅうが できます。',
    ),
    action: ('訓練のお知らせを読む', 'Read the drill notice', 'くんれんの おしらせを よむ'),
  ),
  AssistantTopic.earthquake: (
    question: ('地震が起きたら？', 'What if an earthquake starts?', 'じしんが おきたら？'),
    answer: (
      '室内で揺れを感じたら、まず頭と体を守ります。丈夫な机の下などに身を寄せ、揺れが収まるまで待ちます。\n参考：東京都防災ホームページ',
      'If you feel shaking indoors, first protect your head and body. Take cover under a sturdy table if you can and wait for the shaking to stop.\nSource: Tokyo Metropolitan Government',
      'へやで ゆれたら、まず あたまと からだを まもります。じょうぶな つくえの したなどで、ゆれが おわるまで まちます。\nさんこう：とうきょうとの ぼうさいページ',
    ),
    action: ('自宅の防災診断を開く', 'Open home inspection', 'いえの てんけんを みる'),
  ),
  AssistantTopic.evacuation: (
    question: (
      '避難するときの確認は？',
      'What should I check before evacuating?',
      'にげる ときは なにを みる？',
    ),
    answer: (
      '自治体が発表する避難情報を確認し、災害の種類に合った避難場所を調べます。事前にハザードマップで危険区域と避難経路を見比べておきましょう。\n参考：防災情報のページ',
      'Check official local evacuation information and look for an evacuation site designated for the type of hazard. In advance, compare hazard zones and possible routes on an official map.\nSource: Japan disaster management information',
      'まちの ひなんの おしらせを みます。さいがいの しゅるいに あう にげる ばしょを しらべます。ふだんから ちずで きけんな ばしょと みちを たしかめます。\nさんこう：ぼうさいじょうほうの ページ',
    ),
    action: ('ハザードマップを開く', 'Open hazard map', 'きけんな ばしょの ちずを みる'),
  ),
  AssistantTopic.flood: (
    question: ('洪水時の避難先は？', 'Where can I go in a flood?', 'こうずいの とき どこに にげる？'),
    answer: (
      '地図の「洪水」で浸水想定と水害時の一時避難施設を確認できます。施設を利用できる条件や開設状況は、江東区の案内で確かめてください。',
      'The Flood map shows projected inundation and temporary flood refuges. Check Koto City’s guidance for access conditions and current availability.',
      'ちずの「こうずい」で、みずが くる おそれの ある ところと、いちじてきに にげる ばしょを みられます。つかえる かどうかは こうとうくの おしらせを みます。',
    ),
    action: ('洪水の地図を開く', 'Open the flood map', 'こうずいの ちずを みる'),
  ),
};

AssistantTopic? _sampleTopic(String input) {
  final text = input.toLowerCase();
  for (final (topic, keywords) in [
    (AssistantTopic.drill, '訓練|くんれん|drill'),
    (AssistantTopic.flood, '洪水|水害|浸水|こうずい|flood'),
    (AssistantTopic.earthquake, '地震が起き|地震直後|地震のとき|揺れ|じしん|earthquake|shaking'),
    (
      AssistantTopic.evacuation,
      '避難方法|どこへ避難|どう避難|避難すれば|避難する|避難ルート|避難経路|how to evacuate|evacuation route|にげかた|どう にげ',
    ),
    (AssistantTopic.shelters, '避難|地図|にげる|map|shelter'),
    (AssistantTopic.homeCheck, '自宅|家具|診断|いえ|かぐ|house|checklist|furniture|home'),
    (
      AssistantTopic.supplies,
      '備蓄|水|食品|食料|期限|もちもの|たべもの|water|food|suppl|stock|expir',
    ),
  ]) {
    if (keywords.split('|').any(text.contains)) return topic;
  }
  return null;
}

class DisasterChatScreen extends StatefulWidget {
  final bool assistant;
  const DisasterChatScreen.community({super.key}) : assistant = false;
  const DisasterChatScreen.assistant({super.key}) : assistant = true;

  @override
  State<DisasterChatScreen> createState() => _DisasterChatScreenState();
}

class _DisasterChatScreenState extends State<DisasterChatScreen> {
  final composer = TextEditingController();
  final scroll = ScrollController();
  int seenQuestions = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.assistant) return;
    final questionCount = DemoScope.of(context).assistantQuestions.length;
    if (seenQuestions != questionCount) {
      seenQuestions = questionCount;
      jumpToLatest();
    }
  }

  @override
  void dispose() {
    composer.dispose();
    scroll.dispose();
    super.dispose();
  }

  void jumpToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && scroll.hasClients) {
        scroll.jumpTo(scroll.position.maxScrollExtent);
      }
    });
  }

  void send(DemoState s, {AssistantTopic? topic}) {
    final input = topic == null ? composer.text.trim() : '';
    if (topic == null && input.isEmpty) return;
    if (topic == null) composer.clear();
    if (widget.assistant) {
      s.askAssistant((topic: topic ?? _sampleTopic(input), text: input));
    } else {
      s.update(() => s.communityMessages.add(input));
      jumpToLatest();
    }
  }

  void openRelated(AssistantTopic topic) => openPage<void>(
    context,
    switch (topic) {
      AssistantTopic.supplies => const SuppliesScreen(),
      AssistantTopic.shelters ||
      AssistantTopic.evacuation => const PreparednessMapScreen(),
      AssistantTopic.homeCheck => const HomeCheckScreen(),
      AssistantTopic.earthquake => const HomeCheckScreen(),
      AssistantTopic.flood => const PreparednessMapScreen(showFlood: true),
      AssistantTopic.drill => BulletinDetailScreen(
        bulletin: bulletins.firstWhere((bulletin) => bulletin.id == 'training'),
        backLabel: DemoScope.of(context).tr('そなAIに戻る', 'Back to Sona AI'),
      ),
    },
  );

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final assistant = widget.assistant;
    final title = assistant
        ? 'そなAI'
        : s.tr('防災チャット', 'Community chat', 'ぼうさい チャット');

    Widget topicChips(List<AssistantTopic> topics) => Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        for (final topic in topics)
          Semantics(
            label: _topics[topic]!.question.forDemo(s),
            button: true,
            onTap: () => send(s, topic: topic),
            excludeSemantics: true,
            child: ActionChip(
              label: Text(_topics[topic]!.question.forDemo(s)),
              backgroundColor: paper,
              onPressed: () => send(s, topic: topic),
            ),
          ),
      ],
    );
    Widget suggestions() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.tr('災害時の行動', 'During a disaster', 'さいがいの とき')),
        topicChips(const [
          AssistantTopic.earthquake,
          AssistantTopic.evacuation,
          AssistantTopic.shelters,
        ]),
        const SizedBox(height: 6),
        Text(s.tr('日頃の備え', 'Everyday preparedness', 'ふだんの そなえ')),
        topicChips(const [
          AssistantTopic.supplies,
          AssistantTopic.homeCheck,
          AssistantTopic.drill,
        ]),
      ],
    );

    final body = ColoredBox(
      color: paper,
      child: TaskBody(
        controller: scroll,
        footer: ActionPanel(
          primary: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: composer,
                  maxLength: 180,
                  minLines: 1,
                  maxLines: 2,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => send(s),
                  decoration: InputDecoration(
                    labelText: assistant
                        ? s.tr('そなAIに聞く', 'Ask Sona AI', 'そなAIに きく')
                        : s.tr('メッセージ', 'Message', 'メッセージ'),
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder(
                valueListenable: composer,
                builder: (context, value, _) => IconButton.filled(
                  tooltip: assistant
                      ? s.tr('質問する', 'Ask', 'きく')
                      : s.tr('記録する', 'Save message', 'きろくする'),
                  style: IconButton.styleFrom(
                    minimumSize: const Size.square(48),
                  ),
                  onPressed: value.text.trim().isEmpty ? null : () => send(s),
                  icon: const Icon(Icons.send_rounded),
                ),
              ),
            ],
          ),
        ),
        children: [
          if (assistant) ...[
            Text(
              s.tr(
                '防災の資料から、備えや災害時の行動を調べられます。',
                'Find guidance on preparedness and what to do during a disaster.',
                'ふだんの そなえや、さいがいの ときに することを しらべます。',
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            suggestions(),
            const SizedBox(height: 16),
            if (s.assistantQuestions.isEmpty) ...[
              _Bubble(
                author: s.tr('質問例', 'Example question', 'しつもんの れい'),
                body: s.tr(
                  '団地の近くには、地震のときに使う避難所がありますか？',
                  'Is there a shelter near the estate for an earthquake?',
                  'だんちの ちかくに じしんの ときの ひなんじょは ありますか？',
                ),
                mine: true,
              ),
              _Bubble(
                author: 'そなAI',
                body: _topics[AssistantTopic.shelters]!.answer.forDemo(s),
                action: TextButton(
                  onPressed: () => openRelated(AssistantTopic.shelters),
                  child: Text(
                    _topics[AssistantTopic.shelters]!.action.forDemo(s),
                  ),
                ),
              ),
            ],
            for (final question in s.assistantQuestions) ...[
              _Bubble(
                author: s.tr('あなた', 'You'),
                body: question.text.isEmpty
                    ? _topics[question.topic]!.question.forDemo(s)
                    : question.text,
                mine: true,
              ),
              Semantics(
                liveRegion: true,
                child: _Bubble(
                  author: 'そなAI',
                  body:
                      _topics[question.topic]?.answer.forDemo(s) ??
                      s.tr(
                        'この質問に合う案内が見つかりませんでした。地震、避難所、備蓄などの言葉で聞き直せます。',
                        'No guidance matched this question. Try a term such as earthquake, shelter, or supplies.',
                        'この しつもんの こたえが ありません。じしん、ひなんじょ、そなえ などで きいてみます。',
                      ),
                  action: question.topic == null
                      ? null
                      : TextButton(
                          onPressed: () => openRelated(question.topic!),
                          child: Text(
                            _topics[question.topic]!.action.forDemo(s),
                          ),
                        ),
                ),
              ),
            ],
          ] else ...[
            Text(
              s.tr(
                '訓練用の会話です。入力したメッセージは端末内に保存されます。',
                'Practice conversation. Your messages stay on this device.',
                'だんちの チャットの れいです。かいた ことは この がめんにだけ でます。',
              ),
            ),
            const SizedBox(height: 12),
            _Bubble(
              author: s.tr('住民A', 'Resident A', 'だんちの ひとA'),
              body: s.tr(
                '訓練のお知らせはどこから読めますか？',
                'Where can I read the drill notice?',
                'くんれんの おしらせは どこで よめますか？',
              ),
            ),
            _Bubble(
              author: s.tr('住民B', 'Resident B', 'だんちの ひとB'),
              body: s.tr(
                '回覧板の「防災訓練」に載っています。',
                'It is under Drills on the bulletin board.',
                'おしらせの「ぼうさい くんれん」に あります。',
              ),
            ),
            for (final message in s.communityMessages)
              _Bubble(author: s.tr('あなた', 'You'), body: message, mine: true),
          ],
        ],
      ),
    );
    return DetailPage(title: title, child: body);
  }
}

class _Bubble extends StatelessWidget {
  final String author, body;
  final bool mine;
  final Widget? action;
  const _Bubble({
    required this.author,
    required this.body,
    this.mine = false,
    this.action,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: mine ? 32 : 0,
      right: mine ? 0 : 20,
      bottom: 12,
    ),
    child: SurfaceCard(
      color: mine ? paleYellow : paper,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            author,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(body, style: Theme.of(context).textTheme.bodyLarge),
          if (action != null) ...[const SizedBox(height: 6), action!],
        ],
      ),
    ),
  );
}
