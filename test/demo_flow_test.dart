import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:neo_jichikai/local_records.dart';
import 'package:neo_jichikai/room_inspection.dart';
import 'package:neo_jichikai/screens/room_photo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neo_jichikai/app.dart';
import 'package:neo_jichikai/mock/demo_state.dart';
import 'package:neo_jichikai/screens/home.dart';
import 'package:neo_jichikai/screens/settings.dart';
import 'package:neo_jichikai/screens/onboarding.dart';
import 'package:neo_jichikai/screens/safety.dart';
import 'package:neo_jichikai/screens/bulletins.dart';
import 'package:neo_jichikai/screens/help.dart';
import 'package:neo_jichikai/screens/disaster_chat.dart';
import 'package:neo_jichikai/screens/home_check.dart';
import 'package:neo_jichikai/screens/points.dart';
import 'package:neo_jichikai/screens/preparedness_map.dart';
import 'package:neo_jichikai/screens/resident_board.dart';
import 'package:neo_jichikai/screens/supplies.dart';
import 'package:neo_jichikai/screens/training_game.dart';
import 'package:neo_jichikai/widgets/common.dart';
import 'package:neo_jichikai/widgets/prototype.dart';
import 'package:neo_jichikai/theme/app_theme.dart';

Future<void> start(WidgetTester t, {Size size = const Size(390, 844)}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  await t.pumpWidget(const NeoApp());
  await t.pumpAndSettle();
}

DemoState stateOf(WidgetTester t) =>
    DemoScope.of(t.element(find.byType(HomeShell, skipOffstage: false)));
Future<void> tapTarget(WidgetTester t, Finder target) async {
  await t.ensureVisible(target);
  await t.tap(target);
  await t.pumpAndSettle();
}

Future<void> button(WidgetTester t, String label) =>
    tapTarget(t, find.widgetWithText(AppButton, label).last);
Future<void> text(WidgetTester t, String label) =>
    tapTarget(t, find.text(label).last);
Future<void> tab(WidgetTester t, int i) =>
    tapTarget(t, find.byKey(ValueKey('tab-$i')));
Future<void> back(WidgetTester t) => tapTarget(t, find.byTooltip('戻る').last);
Future<void> settings(WidgetTester t) =>
    tapTarget(t, find.byKey(const ValueKey('home-settings')));
Future<void> help(WidgetTester t) async {
  stateOf(t).setEmergency(true);
  await t.pumpAndSettle();
  await text(t, '助け合いを見る');
}

Future<void> enter(WidgetTester t, int i, String value) async {
  final field = find.byType(TextFormField).at(i);
  await t.ensureVisible(field);
  await t.enterText(field, value);
  await t.pumpAndSettle();
}

Future<void> createDraft(
  WidgetTester t, {
  String title = '飲料水を1本分けてほしい',
}) async {
  await text(t, '水');
  await enter(t, 0, title);
  final field = find.byType(DropdownButtonFormField<int>);
  await tapTarget(t, field);
  await text(t, '2号棟');
  await enter(t, 1, '入口付近');
  await enter(t, 2, '未開封の2Lを1本希望しています。');
}

