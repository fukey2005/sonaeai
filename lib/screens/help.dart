import 'package:flutter/material.dart';
import '../mock/demo_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/prototype.dart';
import 'disaster_chat.dart';

Future<void> startPostFlow(BuildContext context, {HelpPost? editing}) async {
  final post = await openPage<HelpPost>(
    context,
    HelpPostScreen(editing: editing),
  );
  if (!context.mounted) return;
  if (post == null) return;

  openPage(context, PostSavedScreen(postId: post.id, updated: editing != null));
}

Future<void> _startSupportRequest(BuildContext context) async {
  final category = await openPage<int>(context, const _SupportGuideScreen());
  if (category == null || !context.mounted) return;
  final s = DemoScope.of(context);
  if (!s.helpDraft.hasInput) {
    s.update(() => s.helpDraft.category = category);
  }
  await startPostFlow(context);
}

class _SupportGuideScreen extends StatefulWidget {
  const _SupportGuideScreen();

  @override
  State<_SupportGuideScreen> createState() => _SupportGuideScreenState();
}

class _SupportGuideScreenState extends State<_SupportGuideScreen> {
  int? selected;

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    return PrototypePage(
      title: s.tr('支援を依頼する', 'Ask for support', 'たすけを おねがいする'),
      description: s.tr(
        '困っている内容を選び、依頼の入力画面へ進む流れを試せます。',
        'Choose the kind of support you need to preview the request form.',
        'こまっている ことを えらぶと、おねがいを かく がめんへ すすみます。',
      ),
      footer: ActionPanel(
        status: selected == null || s.helpDraft.hasInput
            ? null
            : ActionStatus(
                s.tr(
                  '${helpCategory(s, selected!)}の依頼を作成',
                  'Create a ${helpCategory(s, selected!)} request',
                  'つぎに することの れい · ${helpCategory(s, selected!)}の おねがいを かく',
                ),
                tone: StatusTone.pending,
              ),
        hint: s.helpDraft.hasInput
            ? s.tr(
                '入力中の投稿を再開します。現在の下書きは保持されます。',
                'Continue the current draft with its existing details.',
                'かきかけの とうこうの つづきから はじめます。',
              )
            : null,
        primary: AppButton(
          label: s.helpDraft.hasInput
              ? s.tr('下書きの入力へ', 'Resume draft', 'かきかけの つづきへ')
              : s.tr('依頼の入力へ', 'Continue to request form', 'おねがいを かく'),
          onPressed: selected == null && !s.helpDraft.hasInput
              ? null
              : () => Navigator.pop(context, selected ?? 0),
        ),
      ),
      children: [
        if (!s.helpDraft.hasInput) ...[
          Text(
            s.tr(
              '何に困っていますか？',
              'What kind of support do you need?',
              'なにに こまって いますか？',
            ),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ChoiceTile(
                label: helpCategory(s, i),
                selected: selected == i,
                onTap: () => setState(() => selected = i),
              ),
            ),
        ],
      ],
    );
  }
}

class HelpListScreen extends StatefulWidget {
  const HelpListScreen({super.key});
  @override
  State<HelpListScreen> createState() => _HelpListScreenState();
}

