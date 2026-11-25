import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../mock/demo_state.dart';
import '../photo_picker.dart';
import '../room_inspection.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/prototype.dart';

const _areas =
    <
      RoomArea,
      ({UiCopy name, UiCopy instruction, UiCopy finding, UiCopy action})
    >{
      RoomArea.tallFurniture: (
        name: ('背の高い家具', 'Tall furniture', 'せの たかい かぐ'),
        instruction: (
          '棚やタンスと、その隣の壁を一緒に写してください。',
          'Include a tall shelf or dresser and the wall next to it.',
          'せの たかい たなや タンスと、となりの かべを うつします。',
        ),
        finding: (
          '棚や家具が写っているようです。',
          'The photo appears to show shelving or furniture.',
          'たなや かぐが うつっている ようです。',
        ),
        action: (
          '家具の固定具と、壁や天井への取り付け部を確かめます。',
          'Look at the actual fastenings to check that the furniture is secured.',
          'かべに とまっているか みます。',
        ),
      ),
      RoomArea.doorway: (
        name: ('出入口と通路', 'Doorway and passage', 'でいりぐちと とおりみち'),
        instruction: (
          'ドア全体と、手前の床が見えるように撮ってください。',
          'Frame the whole door and the floor in front of it.',
          'ドアと まえの ゆかが みえるように とります。',
        ),
        finding: (
          'ドアや荷物が写っているようです。',
          'The photo appears to show a door or boxes.',
          'ドアか にもつが うつっている ようです。',
        ),
        action: (
          'ドアを開けて、通路をふさぐ物がないか確かめます。',
          'Open the door and check that objects do not block the passage.',
          'ドアを あけて、とおりみちに ものが ないか みます。',
        ),
      ),
      RoomArea.upperShelf: (
        name: ('棚の上と収納', 'Upper shelves and storage', 'たなの うえと しゅうのう'),
        instruction: (
          '棚の上から低い段まで、何を置いているか分かるように撮ってください。',
          'Show what is stored from the top to the lower shelves.',
          'たなの うえから したまで、なにが あるか わかるように とります。',
        ),
        finding: (
          '棚や収納が写っているようです。',
          'The photo appears to show a shelf or storage space.',
          'たなや しゅうのうが うつっている ようです。',
        ),
        action: (
          '重い物や割れ物が上にある場合は、低い段に移します。',
          'Move heavy or breakable objects from upper shelves to a lower shelf.',
          'おもい ものや われものは、ひくい ところに おきます。',
        ),
      ),
    };

String inspectionAreaLabel(DemoState s, RoomArea area) =>
    _areas[area]!.name.forDemo(s);

Future<List<int>> _suggestChecks(Uint8List image) async {
  try {
    const channel = MethodChannel('jp.ac.tid.neoJichikai/room_photo');
    return await channel.invokeListMethod<int>('suggestChecks', image) ??
        const [];
  } on PlatformException {
    return const [];
  } on MissingPluginException {
    return const [];
  }
}

class RoomPhotoScreen extends StatefulWidget {
  final PickPhoto selectPhoto;
  final Future<List<int>> Function(Uint8List)? analyzePhoto;

  const RoomPhotoScreen({
    super.key,
    this.selectPhoto = pickPhoto,
    this.analyzePhoto,
  });

  @override
  State<RoomPhotoScreen> createState() => _RoomPhotoScreenState();
}

class _RoomPhotoScreenState extends State<RoomPhotoScreen> {
  final _photos = List<Uint8List?>.filled(RoomArea.values.length, null);
  final _flagged = List<bool>.filled(RoomArea.values.length, false);
  final _reviewed = List<bool?>.filled(RoomArea.values.length, null);
  final _scroll = ScrollController();
  int _index = 0;
  bool _reviewing = false, _busy = false, _confirming = false;
  String? _error;