void main() {
  setUpAll(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDownAll(() => WidgetController.hitTestWarningShouldBeFatal = false);
  testWidgets('opens home directly and language is reachable from settings', (
    t,
  ) async {
    await start(t);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(BulletinListScreen), findsNothing);
    expect(find.text('そなえあい'), findsOneWidget);
    await settings(t);
    await tapTarget(t, find.widgetWithText(ChoiceTile, 'English'));
    expect(stateOf(t).language, AppLanguage.english);
    await tapTarget(t, find.byTooltip('Back'));
    expect(find.text('Home preparedness check'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('feature-menu')).hitTestable(),
      findsOneWidget,
    );
    await tapTarget(t, find.byKey(const ValueKey('feature-menu')));
    expect(stateOf(t).tab, DemoState.menuTab);
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(stateOf(t).tab, 0);
  });

  testWidgets('safety and access to help are limited to emergency mode', (
    t,
  ) async {
    await start(t);
    final safetyTab = find.byKey(const ValueKey('tab-2'));
    final safetyCard = find.widgetWithText(TextButton, '安否を報告する');
    final helpTab = find.byKey(const ValueKey('tab-3'));
    final helpLink = find.text('助け合いを見る');
    expect(safetyTab, findsNothing);
    expect(safetyCard, findsNothing);
    expect(helpLink, findsNothing);
    await settings(t);
    await tapTarget(t, find.widgetWithText(ChoiceTile, '非常時の訓練'));
    await back(t);
    expect(safetyTab.hitTestable(), findsOneWidget);
    expect(safetyCard.hitTestable(), findsOneWidget);
    expect(helpTab, findsNothing);
    await tapTarget(t, helpLink);
    expect(find.byType(HelpListScreen), findsOneWidget);
    await tapTarget(t, find.byTooltip('ホームに戻る'));
    await tab(t, 2);
    expect(find.byType(SafetyScreen), findsOneWidget);
    await text(t, '通常時に戻す');
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(safetyTab, findsNothing);
    expect(safetyCard, findsNothing);
    expect(helpLink, findsNothing);
  });

  testWidgets(
    'home scrolls its header with the content and stops at the top',
    (t) async {
      await start(t, size: const Size(390, 700));
      stateOf(t).setEmergency(true);
      await t.pumpAndSettle();
      final safetyButton = find.widgetWithText(TextButton, '安否を報告する');
      final header = find.text('大島六丁目団地');
      final initialTop = t.getTopLeft(safetyButton).dy;
      final initialHeaderTop = t.getTopLeft(header).dy;
      final pull = await t.startGesture(t.getCenter(safetyButton));
      await pull.moveBy(const Offset(0, 25));
      await pull.moveBy(const Offset(0, 240));
      await t.pump();
      final pulledTop = t.getTopLeft(safetyButton).dy;
      await pull.up();
      await t.pumpAndSettle();

      expect(pulledTop, closeTo(initialTop, 1));

      await t.drag(safetyButton, const Offset(0, -180));
      await t.pumpAndSettle();
      final cardTravel = initialTop - t.getTopLeft(safetyButton).dy;
      expect(cardTravel, greaterThan(0));
      expect(
        initialHeaderTop - t.getTopLeft(header).dy,
        closeTo(cardTravel, 1),
      );
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.iOS,
      TargetPlatform.macOS,
    }),
  );

  testWidgets(
    'safety selection remains editable and reports only after confirmation',
    (t) async {
      await start(t);
      stateOf(t).setEmergency(true);
      await t.pumpAndSettle();
      await text(t, '安否を報告する');
      await tapTarget(t, find.widgetWithText(ChoiceTile, '助けが必要です'));
      expect(find.byType(SafetyConfirmScreen), findsNothing);
      expect(stateOf(t).safetyReport(), isNull);
      await text(t, '場所・補足を追加（任意）');
      await text(t, '自宅');
      await text(t, '避難先');
      await text(t, 'けがをしている');
      expect(stateOf(t).safetyDraft().place, 1);
      expect(stateOf(t).safetyDraft().tags, {0});
      await button(t, '報告内容を確認する');
      expect(stateOf(t).safetyReport(), isNull);
      await button(t, '内容を変更する');
      expect(stateOf(t).safetyDraft().status, 1);
      expect(stateOf(t).safetyDraft().place, 1);
      await button(t, '報告内容を確認する');
      final confirm = find.widgetWithText(AppButton, 'この内容で記録する');
      await t.tap(confirm);
      await t.tap(confirm, warnIfMissed: false);
      await t.pumpAndSettle();
      expect(stateOf(t).safetyReport()!.status, 1);
      expect(stateOf(t).safetyReport()!.tags, {0});
      expect(find.byType(SafetyResultScreen), findsOneWidget);
      await button(t, '内容を変更する');
      await tapTarget(t, find.widgetWithText(ChoiceTile, '無事です'));
      expect(stateOf(t).safetyDraft().tags, isEmpty);
      expect(stateOf(t).safetyReport()!.status, 1);
      await button(t, '報告内容を確認する');
      await button(t, 'この内容で記録する');
      expect(stateOf(t).safetyReport()!.status, 0);
      await button(t, 'ホームに戻る');
      expect(find.text('報告済み'), findsOneWidget);
      await settings(t);
      await button(t, '安否確認の訓練を開く');
      expect(find.byType(SafetyDrillScreen), findsOneWidget);
      expect(stateOf(t).safetyReport(drill: true), isNull);
      expect(stateOf(t).safetyDraft(drill: true).status, isNull);
      expect(stateOf(t).safetyReport()!.status, 0);
    },
  );

  testWidgets(
    'read action stays visible, can be undone, and supports the next unread item',
    (t) async {
      await start(t);
      await tab(t, 1);
      await text(t, '回覧板');
      await text(t, '未確認のみ');
      await tapTarget(t, find.widgetWithText(BulletinCard, '在宅避難に備えるチェックリスト'));
      final confirm = find.widgetWithText(AppButton, '確認済みにする');
      expect(confirm.hitTestable(), findsOneWidget);
      await button(t, '確認済みにする');
      expect(stateOf(t).readBulletins, contains('home'));
      await t.pump(const Duration(seconds: 10));
      await text(t, '未確認に戻す');
      expect(stateOf(t).readBulletins, isEmpty);
      await button(t, '確認済みにする');
      await button(t, '次の未確認を見る');
      expect(find.text('江東区の防災情報を確認する'), findsOneWidget);
      await button(t, '確認済みにする');
      await button(t, '次の未確認を見る');
      await button(t, '確認済みにする');
      await button(t, '回覧板一覧に戻る');
      expect(find.byType(BulletinCard), findsNWidgets(3));
      await text(t, '未確認のみ');
      expect(find.text('未確認のお知らせはありません'), findsOneWidget);
      await button(t, 'すべてのお知らせを見る');
      expect(find.byType(BulletinCard), findsNWidgets(3));
    },
  );

  testWidgets('help has an explicit empty state and filters can be cleared', (
    t,
  ) async {
    await start(t);
    await help(t);
    await tapTarget(t, find.byType(DropdownButtonFormField<int>));
    await text(t, '食料');
    expect(find.text('この条件の投稿はありません'), findsOneWidget);
    await button(t, '絞り込みを解除する');
    expect(find.byType(HelpCard), findsNWidgets(3));
    await text(t, '自分の投稿');
    expect(find.text('自分の投稿はありません'), findsOneWidget);
    expect(
      find.widgetWithText(AppButton, '助け合いを投稿する').hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets(
    'draft survives going back, review is editable and posting is not duplicated',
    (t) async {
      await start(t);
      await help(t);
      await button(t, '助け合いを投稿する');
      await button(t, '内容を確認する');
      expect(find.text('内容を1つ選んでください。'), findsOneWidget);
      await createDraft(t);
      await back(t);
      expect(stateOf(t).helpDraft.title, '飲料水を1本分けてほしい');
      expect(stateOf(t).helpDraft.landmark, '入口付近');
      expect(stateOf(t).helpDraft.detail, '未開封の2Lを1本希望しています。');
      await button(t, '下書きの続きを入力する');
      expect(
        t
            .widget<TextFormField>(find.byType(TextFormField).at(1))
            .controller!
            .text,
        '入口付近',
      );
      await button(t, '内容を確認する');
      expect(stateOf(t).posts.length, 3);
      await button(t, '内容を修正する');
      expect(
        t
            .widget<TextFormField>(find.byType(TextFormField).at(2))
            .controller!
            .text,
        '未開封の2Lを1本希望しています。',
      );
      await button(t, '内容を確認する');
      final submit = find.widgetWithText(AppButton, 'この内容で投稿する');
      await t.tap(submit);
      await t.tap(submit, warnIfMissed: false);
      await t.pumpAndSettle();
      expect(stateOf(t).posts.length, 4);
      expect(stateOf(t).helpDraft.hasInput, isFalse);
      expect(find.byType(PostSavedScreen), findsOneWidget);
      expect(find.byType(HelpPostScreen, skipOffstage: false), findsNothing);
      expect(
        find.byType(HelpPostReviewScreen, skipOffstage: false),
        findsNothing,
      );
      await button(t, '投稿した内容を見る');
      expect(find.text('飲料水を1本分けてほしい'), findsOneWidget);
      expect(find.text('場所: 2号棟・入口付近'), findsOneWidget);
    },
  );

  testWidgets('own posts can be edited, closed, found again and reopened', (
    t,
  ) async {
    await start(t);
    await help(t);
    await button(t, '助け合いを投稿する');
    await createDraft(t);
    await button(t, '内容を確認する');
    await button(t, 'この内容で投稿する');
    await button(t, '投稿した内容を見る');
    final id = stateOf(t).posts.first.id;
    await button(t, '投稿を編集する');
    expect(find.text('下書きを破棄する'), findsNothing);
    expect(
      t.widget<AppButton>(find.widgetWithText(AppButton, '内容を確認する')).onPressed,
      isNull,
    );
    await enter(t, 0, '飲料水を2本分けてほしい');
    await button(t, '内容を確認する');
    await button(t, '変更を保存する');
    await button(t, '投稿した内容を見る');
    expect(stateOf(t).postById(id).title, '飲料水を2本分けてほしい');
    expect(stateOf(t).posts.length, 4);
    await button(t, '募集を終了する');
    await button(t, '募集を終了する');
    expect(stateOf(t).closedPosts, contains(id));
    expect(find.text('募集終了'), findsOneWidget);
    await back(t);
    expect(stateOf(t).helpFilter, 3);
    expect(find.text('募集終了'), findsOneWidget);
    await tapTarget(t, find.widgetWithText(HelpCard, '飲料水を2本分けてほしい'));
    await button(t, '募集を再開する');
    expect(stateOf(t).closedPosts, isEmpty);
  });

  for (final request in [true, false]) {
    testWidgets(
      'a ${request ? 'help offer' : 'help request'} can be reviewed and cancelled',
      (t) async {
        await start(t);
        await help(t);
        await tapTarget(
          t,
          find.widgetWithText(
            HelpCard,
            request ? '飲料水を分けてほしい' : '英語での案内を手伝えます',
          ),
        );
        final action = request ? '協力を申し出る' : '手伝いをお願いする';
        await button(t, action);
        await button(t, 'やめる');
        expect(stateOf(t).responses, isEmpty);
        await button(t, action);
        await button(t, request ? '申し出を記録' : '依頼を記録');
        expect(stateOf(t).responses, contains(request ? 'water' : 'english'));
        expect(find.byType(ResponseResultScreen), findsOneWidget);
        await button(t, '投稿の内容に戻る');
        await button(t, request ? '申し出を取り消す' : '依頼を取り消す');
        await button(t, '取り消す');
        expect(stateOf(t).responses, isEmpty);
        expect(find.widgetWithText(AppButton, action), findsOneWidget);
      },
    );
  }

  testWidgets(
    'a need-help report leads to offers without overwriting a draft',
    (t) async {
      await start(t);
      final s = stateOf(t);
      s.setEmergency(true);
      s.update(() {
        s.helpDraft.request = false;
        s.helpDraft.detail = 'Keep this offer draft';
      });
      await t.pumpAndSettle();
      await tab(t, 2);
      await tapTarget(t, find.widgetWithText(ChoiceTile, '助けが必要です'));
      await button(t, '報告内容を確認する');
      await button(t, 'この内容で記録する');
      await button(t, '手伝える人の投稿を見る');
      expect(s.tab, 3);
      expect(s.helpFilter, 2);
      expect(s.safetyReport()!.status, 1);
      expect(s.helpDraft.request, isFalse);
      expect(s.helpDraft.detail, 'Keep this offer draft');
      expect(find.text('英語での案内を手伝えます'), findsOneWidget);
    },
  );

  testWidgets(
    'a drill report returns to the notice without activating emergency mode',
    (t) async {
      await start(t);
      final s = stateOf(t);
      s.update(() => s.safetyDraft().status = 0);
      s.saveSafety();
      await t.pumpAndSettle();
      await tab(t, 1);
      await text(t, '回覧板');
      await tapTarget(t, find.widgetWithText(BulletinCard, '安否確認の練習'));
      await button(t, '訓練モードで安否確認へ');
      expect(find.byType(SafetyDrillScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey('tab-2'), skipOffstage: false),
        findsNothing,
      );
      await tapTarget(t, find.widgetWithText(ChoiceTile, '助けが必要です'));
      await button(t, '報告内容を確認する');
      await button(t, 'この内容で記録する');
      await button(t, '訓練を終える');
      expect(find.byType(BulletinDetailScreen), findsOneWidget);
      expect(s.tab, 1);
      expect(s.isEmergency, isFalse);
      expect(s.safetyReport(drill: true)!.status, 1);
      expect(s.safetyReport()!.status, 0);
      expect(s.readBulletins.contains('training'), isFalse);
    },
  );

  testWidgets('demo reset preserves accessibility and language preferences', (
    t,
  ) async {
    await start(t);
    final s = stateOf(t);
    s.setEmergency(true);
    s.update(() {
      s.language = AppLanguage.english;
      s.fontScale = 1.3;
      s.highContrast = true;
      s.readBulletins.add('home');
      s.helpDraft.detail = 'Draft';
    });
    await t.pumpAndSettle();
    await settings(t);
    expect(
      Theme.of(t.element(find.byType(SettingsScreen))).colorScheme.outline,
      ink,
    );
    await button(t, 'Clear local records');
    await button(t, 'Reset records');
    expect(s.language, AppLanguage.english);
    expect(s.fontScale, 1.3);
    expect(s.highContrast, isTrue);
    expect(s.isEmergency, isTrue);
    expect(s.readBulletins, isEmpty);
    expect(s.helpDraft.hasInput, isFalse);
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('review action remains above the keyboard on the post form', (
    t,
  ) async {
    await start(t);
    await help(t);
    await button(t, '助け合いを投稿する');
    t.view.viewInsets = const FakeViewPadding(bottom: 320);
    addTearDown(t.view.resetViewInsets);
    await t.pumpAndSettle();
    final action = find.widgetWithText(AppButton, '内容を確認する');
    expect(t.getBottomRight(action).dy, lessThanOrEqualTo(524));
    expect(action.hitTestable(), findsOneWidget);
  });

  testWidgets(
    'the feature menu opens each everyday demo and returns to the menu',
    (t) async {
      await start(t);
      await tapTarget(t, find.byKey(const ValueKey('feature-menu')));
      expect(find.byType(FeatureLink), findsNWidgets(8));
      for (final (label, screen) in <(String, Type)>[
        ('ハザードマップ', PreparednessMapScreen),
        ('備蓄品管理', SuppliesScreen),
        ('自宅の防災診断', HomeCheckScreen),
        ('そなAI', DisasterChatScreen),
        ('防災ゲーム', TrainingGameScreen),
        ('ポイント・ランキング', PointsScreen),
      ]) {
        await tapTarget(t, find.widgetWithText(FeatureLink, label));
        expect(find.byType(screen), findsOneWidget);
        switch (label) {
          case 'そなAI':
            await tapTarget(t, find.widgetWithText(ActionChip, '備蓄の見直し'));
            expect(find.textContaining('備蓄品管理では'), findsOneWidget);
          case '自宅の防災診断':
            expect(find.text('点検を始める'), findsOneWidget);
            expect(find.text('過去のAI点検サンプル'), findsOneWidget);
            expect(find.byType(CheckboxListTile), findsNothing);
          case 'ハザードマップ':
            expect(find.byType(TextField), findsNothing);
            expect(find.widgetWithText(ListTile, '第四大島小学校'), findsOneWidget);
            await text(t, '洪水');
            expect(find.textContaining('想定最大規模の洪水'), findsOneWidget);
            expect(find.widgetWithText(ListTile, 'UR大島六丁目団地'), findsOneWidget);
            expect(find.widgetWithText(ListTile, '第四大島小学校'), findsNothing);
            await text(t, '地震');
            final shelter = find.widgetWithText(ListTile, '第四大島小学校');
            expect(shelter, findsOneWidget);
            await tapTarget(t, shelter);
            expect(find.text('地図アプリで経路を開く'), findsOneWidget);
            await text(t, '閉じる');
        }
        await back(t);
        expect(find.byType(FeatureLink), findsNWidgets(8));
      }
    },
  );

  testWidgets(
    'the home floating button opens the assistant and keeps its conversation',
    (t) async {
      await start(t, size: const Size(360, 740));
      final assistant = find.byKey(const ValueKey('open-assistant'));
      expect(assistant.hitTestable(), findsOneWidget);
      expect(
        t.widget<FloatingActionButton>(assistant).shape,
        isA<CircleBorder>(),
      );
      expect(
        t.getBottomRight(assistant).dy,
        lessThan(t.getTopLeft(find.byKey(const ValueKey('tab-0'))).dy),
      );
      await tapTarget(t, assistant);
      expect(find.byType(TextField).hitTestable(), findsOneWidget);
      await tapTarget(t, find.widgetWithText(ActionChip, '備蓄の見直し'));
      expect(find.textContaining('備蓄品管理では'), findsOneWidget);
      await text(t, '備蓄品管理を開く');
      expect(find.byType(SuppliesScreen), findsOneWidget);
      await back(t);
      expect(find.textContaining('備蓄品管理では'), findsOneWidget);
      await back(t);
      expect(find.byType(HomeScreen), findsOneWidget);
      await tapTarget(t, assistant);
      expect(find.textContaining('備蓄品管理では'), findsOneWidget);
      await t.enterText(find.byType(TextField).hitTestable(), '自宅の家具を確認したい');
      await t.pumpAndSettle();
      await tapTarget(t, find.byTooltip('質問する'));
      expect(find.text('自宅の防災診断を開く'), findsOneWidget);
    },
  );

  testWidgets('home search finds the hazard map and returns to the search', (
    t,
  ) async {
    await start(t);
    await tapTarget(t, find.byKey(const ValueKey('feature-menu')));
    final query = find.byKey(const ValueKey('feature-query'));
    await t.enterText(query, 'ハザード');
    await t.pumpAndSettle();
    expect(find.byType(FeatureLink), findsOneWidget);
    await tapTarget(t, find.widgetWithText(FeatureLink, 'ハザードマップ'));
    expect(find.byType(PreparednessMapScreen), findsOneWidget);
    await back(t);
    expect(find.byType(FeatureLink), findsOneWidget);
    await tapTarget(t, find.byTooltip('検索をクリア'));
    expect(find.byType(FeatureLink), findsNWidgets(8));
  });

  testWidgets(
    'posts saved in the earlier categories can still be opened and edited',
    (t) async {
      await start(t);
      final state = stateOf(t);
      state.update(() {
        LocalRecords.restore(
          state,
          jsonEncode({
            'boardPosts': [
              {
                'id': 'saved-drill',
                'topic': 'drill',
                'body': '集合場所を確認しました。',
                'time': '2026-11-21T18:00:00',
                'photoKey': 'post/photo/legacy-drill',
              },
              {
                'id': 'saved-preparedness',
                'topic': 'preparedness',
                'body': '持ち出し袋を入れ替えました。',
                'time': '2026-11-21T17:00:00',
              },
            ],
          }),
        );
      });
      await tab(t, 1);
      expect(find.text('持ち出し袋を入れ替えました。'), findsOneWidget);
      expect(find.text('訓練・避難'), findsNothing);
      expect(find.text('備え'), findsNothing);
      await text(t, '集合場所を確認しました。');
      expect(find.text('共有する'), findsOneWidget);
      await text(t, '編集する');
      expect(find.byType(TextFormField), findsOneWidget);
      await enter(t, 0, '集合場所を家族と確認しました。');
      await button(t, '変更を保存');
      expect(find.text('集合場所を家族と確認しました。'), findsOneWidget);
      expect(state.boardPosts.first.topic, BoardTopic.drill);
      expect(state.boardPosts.first.photoKey, 'post/photo/legacy-drill');
      await back(t);
      expect(find.text('集合場所を家族と確認しました。'), findsOneWidget);
    },
  );

  testWidgets(
    'the support demo opens the request form with the selected category',
    (t) async {
      await start(t);
      await help(t);
      await tapTarget(t, find.widgetWithText(OutlinedButton, '支援を依頼する'));
      await tapTarget(t, find.widgetWithText(ChoiceTile, '水'));
      await button(t, '依頼の入力へ');
      expect(find.byType(HelpPostScreen), findsOneWidget);
      expect(stateOf(t).helpDraft.category, 0);
      expect(stateOf(t).helpDraft.request, isTrue);
    },
  );

  testWidgets('emergency home shows contacts and can report safe in one tap', (
    t,
  ) async {
    await start(t);
    expect(find.text('家族・知人の安否を見る'), findsNothing);
    stateOf(t).setEmergency(true);
    await t.pumpAndSettle();
    await text(t, '家族・知人の安否を見る');
    expect(find.byType(SafetyContactsScreen), findsOneWidget);
    expect(find.text('母'), findsOneWidget);
    expect(find.text('まだ報告がありません'), findsOneWidget);
    await back(t);
    await text(t, '無事と記録する');
    expect(find.text('安否を記録しました'), findsOneWidget);
    expect(stateOf(t).safetyReport()?.status, 0);
    expect(find.text('この記録は端末内に保存されます。'), findsOneWidget);
    await text(t, '家族・知人の安否を見る');
    await button(t, '助け合いを見る');
    expect(find.byType(HelpListScreen), findsOneWidget);
    expect(find.text('支援を依頼する'), findsOneWidget);
    await back(t);
    expect(find.byType(SafetyContactsScreen), findsOneWidget);
    await back(t);
    expect(find.text('安否を記録しました'), findsOneWidget);
  });

  testWidgets('the flood answer opens a temporary flood refuge', (t) async {
    await start(t);
    await tapTarget(t, find.byKey(const ValueKey('open-assistant')));
    await t.enterText(find.byType(TextField).hitTestable(), '地震が起きた直後はどうする？');
    await t.pumpAndSettle();
    await tapTarget(t, find.byTooltip('質問する'));
    expect(find.textContaining('頭と体を守ります'), findsOneWidget);
    await t.enterText(find.byType(TextField).hitTestable(), '夜間にどう避難すればいいですか？');
    await t.pumpAndSettle();
    await tapTarget(t, find.byTooltip('質問する'));
    expect(find.textContaining('災害の種類に合った避難場所'), findsOneWidget);
    await t.enterText(find.byType(TextField).hitTestable(), '洪水ではどこへ行きますか？');
    await t.pumpAndSettle();
    await tapTarget(t, find.byTooltip('質問する'));
    await text(t, '洪水の地図を開く');
    expect(find.textContaining('想定最大規模の洪水'), findsOneWidget);
    await tapTarget(t, find.widgetWithText(ListTile, 'UR大島六丁目団地'));
    expect(find.text('江東区の利用条件を確認'), findsOneWidget);
    expect(find.text('3階以上の共用部（屋上を除く）'), findsOneWidget);
  });

  testWidgets(
    'the diagnosis links to supplies and a sample can be copied into a new item',
    (t) async {
      await start(t);
      await tab(t, DemoState.homeCheckTab);
      await text(t, '備蓄品管理');
      expect(stateOf(t).supplies, isEmpty);
      await text(t, '期限が近い・期限切れ');
      expect(find.text('携帯トイレ'), findsNothing);
      await text(t, '飲料水 2L');
      expect(find.text('この品目を削除'), findsNothing);
      await enter(t, 0, '検証用非常食');
      await enter(t, 1, '2');
      await button(t, '保存する');
      expect(find.text('検証用非常食'), findsOneWidget);
      await back(t);
      await text(t, '備蓄品管理');
      expect(find.text('検証用非常食'), findsOneWidget);
    },
  );

  testWidgets('hazards ask for the place and keep it visible on the timeline', (
    t,
  ) async {
    await start(t);
    await text(t, '危険箇所を確認する');
    expect(find.byType(FilterTabs), findsNothing);
    expect(find.text('投稿例'), findsOneWidget);
    await button(t, '危険箇所を投稿');
    expect(find.byType(FilterTabs), findsNothing);
    await enter(t, 1, '手すりがぐらついています。');
    await button(t, '投稿する');
    expect(find.text('場所を入力してください'), findsOneWidget);
    await enter(t, 0, '公園側の階段');
    await button(t, '投稿する');
    expect(stateOf(t).boardPosts.single.topic, BoardTopic.hazard);
    expect(find.text('公園側の階段'), findsOneWidget);
    await text(t, '手すりがぐらついています。');
    expect(find.text('公園側の階段'), findsOneWidget);
  });

  final testPhoto = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jL1sAAAAASUVORK5CYII=',
  );

  testWidgets(
    'inspection guides each photo and retains results when a second inspection is saved',
    (t) async {
      await start(t);
      final sources = <ImageSource>[];
      RoomPhotoScreen flow() => RoomPhotoScreen(
        selectPhoto: (source) async {
          sources.add(source);
          return sources.length == 2 ? null : testPhoto;
        },
        analyzePhoto: (_) async => [0, 1, 2],
      );
      await tab(t, DemoState.homeCheckTab);
      openPage(t.element(find.byType(HomeShell)), flow());
      await t.pumpAndSettle();
      expect(find.text('撮影 1 / 3'), findsOneWidget);
      await button(t, '写真を撮る');
      await button(t, '撮り直す');
      expect(sources, [ImageSource.camera, ImageSource.camera]);
      expect(find.byType(Image), findsOneWidget);
      await button(t, 'この写真で次へ');
      expect(find.text('出入口と通路'), findsOneWidget);
      await back(t);
      expect(find.text('撮り直す'), findsOneWidget);
      await button(t, 'この写真で次へ');
      await button(t, '写真を選ぶ');
      await button(t, 'この写真で次へ');
      expect(find.text('棚の上と収納'), findsOneWidget);
      await button(t, '写真を撮る');
      await button(t, '3枚の写真を判定する');
      expect(find.text('確認 1 / 3'), findsOneWidget);
      expect(find.text('AIが挙げた確認箇所'), findsOneWidget);
      await button(t, '確認した');
      await button(t, 'あとで確認');
      await button(t, '確認済みにして保存');

      final state = stateOf(t);
      final saved = state.roomInspections.single;
      expect(saved.photos.map((photo) => photo.area), RoomArea.values);
      expect(saved.photos.map((photo) => photo.reviewed), [true, false, true]);
      expect(saved.photos.map((photo) => photo.photoKey).toSet(), hasLength(3));
      for (final photo in saved.photos) {
        expect(await state.postPhotos.read(photo.photoKey), testPhoto);
      }
      await tapTarget(t, find.textContaining('前回の点検'));
      expect(find.byType(InspectionPicture), findsOneWidget);
      await button(t, '次の写真');
      expect(find.text('出入口と通路'), findsOneWidget);
      await tapTarget(t, find.widgetWithText(CheckboxListTile, 'この箇所を確認した'));
      expect(state.roomInspections.single.photos[1].reviewed, isTrue);
      await back(t);

      openPage(t.element(find.byType(HomeShell)), flow());
      await t.pumpAndSettle();
      for (var photo = 0; photo < 3; photo++) {
        await button(t, '写真を撮る');
        await button(t, photo == 2 ? '3枚の写真を判定する' : 'この写真で次へ');
      }
      await button(t, '確認した');
      await button(t, '確認した');
      state.waitForLocalSaves = () async => state.storageUnavailable = true;
      await button(t, '確認済みにして保存');
      expect(find.textContaining('写真を保存できませんでした'), findsOneWidget);
      expect(state.roomInspections, hasLength(1));
      state.waitForLocalSaves = () async => state.storageUnavailable = false;
      await button(t, '確認済みにして保存');
      expect(state.roomInspections, hasLength(2));
      expect(
        state.roomInspections.last.photos[0].photoKey,
        saved.photos[0].photoKey,
      );
      expect(await state.postPhotos.read(saved.photos[0].photoKey), testPhoto);
    },
  );

  testWidgets(
    'photo posts can be previewed and edited without losing the attachment',
    (t) async {
      await start(t, size: const Size(360, 800));
      t.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      openPage(
        t.element(find.byType(HomeShell)),
        ResidentBoardScreen(selectPhoto: (_) async => testPhoto),
      );
      await t.pumpAndSettle();
      await button(t, '危険箇所を投稿');
      await enter(t, 0, '西側の入口');
      await enter(t, 1, '植木鉢が倒れています。');
      await text(t, '写真を追加');
      await text(t, '写真を選ぶ');
      expect(find.byType(Image), findsOneWidget);
      await back(t);
      await button(t, 'やめる');
      expect(find.byType(Image), findsOneWidget);
      await button(t, '投稿する');
      final state = stateOf(t);
      final post = state.boardPosts.single;
      expect(await state.postPhotos.read(post.photoKey!), testPhoto);
      await text(t, '植木鉢が倒れています。');
      expect(find.byType(Image), findsOneWidget);
      await text(t, '編集する');
      await enter(t, 1, '植木鉢が片付きました。');
      await button(t, '変更を保存');
      expect(state.boardPosts.single.photoKey, post.photoKey);
      expect(state.boardPosts.single.body, '植木鉢が片付きました。');
      await text(t, '削除する');
      await button(t, '削除する');
      expect(state.boardPosts, isEmpty);
    },
  );

  testWidgets('the map displays the returned position and shelter distance', (
    t,
  ) async {
    await start(t);
    openPage(
      t.element(find.byType(HomeShell)),
      PreparednessMapScreen(
        locate: () async => const LatLng(35.69095, 139.83460),
      ),
    );
    await t.pumpAndSettle();
    await text(t, '現在地');
    await tapTarget(t, find.byTooltip('第四大島小学校'));
    expect(find.textContaining('現在地から直線で'), findsOneWidget);
  });

  test('local records restore personal work and launch on the normal home', () {
    final old = DemoState()
      ..setEmergency(true)
      ..selectTab(DemoState.safetyTab)
      ..reportSafe()
      ..checkIn()
      ..checkIn();
    old.homeCheckAnswers.add(0);
    old.roomCheckAnswers.addAll([0, 1]);
    old.roomCheckedAt = DateTime(2026, 11, 22);
    old.roomInspections.add((
      time: DateTime(2026, 11, 23),
      photos: [
        (
          area: RoomArea.tallFurniture,
          photoKey: 'post/photo/inspection',
          flagged: true,
          reviewed: false,
        ),
      ],
    ));
    old.supplies.add((name: '乾電池', quantity: 2, expiry: null));
    old.readBulletins.add('home');
    old.boardPosts.add((
      id: 'post-1',
      topic: BoardTopic.hazard,
      body: '手すりを点検してください。',
      place: '南側階段',
      time: DateTime(2026, 11, 22),
      photoKey: 'post/photo/test',
    ));
    final restored = DemoState();
    LocalRecords.restore(restored, LocalRecords.encode(old));
    expect(LocalRecords.encode(restored), LocalRecords.encode(old));
    expect(restored.isEmergency, isFalse);
    expect(restored.tab, 0);
    expect(restored.dailyChecks, 1);
  });

  for (final width in [360.0, 390.0]) {
    for (final language in AppLanguage.values) {
      testWidgets('all flows at ${width.toInt()}px / $language / 200% text', (
        t,
      ) async {
        await start(t, size: Size(width, 800));
        final s = stateOf(t);
        s.setEmergency(true);
        t.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        s.update(() {
          s.language = language;
          s.highContrast = true;
          s.safetyDraft().status = 1;
          s.safetyDraft().place = 0;
          s.safetyDraft().tags.add(0);
        });
        s.saveSafety();
        final draft = HelpDraft()
          ..category = 0
          ..building = 2
          ..title = 'Water'
          ..detail = 'Sample details';
        final own = s.commitPost(draft);
        s.update(() {
          s.responses['water'] = DateTime.now();
          s.readBulletins.add(bulletins.first.id);
        });
        await t.pumpAndSettle();
        for (var i = 0; i <= DemoState.homeCheckTab; i++) {
          s.selectTab(i);
          await t.pumpAndSettle();
          final scroll = find
              .byWidgetPredicate(
                (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
              )
              .hitTestable()
              .first;
          await t.drag(scroll, const Offset(0, -1800));
          await t.pumpAndSettle();
        }
        for (final page in <Widget>[
          const SafetyConfirmScreen(),
          const SafetyDrillScreen(),
          const SafetyResultScreen(justSaved: true),
          const HelpPostScreen(),
          HelpPostReviewScreen(draft: draft),
          const HelpDetailScreen(postId: 'water'),
          HelpDetailScreen(postId: own.id),
          const ResponseResultScreen(postId: 'water'),
          PostSavedScreen(postId: own.id),
          BulletinDetailScreen(bulletin: bulletins.first),
          const SettingsScreen(),
          const OnboardingScreen(),
          const ResidentBoardScreen(),
          const DisasterChatScreen.community(),
          const DisasterChatScreen.assistant(),
          const PreparednessMapScreen(),
          const SuppliesScreen(),
          const HomeCheckScreen(),
          const RoomPhotoScreen(),
          const TrainingGameScreen(),
          const PointsScreen(),
        ]) {
          openPage(t.element(find.byType(HomeShell)), page);
          await t.pumpAndSettle();
          final scroll = find
              .byWidgetPredicate(
                (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
              )
              .hitTestable()
              .first;
          await t.drag(scroll, const Offset(0, -2500));
          await t.pumpAndSettle();
          Navigator.of(
            t.element(find.byType(HomeShell, skipOffstage: false)),
          ).pop();
          await t.pumpAndSettle();
        }
      });
    }
  }
}