class _HelpListScreenState extends State<HelpListScreen> {
  final controller = ScrollController();
  int lastRevision = -1;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    if (lastRevision != s.helpRevision) {
      lastRevision = s.helpRevision;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && controller.hasClients) controller.jumpTo(0);
      });
    }
    final myEmpty = s.helpFilter == 3 && !s.posts.any((post) => post.own);
    final items = s.posts
        .where(
          (p) =>
              (s.helpFilter == 0 ||
                  (s.helpFilter == 1 && p.request) ||
                  (s.helpFilter == 2 && !p.request) ||
                  (s.helpFilter == 3 && p.own)) &&
              (s.helpCategoryFilter == null ||
                  p.category == s.helpCategoryFilter) &&
              (s.helpFilter == 3 || !s.closedPosts.contains(p.id)),
        )
        .toList();
    return TaskBody(
      controller: controller,
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilterTabs(
            labels: [
              s.tr('すべて', 'All'),
              s.tr('助けてほしい', 'Need help'),
              s.tr('手伝えます', 'Can help'),
              s.tr('自分の投稿', 'My posts', 'じぶんの とうこう'),
            ],
            selected: s.helpFilter,
            onChanged: (v) => s.update(() => s.helpFilter = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            key: ValueKey(s.helpCategoryFilter),
            initialValue: s.helpCategoryFilter ?? -1,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: s.tr('内容で絞り込む', 'Filter by category', 'ないようで しぼる'),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            items: [
              DropdownMenuItem(
                value: -1,
                child: Text(s.tr('すべての内容', 'All categories', 'ぜんぶの ないよう')),
              ),
              ...List.generate(
                5,
                (i) =>
                    DropdownMenuItem(value: i, child: Text(helpCategory(s, i))),
              ),
            ],
            onChanged: (v) =>
                s.update(() => s.helpCategoryFilter = v == -1 ? null : v),
          ),
        ],
      ),
      footer: ActionPanel(
        safeBottom: false,
        primary: AppButton(
          label: s.helpDraft.hasInput
              ? s.tr('下書きの続きを入力する', 'Continue my draft', 'かきかけの つづきを かく')
              : s.tr('助け合いを投稿する', 'Create a post', 'たすけあいを かく'),
          onPressed: () => startPostFlow(context),
        ),
      ),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            OutlinedButton.icon(
              onPressed: () => _startSupportRequest(context),
              icon: const Icon(Icons.pan_tool_alt_outlined),
              label: Text(s.tr('支援を依頼する', 'Ask for support', 'たすけを おねがい')),
            ),
            OutlinedButton.icon(
              onPressed: () =>
                  openPage(context, const DisasterChatScreen.community()),
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text(s.tr('防災チャット', 'Community chat', 'ぼうさい チャット')),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          s.tr(
            '${items.length}件の投稿',
            '${items.length} posts',
            '${items.length}けんの とうこう',
          ),
          style: TextStyle(fontSize: 14, color: secondaryText(context)),
        ),
        const SizedBox(height: 14),
        if (items.isEmpty)
          EmptyState(
            title: myEmpty
                ? s.tr(
                    '自分の投稿はありません',
                    'No posts of your own yet',
                    'じぶんの とうこうは ありません',
                  )
                : s.tr(
                    'この条件の投稿はありません',
                    'No matching posts',
                    'この じょうけんの とうこうは ありません',
                  ),
            message: myEmpty
                ? s.tr(
                    '投稿した内容は、ここから確認・編集できます。',
                    'You can review and edit your posts here.',
                    'かいたものは、ここから みたり なおしたり できます。',
                  )
                : s.tr(
                    '絞り込みを解除すると、ほかの投稿を確認できます。',
                    'Clear the filters to see other posts.',
                    'しぼりこみを やめると、ほかの とうこうを みられます。',
                  ),
            action: myEmpty && s.helpCategoryFilter == null
                ? null
                : AppButton(
                    label: s.tr('絞り込みを解除する', 'Clear filters', 'しぼりこみを やめる'),
                    outlined: true,
                    onPressed: () => s.update(() {
                      s.helpFilter = 0;
                      s.helpCategoryFilter = null;
                    }),
                  ),
          ),
        ...items.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: HelpCard(post: p),
          ),
        ),
      ],
    );
  }
}

