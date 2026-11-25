import 'package:flutter/material.dart';
import '../post_photos.dart';
import '../room_inspection.dart';
import 'easy_japanese.dart';

enum AppLanguage { japanese, easy, english }

// Stored topic names preserve posts written with the earlier categories.
enum BoardTopic { preparedness, drill, hazard }

enum AssistantTopic {
  supplies,
  shelters,
  homeCheck,
  drill,
  earthquake,
  evacuation,
  flood,
}

typedef DemoBoardPost = ({
  String id,
  String body,
  BoardTopic topic,
  String? place,
  DateTime time,
  String? photoKey,
});
typedef AssistantQuestion = ({AssistantTopic? topic, String text});
typedef DemoSupply = ({String name, int quantity, DateTime? expiry});

class SafetyDraft {
  int? status, place;
  final Set<int> tags = {};
  SafetyDraft({this.status, this.place});
  SafetyDraft.fromReport(SafetyReport report)
    : status = report.status,
      place = report.place {
    tags.addAll(report.tags);
  }
}

class SafetyReport {
  final int status;
  final int? place;
  final Set<int> tags;
  final DateTime time;
  final bool drill;
  SafetyReport({
    required this.status,
    this.place,
    required Set<int> tags,
    required this.time,
    required this.drill,
  }) : tags = Set.unmodifiable(tags);
}

class DemoState extends ChangeNotifier {
  static const safetyTab = 2;
  static const helpTab = 3;
  static const menuTab = 4;
  static const mapTab = 5;
  static const homeCheckTab = 6;

  AppLanguage language = AppLanguage.japanese;
  double fontScale = 1;
  bool highContrast = false;
  bool _emergency = false;
  bool get isEmergency => _emergency;
  bool demoGameCompleted = false;
  DateTime? lastDailyCheck;
  int dailyChecks = 0;
  bool get checkedInToday =>
      DateUtils.isSameDay(lastDailyCheck, DateTime.now());
  bool storageUnavailable = false;
  Future<void> Function()? waitForLocalSaves;
  int tab = 0, resetVersion = 0;
  int bulletinFilter = 0;
  bool unreadOnly = false;
  int helpFilter = 0, helpRevision = 0;
  int? helpCategoryFilter;
  final Set<String> readBulletins = {};
  final List<DemoBoardPost> boardPosts = [];
  PostPhotos postPhotos = PostPhotos();
  int communitySection = 0;
  final List<AssistantQuestion> assistantQuestions = [];
  final List<String> communityMessages = [];
  final Set<int> homeCheckAnswers = {};
  final Set<int> roomCheckAnswers = {};
  DateTime? roomCheckedAt;
  final List<RoomInspection> roomInspections = [];
  final List<DemoSupply> supplies = [];
  final Map<bool, SafetyReport> safetyReports = {};
  final Map<bool, SafetyDraft> safetyDrafts = {};
  final Map<String, DateTime> responses = {};
  final Set<String> closedPosts = {};
  final List<HelpPost> posts = List.of(sampleHelp);
  HelpDraft helpDraft = HelpDraft();
  final Map<String, HelpDraft> editDrafts = {};

  String tr(String ja, String en, [String? easy]) =>
      language == AppLanguage.english
      ? en
      : language == AppLanguage.easy
      ? (easy ?? easyJapanese[ja] ?? ja)
      : ja;
  void update(VoidCallback change) {
    change();
    notifyListeners();
  }

  void selectTab(int value) {
    if ((value == safetyTab || value == helpTab) && !isEmergency) return;
    update(() => tab = value);
  }

  void setEmergency(bool enabled) {
    if (isEmergency == enabled) return;
    update(() {
      _emergency = enabled;
      if (!enabled && (tab == safetyTab || tab == helpTab)) tab = 0;
    });
  }

  void askAssistant(AssistantQuestion question) =>
      update(() => assistantQuestions.add(question));

  void checkIn() {
    if (checkedInToday) return;
    update(() {
      lastDailyCheck = DateTime.now();
      dailyChecks++;
    });
  }

  SafetyReport? safetyReport({bool drill = false}) => safetyReports[drill];
  SafetyDraft safetyDraft({bool drill = false}) => safetyDrafts.putIfAbsent(
    drill,
    () => safetyReport(drill: drill) == null
        ? SafetyDraft()
        : SafetyDraft.fromReport(safetyReport(drill: drill)!),
  );
  bool safetyChanged({bool drill = false}) {
    final d = safetyDraft(drill: drill), r = safetyReport(drill: drill);
    if (r == null) {
      return d.status != null || d.place != null || d.tags.isNotEmpty;
    }
    return d.status != r.status ||
        d.place != r.place ||
        d.tags.length != r.tags.length ||
        !d.tags.containsAll(r.tags);
  }

  void saveSafety({bool drill = false}) => update(() {
    final d = safetyDraft(drill: drill);
    safetyReports[drill] = SafetyReport(
      status: d.status!,
      place: d.place,
      tags: d.tags,
      time: DateTime.now(),
      drill: drill,
    );
  });

