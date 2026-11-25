import 'dart:convert';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'mock/demo_state.dart';
import 'post_photos.dart';
import 'room_inspection.dart';

/// Stores the changes made on this device. Navigation and the active practice
/// mode start fresh each time the app opens.
class LocalRecords {
  static const _key = 'state.v1';
  Future<void> _pending = Future.value();

  Future<void> attach(DemoState state) async {
    Set<String> usedPhotoKeys() => {
      ...state.boardPosts.map((post) => post.photoKey).nonNulls,
      for (final inspection in state.roomInspections)
        ...inspection.photos.map((photo) => photo.photoKey),
    };
    late final LazyBox<dynamic> box;
    try {
      await Hive.initFlutter('sonaeai');
      box = await Hive.openLazyBox<dynamic>('sonaeai');
      state.postPhotos = PostPhotos(box);
    } catch (_) {
      state.storageUnavailable = true;
      return;
    }
    try {
      final saved = await box.get(_key) as String?;
      if (saved != null) restore(state, saved);
      final usedPhotos = usedPhotoKeys();
      await box.deleteAll(
        box.keys
            .whereType<String>()
            .where(
              (key) =>
                  key.startsWith(PostPhotos.prefix) &&
                  !usedPhotos.contains(key),
            )
            .toList(),
      );
    } catch (_) {
      state.storageUnavailable = true;
    }

    var queued = encode(state);
    var savedPhotoKeys = usedPhotoKeys();
    state.waitForLocalSaves = () => _pending;
    state.addListener(() {
      final snapshot = encode(state);
      if (snapshot == queued) return;
      queued = snapshot;
      final photoKeys = usedPhotoKeys();
      _pending = _pending.then((_) async {
        var unavailable = false;
        try {
          await box.put(_key, snapshot);
          final unused = savedPhotoKeys.difference(photoKeys);
          if (unused.isNotEmpty) await box.deleteAll(unused);
          savedPhotoKeys = photoKeys;
        } catch (_) {
          unavailable = true;
        }
        if (state.storageUnavailable != unavailable) {
          state.update(() => state.storageUnavailable = unavailable);
        }
      });
    });
  }

  static String encode(DemoState state) => jsonEncode({
    'language': state.language.name,
    'fontScale': state.fontScale,
    'highContrast': state.highContrast,
    'readBulletins': state.readBulletins.toList(),
    'homeChecks': state.homeCheckAnswers.toList(),
    'roomChecks': state.roomCheckAnswers.toList(),
    'roomCheckedAt': state.roomCheckedAt?.toIso8601String(),
    'roomInspections': [
      for (final inspection in state.roomInspections)
        {
          'time': inspection.time.toIso8601String(),
          'photos': [
            for (final photo in inspection.photos)
              {
                'area': photo.area.name,
                'key': photo.photoKey,
                'flagged': photo.flagged,
                'reviewed': photo.reviewed,
              },
          ],
        },
    ],
    'supplies': [
      for (final item in state.supplies)
        {
          'name': item.name,
          'quantity': item.quantity,
          'expiry': item.expiry?.toIso8601String(),
        },
    ],
    'boardPosts': [
      for (final post in state.boardPosts)
        {
          'id': post.id,
          'body': post.body,
          'topic': post.topic.name,
          'place': post.place,
          'time': post.time.toIso8601String(),
          'photoKey': post.photoKey,
        },
    ],
    'assistantQuestions': [
      for (final question in state.assistantQuestions)
        {'topic': question.topic?.name, 'text': question.text},
    ],
    'communityMessages': state.communityMessages,
    'safetyReports': [
      for (final report in state.safetyReports.values)
        {
          'status': report.status,
          'place': report.place,
          'tags': report.tags.toList(),
          'time': report.time.toIso8601String(),
          'drill': report.drill,
        },
    ],
    'helpPosts': [
      for (final post in state.posts.where((post) => post.own))
        {
          'id': post.id,
          'title': post.title,
          'titleEn': post.titleEn,
          'detail': post.detail,
          'request': post.request,
          'building': post.building,
          'category': post.category,
          'landmark': post.landmark,
          'customTitle': post.customTitle,
        },
    ],
    'helpDraft': _encodeDraft(state.helpDraft),
    'editDrafts': state.editDrafts.map(
      (id, draft) => MapEntry(id, _encodeDraft(draft)),
    ),
    'closedPosts': state.closedPosts.toList(),
    'responses': state.responses.map(
      (id, date) => MapEntry(id, date.toIso8601String()),
    ),
    'dailyChecks': state.dailyChecks,
    'lastDailyCheck': state.lastDailyCheck?.toIso8601String(),
    'gameCompleted': state.demoGameCompleted,
  });