class HelpCard extends StatelessWidget {
  final HelpPost post;
  const HelpCard({super.key, required this.post});
  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context), p = post;
    final closed = s.closedPosts.contains(p.id),
        responded = s.responses.containsKey(p.id);
    return SurfaceCard(
      onTap: () => openPage(context, HelpDetailScreen(postId: p.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppBadge(
                p.request
                    ? s.tr('助けてほしい', 'Need help')
                    : s.tr('手伝えます', 'Can help'),
                color: p.request ? red : green,
                background: p.request
                    ? const Color(0xFFFFEAE5)
                    : const Color(0xFFE8F3EB),
              ),
              if (closed) AppBadge(s.tr('募集終了', 'Closed', 'ぼしゅう おわり')),
              if (p.own) AppBadge(s.tr('自分の投稿', 'My post', 'じぶんの とうこう')),
              if (responded)
                AppBadge(
                  p.request
                      ? s.tr('申し出済み', 'Help offered', 'もうしでずみ')
                      : s.tr('依頼済み', 'Help requested', 'おねがいずみ'),
                  color: blue,
                  background: const Color(0xFFEAF1FA),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            s.tr(p.title, p.titleEn),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            locationLabel(s, p),
            style: TextStyle(fontSize: 14, color: secondaryText(context)),
          ),
          if (p.detail.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              s.tr(p.detail, p.detailEn),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                height: 1.7,
                color: secondaryText(context),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            s.tr('内容を確認する', 'View post', 'ないようを みる'),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: blue,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }
}

class PostSummary extends StatelessWidget {
  final HelpPost post;
  const PostSummary({super.key, required this.post});
  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context), p = post;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppBadge(
            p.request ? s.tr('助けてほしい', 'Need help') : s.tr('手伝えます', 'Can help'),
            color: p.request ? red : green,
            background: p.request
                ? const Color(0xFFFFEAE5)
                : const Color(0xFFE8F3EB),
          ),
          const SizedBox(height: 14),
          Text(
            s.tr(p.title, p.titleEn),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text(
            '${s.tr('場所', 'Location')}: ${locationLabel(s, p)}',
            style: const TextStyle(fontSize: 16, height: 1.7),
          ),
          const SizedBox(height: 8),
          Text(
            '${s.tr('内容', 'Category')}: ${helpCategory(s, p.category)}',
            style: const TextStyle(fontSize: 16, height: 1.7),
          ),
          if (p.detail.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              s.tr(p.detail, p.detailEn),
              style: const TextStyle(fontSize: 16, height: 1.9),
            ),
          ],
        ],
      ),
    );
  }
}

