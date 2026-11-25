import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../mock/demo_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'bulletins.dart';
import 'disaster_chat.dart';
import 'feature_menu.dart';
import 'help.dart';
import 'home_check.dart';
import 'preparedness_map.dart';
import 'resident_board.dart';
import 'safety.dart';
import 'settings.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  bool _mapOpened = false;

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final isHome = s.tab == 0;
    _mapOpened = _mapOpened || s.tab == DemoState.mapTab;
    final isSecondary =
        s.tab == DemoState.helpTab || s.tab == DemoState.menuTab;
    final titles = [
      'そなえあい',
      s.tr('防災共有', 'Community updates', 'ぼうさいの おしらせ'),
      s.tr('安否確認', 'Safety check', 'ぶじの かくにん'),
      s.tr('助け合い', 'Help', 'たすけあい'),
      s.tr('機能一覧', 'Explore features', 'きのうの メニュー'),
      s.tr('ハザードマップ', 'Hazard map', 'きけんな ばしょの ちず'),
      s.tr('自宅の防災診断', 'Home preparedness check', 'いえの そなえチェック'),
    ];

    void changeTab(int tab) {
      FocusManager.instance.primaryFocus?.unfocus();
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      s.selectTab(tab);
    }

    AppBar toolbar({required bool home}) => AppBar(
      primary: !home,
      automaticallyImplyLeading: false,
      backgroundColor: home ? yellow : paper,
      toolbarHeight: 56 * MediaQuery.textScalerOf(context).scale(1),
      titleSpacing: !home && isSecondary ? 0 : 16,
      title: Text(
        home ? titles[0] : titles[s.tab],
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      leading: !home && isSecondary
          ? IconButton(
              tooltip: s.tr('ホームに戻る', 'Back to home'),
              onPressed: () => changeTab(0),
              icon: const Icon(Icons.arrow_back_rounded),
            )
          : null,
      actions: home
          ? [
              TextButton(
                key: const ValueKey('feature-menu'),
                onPressed: () => changeTab(DemoState.menuTab),
                child: Text(s.tr('機能一覧', 'Features', 'きのう')),
              ),
              IconButton(
                key: const ValueKey('home-settings'),
                tooltip: s.tr('設定', 'Settings', 'せってい'),
                onPressed: () => openPage(context, const SettingsScreen()),
                icon: const Icon(Icons.settings_outlined),
              ),
              const SizedBox(width: 8),
            ]
          : null,
    );

    final children = [
      Material(
        color: paper,
        child: HomeScreen(header: toolbar(home: true)),
      ),
      const CommunityScreen(),
      s.isEmergency ? const SafetyScreen() : const SizedBox.shrink(),
      s.isEmergency ? const HelpListScreen() : const SizedBox.shrink(),
      const FeatureMenuScreen(),
      _mapOpened
          ? const PreparednessMapScreen(inTab: true)
          : const SizedBox.shrink(),
      const HomeCheckScreen(inTab: true),
    ];

    return PopScope<Object?>(
      canPop: isHome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !isHome) changeTab(0);
      },
      child: Scaffold(
        backgroundColor: isHome ? yellow : paper,
        appBar: isHome ? null : toolbar(home: false),
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark,
          child: SafeArea(
            top: isHome,
            bottom: false,
            child: IndexedStack(
              key: ValueKey(s.resetVersion),
              index: s.tab,
              sizing: StackFit.expand,
              children: [
                for (var i = 0; i < children.length; i++)
                  ExcludeFocus(excluding: i != s.tab, child: children[i]),
              ],
            ),
          ),
        ),
        floatingActionButton: isHome
            ? SizedBox.square(
                dimension: 62,
                child: FloatingActionButton(
                  key: const ValueKey('open-assistant'),
                  heroTag: null,
                  shape: const CircleBorder(),
                  elevation: 2,
                  backgroundColor: yellow,
                  foregroundColor: ink,
                  tooltip: s.tr('そなAIを開く', 'Open Sona AI', 'そなAIを ひらく'),
                  onPressed: () =>
                      openPage(context, const DisasterChatScreen.assistant()),
                  child: const ExcludeSemantics(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 21),
                        SizedBox(height: 2),
                        SizedBox(
                          width: 49,
                          height: 16,
                          child: FittedBox(
                            child: Text(
                              'そなAI',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : null,
        bottomNavigationBar: _TabBar(onSelected: changeTab),
      ),
    );
  }
}

typedef _Tab = ({int id, String label, IconData icon});

class _TabBar extends StatelessWidget {
  final ValueChanged<int> onSelected;
  const _TabBar({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final tabs = <_Tab>[
      (id: 0, label: s.tr('ホーム', 'Home'), icon: Icons.home_outlined),
      if (s.isEmergency)
        (
          id: DemoState.safetyTab,
          label: s.tr('安否', 'Safety', 'ぶじ'),
          icon: Icons.verified_user_outlined,
        ),
      (
        id: DemoState.homeCheckTab,
        label: s.tr('防災診断', 'Home check', 'そなえチェック'),
        icon: Icons.checklist_rounded,
      ),
      (
        id: 1,
        label: s.tr('防災共有', 'Updates', 'おしらせ'),
        icon: Icons.article_outlined,
      ),
      (
        id: DemoState.mapTab,
        label: s.tr('マップ', 'Map', 'ちず'),
        icon: Icons.place_outlined,
      ),
    ];
    Widget row(List<_Tab> items) => Row(
      children: [
        for (final tab in items)
          Expanded(
            child: _TabButton(
              key: ValueKey('tab-${tab.id}'),
              data: tab,
              selected: s.tab == tab.id,
              onTap: () => onSelected(tab.id),
            ),
          ),
      ],
    );
    return Material(
      color: paper,
      child: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, box) {
              final scale = MediaQuery.textScalerOf(context).scale(1);
              if (scale >= 1.65 && box.maxWidth / tabs.length < 92) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    row(tabs.take(3).toList()),
                    const Divider(),
                    row(tabs.skip(3).toList()),
                  ],
                );
              }
              return row(tabs);
            },
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final _Tab data;
  final bool selected;
  final VoidCallback onTap;
  const _TabButton({
    super.key,
    required this.data,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? ink : secondaryText(context);
    return Semantics(
      label: data.label,
      selected: selected,
      button: true,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.fromLTRB(3, 7, 3, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 28,
                decoration: selected
                    ? BoxDecoration(
                        color: yellow,
                        borderRadius: BorderRadius.circular(10),
                      )
                    : null,
                child: Icon(data.icon, color: color, size: 22),
              ),
              const SizedBox(height: 3),
              Text(
                data.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final PreferredSizeWidget header;
  const HomeScreen({super.key, required this.header});

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final theme = Theme.of(context).textTheme;
    final unreadItems = orderedBulletins(
      bulletins.where((item) => !s.readBulletins.contains(item.id)),
    );
    final unread = unreadItems.length;
    final latest = unreadItems.firstOrNull ?? orderedBulletins(bulletins).first;

    void showUpdates() => s.update(() {
      s.communitySection = 1;
      s.bulletinFilter = 0;
      s.unreadOnly = unread > 0;
      s.tab = 1;
    });

    return SingleChildScrollView(
      key: ValueKey('home-${s.isEmergency}'),
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: yellow,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: header.preferredSize.height, child: header),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          s.tr('大島六丁目団地', 'Ojima 6-chome', 'おおじま 6ちょうめ だんち'),
                          style: theme.headlineMedium,
                        ),
                      ),
                      if (s.isEmergency) ...[
                        const SizedBox(height: 12),
                        const _EmergencySummary(),
                      ] else ...[
                        const SizedBox(height: 14),
                        AppButton(
                          label: s.tr(
                            '自宅の防災診断',
                            'Home preparedness check',
                            'いえの そなえチェック',
                          ),
                          onPressed: () => s.selectTab(DemoState.homeCheckTab),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 88),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        s.tr('回覧板', 'Bulletins', 'かいらんばん'),
                        style: theme.titleLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: showUpdates,
                      child: Text(
                        unread > 0
                            ? s.tr(
                                '未確認 $unread件',
                                '$unread unread',
                                'まだ $unreadけん',
                              )
                            : s.tr('一覧を見る', 'View all', 'ぜんぶ みる'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                BulletinCard(bulletin: latest, compact: true),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  title: Text(
                    s.tr('危険箇所を確認する', 'Check local hazards', 'きけんな ばしょを みる'),
                    style: theme.titleMedium,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => s.update(() {
                    s.communitySection = 0;
                    s.tab = 1;
                  }),
                ),
                const Divider(),
                if (s.storageUnavailable)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        s.tr(
                          '端末に保存できません。アプリを閉じる前に端末の空き容量や設定を確認してください。',
                          'Could not save on this device. Check storage and settings before closing the app.',
                        ),
                        style: const TextStyle(color: red),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencySummary extends StatelessWidget {
  const _EmergencySummary();

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final report = s.safetyReport();
    final hasDraft = s.safetyChanged() && s.safetyDraft().status != null;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.tr('非常時の訓練', 'Emergency practice', 'さいがい の れんしゅう'),
            style: const TextStyle(
              color: red,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                s.tr('安否確認', 'Safety check', 'ぶじの かくにん'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              AppBadge(
                report == null
                    ? s.tr('未報告', 'Not reported', 'まだ しらせていません')
                    : s.tr('報告済み', 'Reported', 'しらせました'),
                color: report == null ? ink : green,
                background: report == null
                    ? paleYellow
                    : const Color(0xFFE8F3EB),
              ),
            ],
          ),
          if (report != null)
            Text(
              '${safetyLabel(s, report.status)} · ${timeLabel(report.time)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          const SizedBox(height: 12),
          if (report == null && !hasDraft)
            const QuickSafetyReport(prominent: true),
          const SizedBox(height: 5),
          TextButton(
            child: Text(
              hasDraft
                  ? s.tr('入力の続きを確認する', 'Continue my report', 'かきかけの つづきを みる')
                  : report == null
                  ? s.tr('安否を報告する', 'Report my status', 'ぶじかどうか しらせる')
                  : s.tr('報告した内容を見る', 'View my report', 'しらせた ないようを みる'),
            ),
            onPressed: () {
              if (report != null && !hasDraft) {
                openPage(context, const SafetyResultScreen());
              } else {
                s.selectTab(DemoState.safetyTab);
              }
            },
          ),
          const SafetyContactsLink(),
          TextButton(
            onPressed: () => s.selectTab(DemoState.helpTab),
            child: Text(s.tr('助け合いを見る', 'Browse help posts', 'たすけあいを みる')),
          ),
        ],
      ),
    );
  }
}
