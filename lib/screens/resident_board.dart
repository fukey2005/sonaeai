import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../mock/demo_state.dart';
import '../mock/resident_examples.dart';
import '../photo_picker.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/prototype.dart';
import 'bulletins.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final sections = [
      s.tr('住民の投稿', 'Resident posts', 'だんちの とうこう'),
      s.tr('回覧板', 'Bulletins', 'かいらんばん'),
    ];
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < sections.length; i++)
              Expanded(
                child: Semantics(
                  selected: s.communitySection == i,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      minimumSize: const Size(48, 48),
                      shape: const RoundedRectangleBorder(),
                      foregroundColor: s.communitySection == i
                          ? ink
                          : secondaryText(context),
                    ),
                    onPressed: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      s.update(() => s.communitySection = i);
                    },
                    child: Text(
                      sections[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: s.communitySection == i
                            ? FontWeight.w800
                            : FontWeight.w500,
                        decoration: s.communitySection == i
                            ? TextDecoration.underline
                            : null,
                        decorationThickness: 2,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const Divider(),
        Expanded(
          child: IndexedStack(
            sizing: StackFit.expand,
            index: s.communitySection,
            children: [
              ExcludeFocus(
                excluding: s.communitySection != 0,
                child: const ResidentBoardScreen(inTab: true),
              ),
              ExcludeFocus(
                excluding: s.communitySection != 1,
                child: const BulletinListScreen(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ResidentBoardScreen extends StatefulWidget {
  final bool inTab;
  final PickPhoto selectPhoto;
  const ResidentBoardScreen({
    super.key,
    this.inTab = false,
    this.selectPhoto = pickPhoto,
  });

  @override
  State<ResidentBoardScreen> createState() => _ResidentBoardScreenState();
}

class _ResidentBoardScreenState extends State<ResidentBoardScreen> {
  final _scroll = ScrollController();
  bool _justPosted = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _compose() async {
    final s = DemoScope.of(context);
    final post = await openPage<DemoBoardPost>(
      context,
      _BoardForm(selectPhoto: widget.selectPhoto),
    );
    if (!mounted || post == null) return;
    s.update(() => s.boardPosts.insert(0, post));
    if (_scroll.hasClients) _scroll.jumpTo(0);
    setState(() => _justPosted = true);
  }

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final posts = [...s.boardPosts, residentExample(s)]
      ..sort((a, b) => b.time.compareTo(a.time));
    final header = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        liveRegion: true,
        child: Text(
          s.storageUnavailable
              ? s.tr(
                  '投稿を端末に保存できません。',
                  'Posts could not be saved on this device.',
                  'たんまつに とうこうを のこせません。',
                )
              : _justPosted
              ? s.tr(
                  '投稿を追加しました。投稿を開くと共有できます。',
                  'Posted. Open it to share.',
                  'とうこうを のせました。ひらいて きょうゆうできます。',
                )
              : s.tr(
                  '自分の投稿は端末に保存されます。',
                  'Your posts are saved on this device.',
                  'じぶんの とうこうは たんまつに のこります。',
                ),
          style: TextStyle(
            color: s.storageUnavailable ? red : secondaryText(context),
          ),
        ),
      ),
    );
    final child = Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(16),
            itemCount: posts.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return header;
              final post = posts[index - 1];
              return Column(
                key: ValueKey(post.id),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(),
                  _PostRow(
                    post: post,
                    onTap: () => openPage(
                      context,
                      isResidentExample(post)
                          ? _ExamplePostDetail(post: post)
                          : _PostDetail(
                              id: post.id,
                              selectPhoto: widget.selectPhoto,
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        ActionPanel(
          safeBottom: !widget.inTab,
          primary: AppButton(
            label: s.tr('危険箇所を投稿', 'Report a hazard', 'きけんな ばしょを しらせる'),
            onPressed: _compose,
          ),
        ),
      ],
    );
    return widget.inTab
        ? child
        : DetailPage(
            title: s.tr('住民の投稿', 'Resident posts', 'だんちの とうこう'),
            child: child,
          );
  }
}

class _PostRow extends StatelessWidget {
  final DemoBoardPost post;
  final VoidCallback onTap;
  const _PostRow({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PostHeader(post: post, showAuthor: true),
                const SizedBox(height: 5),
                Text(
                  post.body,
                  style: Theme.of(context).textTheme.bodyLarge,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                if (post.photoKey case final key?) ...[
                  const SizedBox(height: 10),
                  _StoredPostPhoto(
                    key: ValueKey(key),
                    photoKey: key,
                    place: post.place,
                    height: 198,
                    cover: true,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PostHeader extends StatelessWidget {
  final DemoBoardPost post;
  final bool showAuthor;
  const _PostHeader({required this.post, this.showAuthor = false});

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final date = MaterialLocalizations.of(context).formatShortDate(post.time);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (showAuthor)
              Text(
                isResidentExample(post)
                    ? s.tr('佐々木さん', 'Sasaki', 'ささきさん')
                    : s.tr('あなた', 'You'),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            if (isResidentExample(post))
              Text(
                s.tr('投稿例', 'Example', 'とうこうの れい'),
                style: TextStyle(color: secondaryText(context)),
              ),
            Text(
              '$date  ${timeLabel(post.time)}',
              style: TextStyle(color: secondaryText(context)),
            ),
          ],
        ),
        if (post.place case final place?) ...[
          const SizedBox(height: 4),
          Text(place, style: Theme.of(context).textTheme.titleMedium),
        ],
      ],
    );
  }
}

class _StoredPostPhoto extends StatefulWidget {
  final String photoKey;
  final String? place;
  final double height;
  final bool cover;
  const _StoredPostPhoto({
    super.key,
    required this.photoKey,
    this.place,
    required this.height,
    this.cover = false,
  });
  @override
  State<_StoredPostPhoto> createState() => _StoredPostPhotoState();
}

class _StoredPostPhotoState extends State<_StoredPostPhoto> {
  Future<Uint8List?>? _load;
  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    return FutureBuilder<Uint8List?>(
      future: _load ??= s.postPhotos.read(widget.photoKey),
      builder: (context, snapshot) {
        if (snapshot.data case final bytes?) {
          return _PostPhoto(
            bytes: bytes,
            place: widget.place,
            height: widget.height,
            cover: widget.cover,
          );
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return Text(
            s.tr('添付写真を開けませんでした', 'Photo unavailable', 'しゃしんを ひらけませんでした'),
          );
        }
        return const SizedBox(height: 32);
      },
    );
  }
}

class _PostPhoto extends StatelessWidget {
  final Uint8List bytes;
  final String? place;
  final double height;
  final bool cover;
  const _PostPhoto({
    required this.bytes,
    required this.place,
    required this.height,
    this.cover = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final label = place == null
        ? s.tr('投稿の写真', 'Post photo', 'とうこうの しゃしん')
        : s.tr('$place の写真', 'Photo of $place', '$place の しゃしん');
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: ColoredBox(
        color: wash,
        child: Image.memory(
          bytes,
          semanticLabel: label,
          width: double.infinity,
          height: height,
          fit: cover ? BoxFit.cover : BoxFit.contain,
          cacheWidth: cover ? 840 : null,
          errorBuilder: (context, error, stack) =>
              Text(s.tr('添付写真を開けませんでした', 'Photo unavailable')),
        ),
      ),
    );
  }
}

class _ExamplePostDetail extends StatelessWidget {
  final DemoBoardPost post;
  const _ExamplePostDetail({required this.post});

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    return PrototypePage(
      title: s.tr('住民の投稿', 'Resident post', 'だんちの とうこう'),
      children: [
        _PostHeader(post: post, showAuthor: true),
        const SizedBox(height: 12),
        Text(post.body, style: Theme.of(context).textTheme.bodyLarge),
        if (post.photoKey case final key?) ...[
          const SizedBox(height: 16),
          _StoredPostPhoto(photoKey: key, place: post.place, height: 300),
        ],
      ],
    );
  }
}

class _PostDetail extends StatefulWidget {
  final String id;
  final PickPhoto selectPhoto;
  const _PostDetail({required this.id, required this.selectPhoto});
  @override
  State<_PostDetail> createState() => _PostDetailState();
}

class _PostDetailState extends State<_PostDetail> {
  String? _photoKey;
  Future<Uint8List?>? _photo;
  bool _sharing = false;

  Future<void> _edit(DemoBoardPost post) async {
    final s = DemoScope.of(context);
    final changed = await openPage<DemoBoardPost>(
      context,
      _BoardForm(selectPhoto: widget.selectPhoto, editing: post),
    );
    if (!mounted || changed == null) return;
    final i = s.boardPosts.indexWhere((item) => item.id == changed.id);
    if (i >= 0) s.update(() => s.boardPosts[i] = changed);
  }

  Future<void> _remove(DemoBoardPost post) async {
    final s = DemoScope.of(context);
    final ok = await confirmAction(
      context,
      title: s.tr('この投稿を削除しますか？', 'Delete this post?', 'この とうこうを けしますか？'),
      message: s.tr(
        '添付した写真も掲示板から削除されます。',
        'This also removes its attached photo from the board.',
        'いっしょに のせた しゃしんも けします。',
      ),
      confirmLabel: s.tr('削除する', 'Delete', 'けす'),
      danger: true,
    );
    if (!mounted || !ok) return;
    Navigator.pop(context);
    s.update(() => s.boardPosts.removeWhere((item) => item.id == post.id));
  }

  String _shareText(DemoState s, DemoBoardPost post) => [
    if (post.topic == BoardTopic.hazard)
      s.tr('危険箇所', 'Local hazard', 'きけんな ばしょ'),
    if (post.place != null) post.place!,
    post.body,
  ].join('\n');

  Future<void> _share(
    BuildContext buttonContext,
    DemoBoardPost post,
    Uint8List? bytes,
  ) async {
    if (_sharing) return;
    final s = DemoScope.of(context);
    final box = buttonContext.findRenderObject() as RenderBox?;
    setState(() => _sharing = true);
    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          text: _shareText(s, post),
          files: bytes == null
              ? null
              : [XFile.fromData(bytes, mimeType: 'image/png')],
          fileNameOverrides: bytes == null ? null : ['sonaeai-photo.png'],
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
          downloadFallbackEnabled: false,
          mailToFallbackEnabled: false,
        ),
      );
      if (mounted && result.status == ShareResultStatus.unavailable) {
        showNotice(
          context,
          s.tr(
            '共有メニューを開けません。文章はコピーできます。',
            'Sharing is unavailable. You can copy the text.',
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        showNotice(
          context,
          s.tr(
            '共有メニューを開けません。文章はコピーできます。',
            'Sharing is unavailable. You can copy the text.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final post = s.boardPosts.where((post) => post.id == widget.id).firstOrNull;
    if (post == null) return const SizedBox.shrink();
    if (_photoKey != post.photoKey) {
      _photoKey = post.photoKey;
      _photo = _photoKey == null ? null : s.postPhotos.read(_photoKey!);
    }
    return FutureBuilder<Uint8List?>(
      future: _photo,
      builder: (context, snapshot) => PrototypePage(
        title: s.tr('投稿', 'Post', 'とうこう'),
        footer: ActionPanel(
          primary: Builder(
            builder: (buttonContext) => AppButton(
              label: s.tr('共有する', 'Share', 'きょうゆうする'),
              onPressed:
                  _sharing ||
                      (post.photoKey != null &&
                          snapshot.connectionState != ConnectionState.done)
                  ? null
                  : () => _share(buttonContext, post, snapshot.data),
            ),
          ),
        ),
        children: [
          _PostHeader(post: post, showAuthor: true),
          const SizedBox(height: 12),
          Text(post.body, style: Theme.of(context).textTheme.bodyLarge),
          if (snapshot.data case final bytes?) ...[
            const SizedBox(height: 16),
            _PostPhoto(bytes: bytes, place: post.place, height: 300),
          ] else if (post.photoKey != null &&
              snapshot.connectionState == ConnectionState.done) ...[
            const SizedBox(height: 16),
            Text(s.tr('添付写真を開けませんでした', 'Photo unavailable', 'しゃしんを ひらけませんでした')),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton(
                onPressed: () => _edit(post),
                child: Text(s.tr('編集する', 'Edit', 'なおす')),
              ),
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: _shareText(s, post)),
                  );
                  if (context.mounted) {
                    showNotice(context, s.tr('文章をコピーしました', 'Text copied'));
                  }
                },
                child: Text(s.tr('文章をコピー', 'Copy text', 'ぶんを コピー')),
              ),
              TextButton(
                onPressed: () => _remove(post),
                child: Text(
                  s.tr('削除する', 'Delete', 'けす'),
                  style: const TextStyle(color: red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BoardForm extends StatefulWidget {
  final DemoBoardPost? editing;
  final PickPhoto selectPhoto;
  const _BoardForm({required this.selectPhoto, this.editing});

  @override
  State<_BoardForm> createState() => _BoardFormState();
}

class _BoardFormState extends State<_BoardForm> {
  final _form = GlobalKey<FormState>();
  final _placeField = GlobalKey();
  final _bodyField = GlobalKey();
  late final _topic = widget.editing?.topic ?? BoardTopic.hazard;
  bool get _requiresPlace => _topic == BoardTopic.hazard;
  late final _body = TextEditingController(text: widget.editing?.body);
  late final _place = TextEditingController(text: widget.editing?.place);
  late String? _priorPhoto = widget.editing?.photoKey;
  Uint8List? _newPhoto;
  String? _error;
  bool _busy = false;
  bool _finished = false;
  bool _closing = false;
  bool get _changed =>
      _body.text != (widget.editing?.body ?? '') ||
      _place.text != (widget.editing?.place ?? '') ||
      _newPhoto != null ||
      _priorPhoto != widget.editing?.photoKey;

  @override
  void dispose() {
    _body.dispose();
    _place.dispose();
    super.dispose();
  }

  Future<void> _choose() async {
    if (_busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final source = await choosePhotoSource(context);
    if (!mounted || source == null) return;
    final s = DemoScope.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final image = await widget.selectPhoto(source);
      if (mounted && image != null) setState(() => _newPhoto = image);
    } catch (error) {
      if (mounted) setState(() => _error = photoError(s, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (_busy || _finished) return;
    if (!_form.currentState!.validate()) {
      final missingPlace = _requiresPlace && _place.text.trim().isEmpty;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final field = missingPlace ? _placeField : _bodyField;
        if (field.currentContext case final context?) {
          Scrollable.ensureVisible(context, alignment: .15);
        }
      });
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final s = DemoScope.of(context);
    final photo = _newPhoto;
    var photoKey = _priorPhoto;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (photo != null) photoKey = await s.postPhotos.save(photo);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = s.tr(
            '写真を保存できませんでした。空き容量を確認してください。',
            'Could not save the photo. Check available storage.',
            'しゃしんを ほぞんできません。たんまつの あきを みてください。',
          );
        });
      }
      return;
    }
    if (!mounted) return;
    _finished = true;
    final time = DateTime.now();
    Navigator.pop<DemoBoardPost>(context, (
      id: widget.editing?.id ?? 'post-${time.microsecondsSinceEpoch}',
      body: _body.text.trim(),
      topic: _topic,
      place: _requiresPlace ? _place.text.trim() : widget.editing?.place,
      time: widget.editing?.time ?? time,
      photoKey: photoKey,
    ));
  }

  Future<void> _close() async {
    if (_busy || _closing) return;
    if (!_changed) {
      Navigator.pop(context);
      return;
    }
    final s = DemoScope.of(context);
    _closing = true;
    final ok = await confirmAction(
      context,
      title: s.tr('編集をやめますか？', 'Discard changes?', 'かくのを やめますか？'),
      message: s.tr(
        '入力した内容と追加した写真は保存されません。',
        'The text and added photo will not be saved.',
        'かいた ことと しゃしんは のこりません。',
      ),
      confirmLabel: s.tr('破棄する', 'Discard', 'けす'),
      danger: true,
    );
    _closing = false;
    if (mounted && ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final photo = _newPhoto;
    final hasPhoto = photo != null || _priorPhoto != null;
    return PopScope<DemoBoardPost>(
      canPop: !_changed && !_busy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: DetailPage(
        title: widget.editing == null
            ? s.tr('危険箇所の投稿', 'Report a hazard', 'きけんな ばしょを しらせる')
            : s.tr('投稿を編集', 'Edit post', 'とうこうを なおす'),
        onBack: _close,
        child: TaskBody(
          footer: ActionPanel(
            primary: AppButton(
              label: widget.editing == null
                  ? s.tr('投稿する', 'Post', 'とうこうする')
                  : s.tr('変更を保存', 'Save changes', 'なおした ことを ほぞん'),
              onPressed: _busy ? null : _submit,
            ),
          ),
          children: [
            Form(
              key: _form,
              child: Column(
                children: [
                  if (_requiresPlace) ...[
                    TextFormField(
                      key: _placeField,
                      controller: _place,
                      readOnly: _busy,
                      onChanged: (_) => setState(() {}),
                      maxLength: 60,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: s.tr(
                          '場所（必須）',
                          'Location (required)',
                          'ばしょ（ひつよう）',
                        ),
                        hintText: s.tr(
                          '例：2号棟の南階段',
                          'e.g. South stairs, Building 2',
                          'れい：2ごうとうの みなみ かいだん',
                        ),
                      ),
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? s.tr(
                              '場所を入力してください',
                              'Enter the location',
                              'ばしょを いれて ください',
                            )
                          : null,
                    ),
                    const SizedBox(height: 8),
                  ],
                  TextFormField(
                    key: _bodyField,
                    controller: _body,
                    readOnly: _busy,
                    onChanged: (_) => setState(() {}),
                    minLines: 3,
                    maxLines: 7,
                    maxLength: 400,
                    decoration: InputDecoration(
                      labelText: s.tr(
                        '状況・伝えたいこと（必須）',
                        'What happened? (required)',
                        'ようす・つたえたい こと（ひつよう）',
                      ),
                      hintText: _requiresPlace
                          ? s.tr(
                              '例：踊り場の手すりがぐらついています',
                              'e.g. The landing handrail is loose',
                              'れい：かいだんの てすりが ぐらぐらします',
                            )
                          : null,
                      alignLabelWithHint: true,
                    ),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? s.tr(
                            '内容を入力してください',
                            'Enter a message',
                            'かく ことを いれて ください',
                          )
                        : null,
                  ),
                ],
              ),
            ),
            if (photo != null)
              _PostPhoto(bytes: photo, place: _place.text, height: 190)
            else if (_priorPhoto case final key?)
              _StoredPostPhoto(
                key: ValueKey(key),
                photoKey: key,
                place: _place.text,
                height: 190,
              ),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _busy ? null : _choose,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(
                    hasPhoto
                        ? s.tr('写真を変更', 'Change photo', 'しゃしんを かえる')
                        : s.tr('写真を追加', 'Add a photo', 'しゃしんを たす'),
                  ),
                ),
                if (hasPhoto)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _priorPhoto = null;
                            _newPhoto = null;
                          }),
                    child: Text(s.tr('写真を外す', 'Remove photo', 'しゃしんを はずす')),
                  ),
              ],
            ),
            if (_error case final error?)
              Semantics(
                liveRegion: true,
                child: Text(error, style: const TextStyle(color: red)),
              ),
            if (_busy) const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