class HelpDetailScreen extends StatelessWidget {
  final String postId;
  const HelpDetailScreen({super.key, required this.postId});
  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context), p = DemoScope.of(context).postById(postId);
    final closed = s.closedPosts.contains(postId),
        responded = s.responses.containsKey(postId);
    final editLabel = s.editDrafts[postId]?.dirty == true
        ? s.tr('編集の続きを入力する', 'Continue editing', 'なおしている つづきを かく')
        : s.tr('投稿を編集する', 'Edit my post', 'とうこうを なおす');
    final responseLabel =
        '${p.request ? s.tr('申し出済み', 'Help offered', 'もうしでました') : s.tr('依頼済み', 'Help requested', 'おねがいしました')} ${responded ? timeLabel(s.responses[postId]!) : ''}';
    return DetailPage(
      title: s.tr('助け合いの内容', 'Post details', 'たすけあいの ないよう'),
      footer: p.own
          ? ActionPanel(
              status: ActionStatus(
                closed
                    ? s.tr('募集終了', 'Closed', 'ぼしゅう おわり')
                    : s.tr('募集中', 'Open', 'ぼしゅう ちゅう'),
                tone: closed ? StatusTone.neutral : StatusTone.complete,
              ),
              primary: AppButton(
                label: closed
                    ? s.tr('募集を再開する', 'Reopen this post', 'ぼしゅうを さいかいする')
                    : editLabel,
                outlined: closed,
                onPressed: () {
                  if (closed) {
                    s.update(() => s.closedPosts.remove(postId));
                  } else {
                    startPostFlow(context, editing: p);
                  }
                },
              ),
              secondary: AppButton(
                label: closed
                    ? editLabel
                    : s.tr('募集を終了する', 'Close this post', 'ぼしゅうを おわる'),
                outlined: true,
                onPressed: () async {
                  if (closed) {
                    startPostFlow(context, editing: p);
                    return;
                  }
                  final ok = await confirmAction(
                    context,
                    title: s.tr(
                      '募集を終了しますか？',
                      'Close this post?',
                      'ぼしゅうを おわりますか？',
                    ),
                    message: s.tr(
                      '終了後も「自分の投稿」から確認・再開できます。',
                      'You can still find and reopen it under My posts.',
                      'おわった あとも「じぶんの とうこう」から みたり さいかいしたり できます。',
                    ),
                    confirmLabel: s.tr('募集を終了する', 'Close post', 'ぼしゅうを おわる'),
                  );
                  if (ok && context.mounted) {
                    s.update(() => s.closedPosts.add(postId));
                  }
                },
              ),
            )
          : closed
          ? null
          : responded
          ? ActionPanel(
              status: ActionStatus(responseLabel),
              primary: AppButton(
                label: p.request
                    ? s.tr('申し出を取り消す', 'Cancel my offer', 'もうしでを とりけす')
                    : s.tr('依頼を取り消す', 'Cancel my request', 'おねがいを とりけす'),
                outlined: true,
                onPressed: () async {
                  final ok = await confirmAction(
                    context,
                    title: p.request
                        ? s.tr(
                            '申し出を取り消しますか？',
                            'Cancel this offer?',
                            'もうしでを とりけしますか？',
                          )
                        : s.tr(
                            '依頼を取り消しますか？',
                            'Cancel this request?',
                            'おねがいを とりけしますか？',
                          ),
                    message: s.tr(
                      '取り消した後も、同じ投稿にもう一度申し出・依頼できます。',
                      'You can respond to this post again later.',
                      'とりけした あとでも、もういちど できます。',
                    ),
                    confirmLabel: s.tr('取り消す', 'Cancel response', 'とりけす'),
                  );
                  if (ok && context.mounted) {
                    s.update(() => s.responses.remove(postId));
                    showNotice(
                      context,
                      s.tr('取り消しました', 'Response cancelled', 'とりけしました'),
                    );
                  }
                },
              ),
            )
          : ActionPanel(
              primary: AppButton(
                label: p.request
                    ? s.tr('協力を申し出る', 'Offer to help', 'てつだうと しらせる')
                    : s.tr('手伝いをお願いする', 'Ask for help', 'てつだいを おねがいする'),
                onPressed: () async {
                  final ok = await confirmAction(
                    context,
                    title: p.request
                        ? s.tr('協力の申し出を確認', 'Review my offer', 'もうしでを たしかめる')
                        : s.tr('手伝いの依頼を確認', 'Review my request', 'おねがいを たしかめる'),
                    message:
                        '${s.tr(p.title, p.titleEn)}\n${locationLabel(s, p)}\n\n${s.tr('この申し出は端末内に記録されます。', 'This is saved on your device.', 'れんしゅう用です。ほかの ひとには おくられません。')}',
                    confirmLabel: p.request
                        ? s.tr('申し出を記録', 'Confirm offer (demo)', 'もうしでる')
                        : s.tr('依頼を記録', 'Confirm request (demo)', 'おねがいする'),
                  );
                  if (ok && context.mounted) {
                    s.update(() => s.responses[postId] = DateTime.now());
                    openPage(context, ResponseResultScreen(postId: postId));
                  }
                },
              ),
            ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (closed && !p.own) ...[
              AppBadge(s.tr('募集終了', 'Closed', 'ぼしゅう おわり')),
              const SizedBox(height: 16),
            ],
            PostSummary(post: p),
            if (p.own && s.editDrafts[postId]?.dirty == true) ...[
              const SizedBox(height: 16),
              Text(
                s.tr(
                  '未確定の編集内容を下書きに残しています。',
                  'Your unfinished edits are kept as a draft.',
                  'なおしている ないようを のこしています。',
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ],
            const LocalRecordNote(),
          ],
        ),
      ),
    );
  }
}