  void reportSafe() {
    safetyDrafts[false] = SafetyDraft(status: 0);
    saveSafety();
  }

  void restoreSafetyDraft({bool drill = false}) => update(() {
    final report = safetyReport(drill: drill);
    safetyDrafts[drill] = report == null
        ? SafetyDraft()
        : SafetyDraft.fromReport(report);
  });
  HelpPost postById(String id) => posts.firstWhere((p) => p.id == id);
  HelpDraft draftFor(HelpPost? editing) => editing == null
      ? helpDraft
      : editDrafts.putIfAbsent(editing.id, () => HelpDraft.fromPost(editing));
  void clearDraft(String? id) => update(() {
    if (id == null) {
      helpDraft = HelpDraft();
    } else {
      editDrafts.remove(id);
    }
  });
  HelpPost commitPost(HelpDraft draft, {String? id}) {
    final cat = draft.category!;
    final post = HelpPost(
      id: id ?? 'local-${DateTime.now().microsecondsSinceEpoch}',
      title: draft.titleEdited
          ? draft.title.trim()
          : defaultHelpTitle(draft.request, cat, false),
      titleEn: draft.titleEdited
          ? draft.title.trim()
          : defaultHelpTitle(draft.request, cat, true),
      detail: draft.detail.trim(),
      detailEn: draft.detail.trim(),
      request: draft.request,
      building: draft.building!,
      category: cat,
      own: true,
      landmark: draft.landmark.trim(),
      customTitle: draft.titleEdited,
    );
    update(() {
      if (id == null) {
        posts.insert(0, post);
        helpDraft = HelpDraft();
      } else {
        posts[posts.indexWhere((p) => p.id == id)] = post;
        editDrafts.remove(id);
      }
      helpFilter = 3;
      helpCategoryFilter = null;
      helpRevision++;
      if (isEmergency) tab = helpTab;
    });
    return post;
  }

  void resetRecords() => update(() {
    lastDailyCheck = null;
    dailyChecks = 0;
    demoGameCompleted = false;
    tab = 0;
    resetVersion++;
    bulletinFilter = 0;
    unreadOnly = false;
    communitySection = 0;
    helpFilter = 0;
    helpCategoryFilter = null;
    helpRevision++;
    readBulletins.clear();
    boardPosts.clear();
    assistantQuestions.clear();
    communityMessages.clear();
    homeCheckAnswers.clear();
    roomCheckAnswers.clear();
    roomCheckedAt = null;
    roomInspections.clear();
    supplies.clear();
    safetyReports.clear();
    safetyDrafts.clear();
    responses.clear();
    closedPosts.clear();
    editDrafts.clear();
    posts
      ..clear()
      ..addAll(sampleHelp);
    helpDraft = HelpDraft();
  });
}

class DemoScope extends InheritedNotifier<DemoState> {
  const DemoScope({super.key, required DemoState state, required super.child})
    : super(notifier: state);
  static DemoState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DemoScope>()!.notifier!;
}

class Bulletin {
  final String id, title, titleEn, summary, summaryEn, body, bodyEn, date;
  final int category;
  const Bulletin(
    this.id,
    this.title,
    this.titleEn,
    this.summary,
    this.summaryEn,
    this.body,
    this.bodyEn,
    this.date,
    this.category,
  );
}

const bulletins = [
  Bulletin(
    'festival',
    '江東区の防災情報を確認する',
    'Koto City disaster information',
    '避難所の開設状況や区からのお知らせを確認できます。',
    'Check shelter openings and city updates.',
    '避難所の開設状況や、災害時の区からのお知らせは江東区防災ポータルで確認できます。ふだんから大島周辺の防災マップも見ておきましょう。',
    'Use the Koto City disaster portal for shelter openings and official updates. You can also review the disaster maps for the Ojima area in advance.',
    '2026.11.03',
    0,
  ),
  Bulletin(
    'home',
    '在宅避難に備えるチェックリスト',
    'Home preparedness checklist',
    'まずは、おうちの備蓄を見直してみませんか。',
    'Take a moment to review your emergency supplies.',
    '災害に備えて、いつもの暮らしの中でできることを考えてみましょう。\n\n□ 飲料水と食料の備蓄\n□ モバイルバッテリーの充電\n□ 携帯トイレの準備\n□ 家族との連絡方法の確認\n\n在宅避難が可能かどうかは、建物の安全性や周囲の状況によって異なります。実際の災害時は、自治体などの公式情報を確認してください。',
    'Small preparations can be part of everyday life.\n\n□ Check your water and food supplies\n□ Charge a power bank\n□ Prepare emergency toilet supplies\n□ Agree on how to contact family\n\nWhether staying home is safe depends on the building and local conditions. Follow official local guidance during an actual emergency.',
    '2026.11.01',
    1,
  ),
  Bulletin(
    'training',
    '安否確認の練習',
    'Practise reporting your safety',
    '災害時の安否確認を練習します。',
    'Try recording your status before an emergency.',
    '家族と集まる場所を決めたら、ここから安否確認を練習できます。今の状況を選び、内容を確認してから記録します。練習の内容はこの端末に残ります。',
    'Once you have chosen a meeting point with your household, practise reporting your status. Choose your situation, review it, and save it on this device.',
    '2026.10.28',
    2,
  ),
];