  Future<List<int>> Function(Uint8List)? get _analyzePhoto =>
      widget.analyzePhoto ??
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
          ? _suggestChecks
          : null);

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _jump(int index, {required bool review}) {
    setState(() {
      _index = index;
      _reviewing = review;
      _error = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _back() async {
    if (_busy || _confirming) return;
    if (_index > 0) {
      _jump(_index - 1, review: _reviewing);
      return;
    }
    if (_reviewing) {
      _jump(_photos.length - 1, review: false);
      return;
    }
    if (_photos.any((photo) => photo != null)) {
      final s = DemoScope.of(context);
      _confirming = true;
      final discard = await confirmAction(
        context,
        title: s.tr('点検を中止しますか？', 'Discard this inspection?', 'てんけんを やめますか？'),
        message: s.tr(
          '途中まで撮った写真は残りません。',
          'Photos from this unfinished inspection will be discarded.',
          'とちゅうの しゃしんは のこりません。',
        ),
        confirmLabel: s.tr('点検を中止する', 'Discard inspection', 'てんけんを やめる'),
      );
      _confirming = false;
      if (!mounted || !discard) return;
    }
    Navigator.pop(context);
  }

  Future<void> _choose(ImageSource source) async {
    if (_busy) return;
    final s = DemoScope.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final photo = await widget.selectPhoto(source);
      if (mounted && photo != null) {
        setState(() {
          _photos[_index] = photo;
          _reviewed[_index] = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = photoError(s, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _nextPhoto() async {
    if (_busy || _photos[_index] == null) return;
    if (_index < _photos.length - 1) {
      _jump(_index + 1, review: false);
      return;
    }
    if (_photos.any((photo) => photo == null)) return;
    final analyze = _analyzePhoto;
    if (analyze == null) {
      _jump(0, review: true);
      return;
    }
    setState(() => _busy = true);
    try {
      for (var i = 0; i < _photos.length; i++) {
        final suggestions = await analyze(_photos[i]!);
        if (!mounted) return;
        _flagged[i] = suggestions.contains(RoomArea.values[i].index);
      }
      _jump(0, review: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finishStep(bool reviewed) async {
    if (_busy) return;
    _reviewed[_index] = reviewed;
    if (_index < _photos.length - 1) {
      _jump(_index + 1, review: true);
      return;
    }
    final s = DemoScope.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final saved = <InspectionPhoto>[];
      for (var i = 0; i < _photos.length; i++) {
        final photoKey = await s.postPhotos.save(_photos[i]!);
        if (!mounted) return;
        saved.add((
          area: RoomArea.values[i],
          photoKey: photoKey,
          flagged: _flagged[i],
          reviewed: _reviewed[i] ?? false,
        ));
      }
      final RoomInspection inspection = (
        time: DateTime.now(),
        photos: List.unmodifiable(saved),
      );
      s.update(() => s.roomInspections.insert(0, inspection));
      await s.waitForLocalSaves?.call();
      if (s.storageUnavailable) {
        s.update(() => s.roomInspections.remove(inspection));
        throw StateError('The inspection record could not be saved.');
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = s.tr(
            '写真を保存できませんでした。空き容量を確認して、もう一度お試しください。',
            'The photos could not be saved. Check storage and try again.',
            'しゃしんを ほぞんできませんでした。たんまつの あきを みてから、もういちど おします。',
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final area = RoomArea.values[_index];
    final photo = _photos[_index];
    final last = _index == _photos.length - 1;
    final step = _index + 1;
    final count = _photos.length;
    final progress = _reviewing
        ? s.tr(
            '確認 $step / $count',
            'Review $step of $count',
            'かくにん $step / $count',
          )
        : s.tr(
            '撮影 $step / $count',
            'Photo $step of $count',
            'しゃしん $step / $count',
          );
    final footer = _reviewing
        ? ActionPanel(
            primary: AppButton(
              label: _busy
                  ? s.tr('保存中…', 'Saving…')
                  : last
                  ? s.tr('確認済みにして保存', 'Mark reviewed and save', 'かくにんして ほぞん')
                  : s.tr('確認した', 'Mark reviewed', 'かくにんした'),
              onPressed: _busy ? null : () => _finishStep(true),
            ),
            secondary: AppButton(
              label: last
                  ? s.tr('未確認のまま保存', 'Save for later', 'あとで かくにん')
                  : s.tr('あとで確認', 'Review later', 'あとで みる'),
              outlined: true,
              onPressed: _busy ? null : () => _finishStep(false),
            ),
          )
        : photo == null
        ? null
        : ActionPanel(
            primary: AppButton(
              label: _busy
                  ? s.tr('写真を確認中…', 'Checking photos…', 'しゃしんを みています…')
                  : last
                  ? _analyzePhoto == null
                        ? s.tr(
                            '写真の確認に進む',
                            'Continue to photo review',
                            'しゃしんの かくにんに すすむ',
                          )
                        : s.tr(
                            '3枚の写真を判定する',
                            'Check all 3 photos',
                            '3まいの しゃしんを みる',
                          )
                  : s.tr(
                      'この写真で次へ',
                      'Use this photo and continue',
                      'この しゃしんで すすむ',
                    ),
              onPressed: _busy ? null : _nextPhoto,
            ),
          );

    return PopScope<void>(
      canPop:
          !_busy &&
          !_reviewing &&
          _index == 0 &&
          _photos.every((photo) => photo == null),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: DetailPage(
        title: _reviewing
            ? _analyzePhoto == null
                  ? s.tr('写真を確認', 'Review photos', 'しゃしんを たしかめる')
                  : s.tr('判定を確認', 'Review findings', 'けっかを みる')
            : s.tr('部屋を撮影', 'Photograph the room', 'へやを とる'),
        onBack: _back,
        child: TaskBody(
          controller: _scroll,
          footer: footer,
          children: [
            Text(progress, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: step / count,
              semanticsLabel: progress,
            ),
            const SizedBox(height: 16),
            PageHeader(title: inspectionAreaLabel(s, area)),
            if (!_reviewing) ...[
              Text(_areas[area]!.instruction.forDemo(s)),
              const SizedBox(height: 14),
            ],
            if (photo != null) ...[
              InspectionPicture(
                bytes: photo,
                label: inspectionAreaLabel(s, area),
              ),
              const SizedBox(height: 14),
            ],
            if (_reviewing) ...[
              _Finding(area: area, flagged: _flagged[_index]),
              if (_reviewed[_index] case final reviewed?) ...[
                const SizedBox(height: 12),
                ActionStatus(
                  reviewed
                      ? s.tr('確認済み', 'Reviewed', 'かくにんした')
                      : s.tr('未確認', 'Not yet reviewed', 'まだ みていない'),
                  tone: reviewed ? StatusTone.complete : StatusTone.pending,
                ),
              ],
            ] else ...[
              if (canTakePhoto) ...[
                AppButton(
                  label: photo == null
                      ? s.tr('写真を撮る', 'Take a photo', 'しゃしんを とる')
                      : s.tr('撮り直す', 'Retake photo', 'とりなおす'),
                  onPressed: _busy ? null : () => _choose(ImageSource.camera),
                  outlined: photo != null,
                ),
                const SizedBox(height: 8),
              ],
              AppButton(
                label: s.tr('写真を選ぶ', 'Choose a photo', 'しゃしんを えらぶ'),
                outlined: canTakePhoto || photo != null,
                onPressed: _busy ? null : () => _choose(ImageSource.gallery),
              ),
            ],
            if (_error case final message?) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(message, style: const TextStyle(color: red)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Finding extends StatelessWidget {
  final RoomArea area;
  final bool flagged;
  const _Finding({required this.area, required this.flagged});

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    return SurfaceCard(
      color: flagged ? paleYellow : wash,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            flagged
                ? s.tr('AIが挙げた確認箇所', 'AI check suggestion', 'AIが えらんだ ばしょ')
                : s.tr('目で確認する箇所', 'Check in person', 'めで たしかめる ばしょ'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 5),
          if (flagged) Text(_areas[area]!.finding.forDemo(s)),
          Text(_areas[area]!.action.forDemo(s)),
        ],
      ),
    );
  }
}

class InspectionPicture extends StatelessWidget {
  final Uint8List bytes;
  final String label;
  const InspectionPicture({
    super.key,
    required this.bytes,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: wash,
        child: Stack(
          alignment: AlignmentDirectional.bottomEnd,
          children: [
            Image.memory(
              bytes,
              semanticLabel: label,
              width: double.infinity,
              height: 225,
              fit: BoxFit.contain,
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: IconButton.filled(
                tooltip: s.tr('写真を拡大', 'Enlarge photo', 'しゃしんを おおきく みる'),
                onPressed: () => showDialog<void>(
                  context: context,
                  useSafeArea: false,
                  builder: (context) => Dialog.fullscreen(
                    child: Scaffold(
                      appBar: AppBar(title: Text(label)),
                      body: SafeArea(
                        child: InteractiveViewer(
                          maxScale: 4,
                          child: SizedBox.expand(
                            child: Image.memory(
                              bytes,
                              semanticLabel: label,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                icon: const Icon(Icons.zoom_in_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RoomHistoryScreen extends StatefulWidget {
  final RoomInspection inspection;
  final bool sample;
  const RoomHistoryScreen({
    super.key,
    required this.inspection,
    this.sample = false,
  });
  @override
  State<RoomHistoryScreen> createState() => _RoomHistoryScreenState();
}

class _RoomHistoryScreenState extends State<RoomHistoryScreen> {
  final _scroll = ScrollController();
  int _index = 0;
  Future<Uint8List?>? _image;
  String? _key;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _show(int index) {
    setState(() => _index = index);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final index = s.roomInspections.indexWhere(
      (item) => item.time == widget.inspection.time,
    );
    final entry = index == -1 ? widget.inspection : s.roomInspections[index];
    final photo = entry.photos[_index];
    if (_key != photo.photoKey) {
      _key = photo.photoKey;
      _image = s.postPhotos.read(photo.photoKey);
    }
    final title = widget.sample
        ? s.tr('過去のAI点検サンプル', 'Example inspection', 'てんけんの れい')
        : s.tr('点検の記録', 'Inspection record', 'てんけんの きろく');
    return PrototypePage(
      title: title,
      controller: _scroll,
      footer: ActionPanel(
        primary: AppButton(
          label: _index == entry.photos.length - 1
              ? s.tr('履歴に戻る', 'Back to history', 'きろくに もどる')
              : s.tr('次の写真', 'Next photo', 'つぎの しゃしん'),
          onPressed: _index == entry.photos.length - 1
              ? () => Navigator.pop(context)
              : () => _show(_index + 1),
        ),
        secondary: _index == 0
            ? null
            : AppButton(
                label: s.tr('前の写真', 'Previous photo', 'まえの しゃしん'),
                outlined: true,
                onPressed: () => _show(_index - 1),
              ),
      ),
      children: [
        Text(
          '${MaterialLocalizations.of(context).formatCompactDate(entry.time)}  ·  ${_index + 1} / ${entry.photos.length}',
        ),
        const SizedBox(height: 8),
        PageHeader(title: inspectionAreaLabel(s, photo.area)),
        FutureBuilder<Uint8List?>(
          future: _image,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LinearProgressIndicator();
            }
            final bytes = snapshot.data;
            if (bytes == null) {
              return Text(
                s.tr('写真を開けませんでした', 'Photo unavailable', 'しゃしんを ひらけませんでした'),
              );
            }
            return InspectionPicture(
              bytes: bytes,
              label: inspectionAreaLabel(s, photo.area),
            );
          },
        ),
        const SizedBox(height: 12),
        _Finding(area: photo.area, flagged: photo.flagged),
        if (widget.sample || index == -1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              photo.reviewed
                  ? s.tr('確認済み', 'Reviewed', 'かくにんした')
                  : s.tr('未確認', 'Not yet reviewed', 'まだ みていない'),
            ),
          )
        else
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              s.tr('この箇所を確認した', 'I checked this area', 'この ばしょを かくにんした'),
            ),
            value: photo.reviewed,
            onChanged: (value) => s.update(() {
              final photos = [...entry.photos];
              photos[_index] = (
                area: photo.area,
                photoKey: photo.photoKey,
                flagged: photo.flagged,
                reviewed: value == true,
              );
              s.roomInspections[index] = (
                time: entry.time,
                photos: List.unmodifiable(photos),
              );
            }),
          ),
      ],
    );
  }
}