class ResponseResultScreen extends StatelessWidget {
  final String postId;
  const ResponseResultScreen({super.key, required this.postId});
  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context), p = DemoScope.of(context).postById(postId);
    return DetailPage(
      title: p.request
          ? s.tr('申し出を記録しました', 'Offer recorded', 'もうしでました')
          : s.tr('依頼を記録しました', 'Request recorded', 'おねがいしました'),
      footer: ActionPanel(
        primary: AppButton(
          label: s.tr('投稿の内容に戻る', 'Back to this post', 'とうこうに もどる'),
          onPressed: () => Navigator.pop(context),
        ),
        secondary: AppButton(
          label: s.tr('助け合い一覧に戻る', 'Back to all posts'),
          outlined: true,
          onPressed: () {
            s.selectTab(DemoState.helpTab);
            Navigator.popUntil(context, (r) => r.isFirst);
          },
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: p.request
                  ? s.tr(
                      '協力の申し出を記録しました',
                      'Your offer was recorded',
                      'てつだう れんしゅうが できました',
                    )
                  : s.tr(
                      '手伝いの依頼を記録しました',
                      'Your request was recorded',
                      'おねがいの れんしゅうが できました',
                    ),
            ),
            PostSummary(post: p),
            const LocalRecordNote(),
            const SizedBox(height: 12),
            Text(
              s.tr(
                '投稿の画面から、申し出・依頼を取り消すこともできます。',
                'You can cancel your response from the post.',
                'とうこうの がめんから とりけすことも できます。',
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

class HelpPostScreen extends StatefulWidget {
  final HelpPost? editing;
  const HelpPostScreen({super.key, this.editing});
  @override
  State<HelpPostScreen> createState() => _HelpPostScreenState();
}

class _HelpPostScreenState extends State<HelpPostScreen> {
  final form = GlobalKey<FormState>(),
      categoryKey = GlobalKey(),
      titleKey = GlobalKey(),
      buildingKey = GlobalKey();
  late HelpDraft draft;
  late TextEditingController title, details, landmark;
  bool initialized = false, showErrors = false, openingReview = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = DemoScope.of(context);
    if (!initialized) {
      draft = s.draftFor(widget.editing);
      title = TextEditingController(text: draftTitle(s, draft));
      details = TextEditingController(text: draft.detail);
      landmark = TextEditingController(text: draft.landmark);
      initialized = true;
    } else if (!draft.titleEdited) {
      final value = draftTitle(s, draft);
      if (title.text != value) title.text = value;
    }
  }

  @override
  void dispose() {
    title.dispose();
    details.dispose();
    landmark.dispose();
    super.dispose();
  }

  void changed(VoidCallback change) {
    final s = DemoScope.of(context), original = widget.editing;
    s.update(() {
      change();
      draft.dirty =
          original == null ||
          draft.request != original.request ||
          draft.category != original.category ||
          draft.building != original.building ||
          draftTitle(s, draft).trim() !=
              s.tr(original.title, original.titleEn) ||
          draft.detail.trim() != original.detail ||
          draft.landmark.trim() != original.landmark;
    });
  }

  void setType(bool request) => changed(() {
    draft.request = request;
    if (!draft.titleEdited) {
      title.text = draftTitle(DemoScope.of(context), draft);
    }
  });
  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final editing = widget.editing != null;
    final hasDraft = editing ? draft.dirty : draft.hasInput;
    return DetailPage(
      title: widget.editing == null
          ? s.tr('助け合いを投稿', 'Create a post')
          : s.tr('投稿を編集', 'Edit my post', 'とうこうを なおす'),
      footer: ActionPanel(
        hint: editing && !hasDraft
            ? s.tr(
                '変更すると確認に進めます。',
                'Make a change to continue.',
                'ないようを かえると つぎに すすみます。',
              )
            : null,
        primary: AppButton(
          label: s.tr('内容を確認する', 'Review post', 'ないようを たしかめる'),
          onPressed: openingReview || (editing && !hasDraft) ? null : review,
        ),
      ),
      child: Form(
        key: form,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasDraft) ...[
                AppBadge(
                  widget.editing == null
                      ? s.tr('入力中の下書き', 'Unfinished draft', 'かきかけの ないよう')
                      : s.tr('保存前の編集内容', 'Unsaved edits', 'まだ きろくしていない へんこう'),
                ),
                const SizedBox(height: 20),
              ],
              _FieldLabel(s.tr('投稿種別', 'Post type', 'とうこうの しゅるい')),
              const SizedBox(height: 12),
              FilterTabs(
                labels: [
                  s.tr('助けてほしい', 'I need help'),
                  s.tr('手伝えます', 'I can help'),
                ],
                selected: draft.request ? 0 : 1,
                onChanged: (v) => setType(v == 0),
              ),
              const SizedBox(height: 24),
              _FieldLabel(s.tr('内容', 'Category'), required: true),
              const SizedBox(height: 12),
              Container(
                key: categoryKey,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(
                    5,
                    (i) => ChoiceChip(
                      label: Text(helpCategory(s, i)),
                      selected: draft.category == i,
                      onSelected: (_) => changed(() {
                        draft.category = i;
                        if (!draft.titleEdited) {
                          title.text = draftTitle(s, draft);
                        }
                      }),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              if (showErrors && draft.category == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    s.tr(
                      '内容を1つ選んでください。',
                      'Choose one category.',
                      'ないようを ひとつ えらんでください。',
                    ),
                    style: const TextStyle(color: red),
                  ),
                ),
              const SizedBox(height: 24),
              TextFormField(
                key: titleKey,
                controller: title,
                maxLength: 40,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: s.tr(
                    '見出し（必須）',
                    'Post title (required)',
                    'みだし（かならず かく）',
                  ),
                  hintText: s.tr(
                    '内容を選ぶと候補が入ります。変更できます。',
                    'Choose a category for a suggestion, then edit it.',
                    'ないようを えらぶと みだしが はいります。なおせます。',
                  ),
                ),
                onChanged: (value) => changed(() {
                  draft.title = value;
                  draft.titleEdited = true;
                }),
                validator: (value) => value == null || value.trim().isEmpty
                    ? s.tr('見出しを入力してください。', 'Enter a title.', 'みだしを かいてください。')
                    : null,
              ),
              const SizedBox(height: 16),
              _FieldLabel(s.tr('場所', 'Location'), required: true),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                key: buildingKey,
                initialValue: draft.building,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: s.tr(
                    '住棟を選択',
                    'Choose a building',
                    'すんでいる とうを えらぶ',
                  ),
                ),
                items: List.generate(
                  8,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text(s.tr('${i + 1}号棟', 'Building ${i + 1}')),
                  ),
                ),
                onChanged: (v) => changed(() => draft.building = v),
                validator: (value) => value == null
                    ? s.tr('住棟を選んでください。', 'Choose a building.', 'とうを えらんでください。')
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: landmark,
                maxLength: 40,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: s.tr(
                    '詳しい場所（任意）',
                    'Meeting place (optional)',
                    'くわしい ばしょ（かかなくても いいです）',
                  ),
                  hintText: s.tr(
                    '例：入口付近・集会所の前',
                    'e.g. by the entrance',
                    'れい：いりぐちの ちかく',
                  ),
                ),
                onChanged: (v) => changed(() => draft.landmark = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: details,
                minLines: 3,
                maxLines: 6,
                maxLength: 200,
                decoration: InputDecoration(
                  labelText: s.tr(
                    '詳細（任意）',
                    'Details (optional)',
                    'くわしい はなし（かかなくても いいです）',
                  ),
                  hintText: draft.request
                      ? s.tr(
                          '必要な量や、困っていることなど（任意）',
                          'What do you need, and how much? (optional)',
                          'どれくらい ひつようか など（かかなくても いいです）',
                        )
                      : s.tr(
                          '手伝える内容や、受け渡しできるものなど（任意）',
                          'How can you help? (optional)',
                          'てつだえること など（かかなくても いいです）',
                        ),
                ),
                onChanged: (v) => changed(() => draft.detail = v),
              ),
              const SizedBox(height: 12),
              Text(
                s.tr(
                  '個人名・電話番号の入力は不要です。',
                  'Names and phone numbers are not needed.',
                  'なまえや でんわばんごうは いりません。',
                ),
                style: TextStyle(fontSize: 14, color: secondaryText(context)),
              ),
              if (hasDraft) ...[
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () async {
                    final ok = await confirmAction(
                      context,
                      title: s.tr(
                        '下書きを破棄しますか？',
                        'Discard this draft?',
                        'かきかけを けしますか？',
                      ),
                      message: s.tr(
                        'この画面で入力した、まだ確定していない内容を破棄します。',
                        'Only the unconfirmed input in this draft will be discarded.',
                        'まだ きろくしていない ないようを けします。',
                      ),
                      confirmLabel: s.tr(
                        '下書きを破棄する',
                        'Discard draft',
                        'かきかけを けす',
                      ),
                      danger: true,
                    );
                    if (ok && context.mounted) {
                      s.clearDraft(widget.editing?.id);
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    s.tr('下書きを破棄する', 'Discard draft', 'かきかけを けす'),
                    style: const TextStyle(color: red),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> review() async {
    final s = DemoScope.of(context);
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => showErrors = true);
    final valid = form.currentState!.validate();
    if (!valid || draft.category == null) {
      final key = draft.category == null
          ? categoryKey
          : title.text.trim().isEmpty
          ? titleKey
          : buildingKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && key.currentContext != null) {
          Scrollable.ensureVisible(
            key.currentContext!,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
            alignment: 0.1,
          );
        }
      });
      return;
    }
    draft.title = title.text;
    setState(() => openingReview = true);
    final confirmed = await openPage<bool>(
      context,
      HelpPostReviewScreen(draft: draft, editing: widget.editing),
    );
    if (!mounted) return;
    if (confirmed == true) {
      final post = s.commitPost(draft, id: widget.editing?.id);
      Navigator.pop(context, post);
    } else {
      setState(() => openingReview = false);
    }
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;
  const _FieldLabel(this.label, {this.required = false});
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(label, style: Theme.of(context).textTheme.titleMedium),
      if (required)
        Text(
          DemoScope.of(context).tr('必須', 'Required', 'かならず えらぶ・かく'),
          style: const TextStyle(fontSize: 14, color: red),
        ),
    ],
  );
}