class HelpPost {
  final String id, title, titleEn, detail, detailEn;
  final bool request;
  final int building, category;
  final bool own, customTitle;
  final String landmark;
  const HelpPost({
    required this.id,
    required this.title,
    required this.titleEn,
    required this.detail,
    required this.detailEn,
    required this.request,
    required this.building,
    required this.category,
    this.own = false,
    this.landmark = '',
    this.customTitle = false,
  });
}

const sampleHelp = [
  HelpPost(
    id: 'water',
    title: '飲料水を分けてほしい',
    titleEn: 'Could you spare some water?',
    detail:
        '備蓄していた飲料水が不足しています。未開封のお水を少し分けていただけると助かります。\n\n受け渡しは2号棟の入口を希望しています。',
    detailEn:
        'My emergency drinking water is running low. A little unopened water would be a great help.\n\nThe entrance to Building 2 would be a convenient meeting place.',
    request: true,
    building: 2,
    category: 0,
  ),
  HelpPost(
    id: 'english',
    title: '英語での案内を手伝えます',
    titleEn: 'I can help with English',
    detail: '避難情報や団地のお知らせを、英語で説明するお手伝いができます。必要な方はお気軽にお声がけください。',
    detailEn:
        'I can help explain evacuation information and community notices in English. Please feel free to ask.',
    request: false,
    building: 3,
    category: 3,
  ),
  HelpPost(
    id: 'move',
    title: '荷物を運ぶのを手伝えます',
    titleEn: 'Happy to help carry supplies',
    detail: '重い備蓄品などを運ぶお手伝いができます。団地内の短い距離であれば協力できます。',
    detailEn:
        'I can help carry heavy supplies over short distances within the community.',
    request: false,
    building: 1,
    category: 2,
  ),
];

class HelpDraft {
  bool request = true, titleEdited = false, dirty = false;
  int? category, building;
  String title = '', detail = '', landmark = '';
  HelpDraft();
  HelpDraft.fromPost(HelpPost p)
    : request = p.request,
      category = p.category,
      building = p.building,
      title = p.title,
      detail = p.detail,
      landmark = p.landmark,
      titleEdited = p.customTitle;
  bool get hasInput =>
      category != null ||
      building != null ||
      title.isNotEmpty ||
      detail.isNotEmpty ||
      landmark.isNotEmpty ||
      !request;
}

String defaultHelpTitle(bool request, int category, bool english) {
  if (english) {
    return (request
        ? [
            'Could you spare some water?',
            'Could you spare some food?',
            'I need help carrying supplies',
            'I need help with translation',
            'I need a helping hand',
          ]
        : [
            'I can share drinking water',
            'I can share food',
            'I can help carry supplies',
            'I can help translate',
            'I can lend a hand',
          ])[category];
  }
  return (request
      ? [
          '飲料水を分けてほしい',
          '食料を分けてほしい',
          '荷物を運ぶのを手伝ってほしい',
          '翻訳を手伝ってほしい',
          '手伝ってほしいことがあります',
        ]
      : [
          '飲料水を分けられます',
          '食料を分けられます',
          '荷物を運ぶのを手伝えます',
          '翻訳を手伝えます',
          'お手伝いできます',
        ])[category];
}

String draftTitle(DemoState s, HelpDraft d) =>
    d.titleEdited || d.category == null
    ? d.title
    : s.tr(
        defaultHelpTitle(d.request, d.category!, false),
        defaultHelpTitle(d.request, d.category!, true),
      );
String helpCategory(DemoState s, int i) => s.tr(
  ['水', '食料', '移動・運搬', '翻訳', 'その他'][i],
  ['Water', 'Food', 'Carrying', 'Translation', 'Other'][i],
  ['みず', 'たべもの', 'ものを はこぶ', 'ほんやく', 'そのほか'][i],
);
String safetyLabel(DemoState s, int i) => s.tr(
  ['無事です', '助けが必要です', '安全を確認できていません'][i],
  ['I am safe', 'I need help', 'I have not confirmed my safety'][i],
  ['ぶじです', 'たすけてほしいです', 'あんぜんか まだ わかりません'][i],
);
String placeLabel(DemoState s, int i) => s.tr(
  ['自宅', '避難先', '移動中'][i],
  ['At home', 'At a shelter', 'On the move'][i],
  ['いえ', 'にげた ばしょ', 'いどう している'][i],
);
String tagLabel(DemoState s, int i) => s.tr(
  ['けがをしている', '家族と一緒'][i],
  ['Injured', 'With family'][i],
  ['けがを しています', 'かぞくと います'][i],
);
String timeLabel(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
String locationLabel(DemoState s, HelpPost p) =>
    '${s.tr('${p.building}号棟', 'Building ${p.building}')}${p.landmark.isEmpty ? '' : '・${p.landmark}'}';