  /// Restores an unopened state from the format written by [encode].
  static void restore(DemoState state, String snapshot) {
    final saved = jsonDecode(snapshot) as Map<String, dynamic>;
    final language = _enum(AppLanguage.values, saved['language']);
    final scale = (saved['fontScale'] as num?)?.toDouble();
    final read = _list(saved, 'readBulletins').cast<String>();
    final homeChecks = _items(saved['homeChecks'], 4);
    final roomChecks = _items(saved['roomChecks'], 3);
    final roomInspections = <RoomInspection>[
      for (final entry in _maps(saved, 'roomInspections'))
        if (_date(entry['time']) case final time?)
          (
            time: time,
            photos: [
              for (final photo in _maps(entry, 'photos'))
                if (_enum(RoomArea.values, photo['area']) case final area?)
                  if (photo['key'] case final String key)
                    (
                      area: area,
                      photoKey: key,
                      flagged: photo['flagged'] == true,
                      reviewed: photo['reviewed'] == true,
                    ),
            ],
          ),
    ].where((inspection) => inspection.photos.isNotEmpty);
    final supplies = [
      for (final item in _maps(saved, 'supplies'))
        (
          name: item['name'] as String,
          quantity: item['quantity'] as int,
          expiry: _date(item['expiry']),
        ),
    ];
    final boardPosts = [
      for (final post in _maps(saved, 'boardPosts'))
        if (_date(post['time']) case final time?)
          (
            id: post['id'] as String,
            body: post['body'] as String,
            topic:
                _enum(BoardTopic.values, post['topic']) ??
                BoardTopic.preparedness,
            place: post['place'] as String?,
            time: time,
            photoKey: post['photoKey'] as String?,
          ),
    ];
    final questions = [
      for (final question in _maps(saved, 'assistantQuestions'))
        (
          topic: _enum(AssistantTopic.values, question['topic']),
          text: question['text'] as String,
        ),
    ].where((question) => question.topic != null || question.text.isNotEmpty);
    final reports = [
      for (final report in _maps(saved, 'safetyReports'))
        if (_index(report['status'], 3) case final status?)
          if (_date(report['time']) case final time?)
            SafetyReport(
              status: status,
              place: _index(report['place'], 3),
              tags: _items(report['tags'], 2),
              time: time,
              drill: report['drill'] == true,
            ),
    ];
    final posts = [
      for (final post in _maps(saved, 'helpPosts'))
        if (_index(post['category'], 5) case final category?)
          HelpPost(
            id: post['id'] as String,
            title: post['title'] as String,
            titleEn: post['titleEn'] as String,
            detail: post['detail'] as String,
            detailEn: post['detail'] as String,
            request: post['request'] == true,
            building: post['building'] as int,
            category: category,
            own: true,
            landmark: post['landmark'] as String,
            customTitle: post['customTitle'] == true,
          ),
    ];

    state
      ..language = language ?? AppLanguage.japanese
      ..fontScale = [1.0, 1.3, 1.6].contains(scale) ? scale! : 1.0
      ..highContrast = saved['highContrast'] == true
      ..roomCheckedAt = _date(saved['roomCheckedAt'])
      ..lastDailyCheck = _date(saved['lastDailyCheck'])
      ..dailyChecks = saved['dailyChecks'] as int? ?? 0
      ..demoGameCompleted = saved['gameCompleted'] == true
      ..helpDraft = _decodeDraft(_map(saved, 'helpDraft'));
    state.readBulletins.addAll(read);
    state.homeCheckAnswers.addAll(homeChecks);
    state.roomCheckAnswers.addAll(roomChecks);
    state.roomInspections.addAll(roomInspections);
    state.supplies.addAll(supplies);
    state.boardPosts.addAll(boardPosts);
    state.assistantQuestions.addAll(questions);
    state.communityMessages.addAll(
      _list(saved, 'communityMessages').whereType<String>(),
    );
    state.safetyReports.addEntries(
      reports.map((report) => MapEntry(report.drill, report)),
    );
    state.posts.insertAll(0, posts);
    state.closedPosts.addAll(_list(saved, 'closedPosts').whereType<String>());
    state.editDrafts.addAll(
      _map(saved, 'editDrafts').map(
        (id, draft) =>
            MapEntry(id, _decodeDraft(draft as Map<String, dynamic>)),
      ),
    );
    for (final entry in _map(saved, 'responses').entries) {
      if (_date(entry.value) case final time?) {
        state.responses[entry.key] = time;
      }
    }
  }

  static Map<String, dynamic> _encodeDraft(HelpDraft draft) => {
    'request': draft.request,
    'titleEdited': draft.titleEdited,
    'dirty': draft.dirty,
    'category': draft.category,
    'building': draft.building,
    'title': draft.title,
    'detail': draft.detail,
    'landmark': draft.landmark,
  };

  static HelpDraft _decodeDraft(Map<String, dynamic> draft) => HelpDraft()
    ..request = draft['request'] != false
    ..titleEdited = draft['titleEdited'] == true
    ..dirty = draft['dirty'] == true
    ..category = _index(draft['category'], 5)
    ..building = draft['building'] as int?
    ..title = draft['title'] as String? ?? ''
    ..detail = draft['detail'] as String? ?? ''
    ..landmark = draft['landmark'] as String? ?? '';

  static List<dynamic> _list(Map<String, dynamic> value, String key) =>
      value[key] as List<dynamic>? ?? const [];

  static Map<String, dynamic> _map(Map<String, dynamic> value, String key) =>
      value[key] as Map<String, dynamic>? ?? const {};

  static Iterable<Map<String, dynamic>> _maps(
    Map<String, dynamic> value,
    String key,
  ) => _list(value, key).whereType<Map<String, dynamic>>();

  static T? _enum<T extends Enum>(List<T> values, Object? name) =>
      values.where((value) => value.name == name).firstOrNull;

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static int? _index(Object? value, int length) =>
      value is int && value >= 0 && value < length ? value : null;

  static Set<int> _items(Object? value, int length) =>
      (value as List<dynamic>? ?? const [])
          .whereType<int>()
          .where((i) => i >= 0 && i < length)
          .toSet();
}