class HelpPostReviewScreen extends StatefulWidget {
  final HelpDraft draft;
  final HelpPost? editing;
  const HelpPostReviewScreen({super.key, required this.draft, this.editing});
  @override
  State<HelpPostReviewScreen> createState() => _HelpPostReviewScreenState();
}

class _HelpPostReviewScreenState extends State<HelpPostReviewScreen> {
  bool submitted = false;
  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context), d = widget.draft;
    final post = HelpPost(
      id: widget.editing?.id ?? 'preview',
      title: draftTitle(s, d),
      titleEn: draftTitle(s, d),
      detail: d.detail,
      detailEn: d.detail,
      request: d.request,
      building: d.building!,
      category: d.category!,
      own: true,
      landmark: d.landmark,
    );
    return DetailPage(
      title: s.tr('投稿内容の確認', 'Review my post', 'とうこうを たしかめる'),
      footer: ActionPanel(
        primary: AppButton(
          label: widget.editing == null
              ? s.tr('この内容で投稿する', 'Add post', 'これで とうこう')
              : s.tr('変更を保存する', 'Save edits', 'へんこうを きろく'),
          onPressed: submitted
              ? null
              : () {
                  if (submitted) return;
                  setState(() => submitted = true);
                  Navigator.pop(context, true);
                },
        ),
        secondary: AppButton(
          label: s.tr('内容を修正する', 'Edit details', 'ないようを なおす'),
          outlined: true,
          onPressed: submitted ? null : () => Navigator.pop(context, false),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PostSummary(post: post),
            const LocalRecordNote(),
          ],
        ),
      ),
    );
  }
}

class PostSavedScreen extends StatelessWidget {
  final String postId;
  final bool updated;
  const PostSavedScreen({
    super.key,
    required this.postId,
    this.updated = false,
  });
  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context),
        post = DemoScope.of(context).postById(postId);
    return DetailPage(
      title: updated
          ? s.tr('投稿を更新しました', 'Post updated', 'とうこうを なおしました')
          : s.tr('掲示板に追加しました', 'Post added', 'とうこうしました'),
      footer: ActionPanel(
        primary: AppButton(
          label: s.tr('投稿した内容を見る', 'View my post', 'とうこうを みる'),
          onPressed: () {
            if (updated) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => HelpDetailScreen(postId: postId),
                ),
              );
            }
          },
        ),
        secondary: AppButton(
          label: s.tr('自分の投稿一覧へ', 'Go to My posts', 'じぶんの とうこうの いちらんへ'),
          outlined: true,
          onPressed: () {
            s.update(() {
              s.helpFilter = 3;
              if (s.isEmergency) s.tab = DemoState.helpTab;
            });
            Navigator.popUntil(context, (r) => r.isFirst);
          },
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.tr(
                '「自分の投稿」から、内容の確認・編集・募集終了ができます。',
                'Find this under My posts to review, edit or close it.',
                '「じぶんの とうこう」から、みたり なおしたり ぼしゅうを おわったり できます。',
              ),
              style: const TextStyle(fontSize: 16, height: 1.8),
            ),
            const SizedBox(height: 20),
            PostSummary(post: post),
            const LocalRecordNote(),
          ],
        ),
      ),
    );
  }
}
