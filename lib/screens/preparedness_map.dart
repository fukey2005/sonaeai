import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../mock/demo_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/prototype.dart';

typedef _Shelter = ({UiCopy name, String address, LatLng location});
typedef LocateOnMap = Future<LatLng> Function();
const _area = LatLng(35.6900, 139.8335);
const _mapTiles = 'https://cyberjapandata.gsi.go.jp/xyz/pale/{z}/{x}/{y}.png';
const _floodTiles =
    'https://disaportaldata.gsi.go.jp/raster/01_flood_l2_shinsuishin_data/{z}/{x}/{y}.png';
final _tileSource = Uri.parse(
  'https://maps.gsi.go.jp/development/ichiran.html',
);
final _floodSource = Uri.parse(
  'https://disaportal.gsi.go.jp/hazardmapportal/hazardmap/copyright/opendata.html',
);
final _wardMap = Uri.parse('https://bosai.city.koto.lg.jp/');

// Coordinates come from GSI's general shelter data (sih). These schools
// are listed as base shelters by Koto City.
const _earthquakeShelters = <_Shelter>[
  (
    name: ('第四大島小学校', 'Daiyon Ojima Elementary', 'だいよん おおじま しょうがっこう'),
    address: '大島6-7-8',
    location: LatLng(35.691234, 139.834030),
  ),
  (
    name: ('大島中学校', 'Ojima Junior High', 'おおじま ちゅうがっこう'),
    address: '大島8-12-22',
    location: LatLng(35.686457, 139.839859),
  ),
  (
    name: ('大島南央小学校', 'Ojima Nanao Elementary', 'おおじま なんおう しょうがっこう'),
    address: '大島4-18-5',
    location: LatLng(35.687238, 139.831582),
  ),
  (
    name: ('第二大島中学校', 'Daini Ojima Junior High', 'だいに おおじま ちゅうがっこう'),
    address: '大島3-27-18',
    location: LatLng(35.691868, 139.831102),
  ),
];

// Koto City lists these estate common areas as temporary flood facilities.
// The pins show each estate, using coordinates from UR's estate inventory.
const _floodShelters = <_Shelter>[
  (
    name: ('UR大島六丁目団地', 'UR Ojima 6-chome', 'おおじま 6ちょうめ だんち'),
    address: '大島6-1',
    location: LatLng(35.689695, 139.832668),
  ),
  (
    name: ('UR大島四丁目団地', 'UR Ojima 4-chome', 'おおじま 4ちょうめ だんち'),
    address: '大島4-1',
    location: LatLng(35.688306, 139.82784),
  ),
];
final _floodFacilities = Uri.parse(
  'https://www.city.koto.lg.jp/057101/bosai/bosai-top/taiou/map_7077_6000.html',
);
final _earthquakeAreas = Uri.parse(
  'https://www.city.koto.lg.jp/057101/bosai/bosai-top/taiou/map_7077_7080/index.html',
);

enum _LocationIssue { disabled, permission, unavailable }

Future<LatLng> _locate() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw _LocationIssue.disabled;
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw _LocationIssue.permission;
  }
  final pos = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 12),
    ),
  );
  return LatLng(pos.latitude, pos.longitude);
}

class PreparednessMapScreen extends StatefulWidget {
  final bool inTab;
  final bool showFlood;
  final LocateOnMap locate;
  const PreparednessMapScreen({
    super.key,
    this.inTab = false,
    this.showFlood = false,
    this.locate = _locate,
  });

  @override
  State<PreparednessMapScreen> createState() => _PreparednessMapScreenState();
}

class _PreparednessMapScreenState extends State<PreparednessMapScreen> {
  final _map = MapController();
  late bool _flood = widget.showFlood;
  bool _gettingLocation = false;
  bool _showTileError = false;
  int _mapRevision = 0;
  LatLng? _current;
  _LocationIssue? _issue;
  bool _practiceMarker = false;

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  Future<void> _moveToCurrent() async {
    if (_gettingLocation) return;
    setState(() {
      _gettingLocation = true;
      _issue = null;
    });
    try {
      final current = await widget.locate();
      if (!mounted) return;
      if (current.latitude < 20 ||
          current.latitude > 47 ||
          current.longitude < 120 ||
          current.longitude > 155) {
        setState(() => _issue = _LocationIssue.unavailable);
        return;
      }
      setState(() => _current = current);
      _map.move(current, 16);
    } catch (error) {
      if (mounted) {
        setState(
          () => _issue = error is _LocationIssue
              ? error
              : _LocationIssue.unavailable,
        );
      }
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  String _locationMessage(DemoState s) => switch (_issue) {
    _LocationIssue.disabled => s.tr(
      '端末の位置情報をオンにしてください。',
      'Turn on Location Services on your device.',
      'たんまつの いちじょうほうを オンにします。',
    ),
    _LocationIssue.permission => s.tr(
      '位置情報の利用が許可されていません。端末やブラウザーの設定を確認してください。',
      'Location access is blocked. Check device or browser settings.',
      'いちじょうほうを つかえません。たんまつの せっていを みてください。',
    ),
    _ => s.tr(
      '現在地を表示できません。団地周辺の地図は引き続き見られます。',
      'Current location is unavailable. You can still view the estate map.',
      'いまの ばしょを みられません。だんちの ちずは みられます。',
    ),
  };

  void _tileError() {
    if (_showTileError || !mounted) return;
    setState(() => _showTileError = true);
  }

  Future<void> _openSource(BuildContext context, Uri url) async {
    final s = DemoScope.of(context);
    try {
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) return;
    } catch (_) {}
    if (context.mounted) {
      showNotice(context, s.tr('リンクを開けませんでした', 'Could not open this link'));
    }
  }

  String _distance(DemoState s, LatLng target) {
    final meters = const Distance().as(LengthUnit.Meter, _current!, target);
    final value = meters < 1000
        ? '${meters.round()} m'
        : '${(meters / 1000).toStringAsFixed(1)} km';
    return s.tr(
      '現在地から直線で $value',
      '$value in a straight line from here',
      'いまの ばしょから $value',
    );
  }

  void _showShelter(_Shelter shelter) {
    FocusManager.instance.primaryFocus?.unfocus();
    final s = DemoScope.of(context);
    final isFlood = _flood;
    final directions = Uri.https('maps.apple.com', '/directions', {
      'destination':
          '${shelter.location.latitude},${shelter.location.longitude}',
      'mode': 'walking',
    });
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(title: shelter.name.forDemo(s)),
              Text(
                isFlood
                    ? s.tr(
                        '水害時の一時避難施設  ·  ${shelter.address}',
                        'Temporary flood refuge · ${shelter.address}',
                        'すいがいで いちじてきに にげる ばしょ  ·  ${shelter.address}',
                      )
                    : s.tr(
                        '拠点避難所  ·  ${shelter.address}',
                        'Base shelter · ${shelter.address}',
                        'ひなんじょ  ·  ${shelter.address}',
                      ),
              ),
              if (isFlood)
                Text(
                  s.tr(
                    '3階以上の共用部（屋上を除く）',
                    'Shared spaces on the third floor or above, excluding the roof.',
                    '3かい いじょうの みんなが つかう ところ。おくじょうは のぞきます。',
                  ),
                ),
              if (_current != null) Text(_distance(s, shelter.location)),
              const SizedBox(height: 12),
              Text(
                s.tr(
                  '開設状況と災害の種類に合った避難先は、江東区の案内で確認してください。',
                  'Check Koto City’s guidance for opening status and a place suited to the hazard.',
                  'あいているか、さいがいに あう ばしょかを、こうとうくの おしらせで みます。',
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: isFlood
                    ? s.tr(
                        '江東区の利用条件を確認',
                        'Check Koto City’s access conditions',
                        'こうとうくの つかいかたを みる',
                      )
                    : s.tr(
                        '地図アプリで経路を開く',
                        'Open directions in Maps',
                        'ちず アプリで みちを みる',
                      ),
                onPressed: () => _openSource(
                  context,
                  isFlood ? _floodFacilities : directions,
                ),
              ),
              TextButton(
                onPressed: () => _openSource(context, _wardMap),
                child: Text(
                  s.tr(
                    '江東区の防災マップ',
                    'Koto City disaster maps',
                    'こうとうくの ぼうさい ちず',
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(s.tr('閉じる', 'Close', 'とじる')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = DemoScope.of(context);
    final places = _flood ? _floodShelters : _earthquakeShelters;
    final showSample = s.isEmergency && _practiceMarker && _current == null;
    final title = s.tr('ハザードマップ', 'Hazard map', 'きけんな ばしょの ちず');
    final content = TaskBody(
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilterTabs(
              labels: [
                s.tr('地震', 'Earthquake', 'じしん'),
                s.tr('洪水', 'Flood', 'こうずい'),
              ],
              selected: _flood ? 1 : 0,
              onChanged: (index) => setState(() => _flood = index == 1),
            ),
            OutlinedButton.icon(
              onPressed: _gettingLocation ? null : _moveToCurrent,
              icon: _gettingLocation
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded, size: 19),
              label: Text(s.tr('現在地', 'Current location', 'いまの ばしょ')),
            ),
          ],
        ),
        if (_issue != null) ...[
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              _locationMessage(s),
              style: const TextStyle(color: red),
            ),
          ),
        ],
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 296,
            width: double.infinity,
            child: FlutterMap(
              mapController: _map,
              options: const MapOptions(
                initialCenter: _area,
                initialZoom: 15.2,
                minZoom: 5,
                maxZoom: 18,
                backgroundColor: wash,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  key: ValueKey(_mapRevision),
                  urlTemplate: _mapTiles,
                  maxNativeZoom: 18,
                  userAgentPackageName: 'jp.ac.tid.neoJichikai',
                  errorTileCallback: (_, _, _) => _tileError(),
                ),
                if (_flood)
                  Opacity(
                    opacity: .65,
                    child: TileLayer(
                      urlTemplate: _floodTiles,
                      maxNativeZoom: 17,
                      userAgentPackageName: 'jp.ac.tid.neoJichikai',
                    ),
                  ),
                MarkerLayer(
                  markers: [
                    for (final place in places)
                      Marker(
                        point: place.location,
                        width: 48,
                        height: 48,
                        child: IconButton.filled(
                          tooltip: place.name.forDemo(s),
                          style: IconButton.styleFrom(
                            backgroundColor: yellow,
                            foregroundColor: ink,
                          ),
                          onPressed: () => _showShelter(place),
                          icon: const Icon(Icons.place_rounded, size: 23),
                        ),
                      ),
                    if (showSample)
                      Marker(
                        point: const LatLng(35.6916, 139.8333),
                        width: 38,
                        height: 38,
                        child: Tooltip(
                          message: s.tr(
                            '訓練の現在地',
                            'Practice location',
                            'くんれんの いまの ばしょ',
                          ),
                          child: const CircleAvatar(
                            backgroundColor: blue,
                            foregroundColor: paper,
                            child: Icon(Icons.my_location_rounded),
                          ),
                        ),
                      ),
                    if (_current case final current?)
                      Marker(
                        point: current,
                        width: 24,
                        height: 24,
                        child: Semantics(
                          label: s.tr('現在地', 'Current location', 'いまの ばしょ'),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: paper, width: 3),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_showTileError)
          TextButton(
            onPressed: () => setState(() {
              _showTileError = false;
              _mapRevision++;
            }),
            child: Text(s.tr('地図を再読み込み', 'Reload map', 'ちずを よみなおす')),
          ),
        Wrap(
          spacing: 10,
          children: [
            TextButton(
              onPressed: () => _map.move(_area, 15.2),
              child: Text(
                s.tr('団地周辺に戻る', 'Back to the estate', 'だんちの ちかくへ もどる'),
              ),
            ),
            TextButton(
              onPressed: () => _openSource(context, _tileSource),
              child: Text(s.tr('地図：国土地理院', 'Map: GSI', 'ちず：こくどちりいん')),
            ),
          ],
        ),
        if (_flood) ...[
          Text(
            s.tr(
              '想定最大規模の洪水で見込まれる浸水の深さを表示しています。着色のない場所にも未公表の区域があります。',
              'Colors show expected depth in a maximum-scale flood. Some uncolored areas have no published data.',
              'とても おおきな こうずいで みずが どのくらい くるかを しめします。いろが ない ところにも、わからない ところが あります。',
            ),
          ),
          TextButton(
            onPressed: () => _openSource(context, _floodSource),
            child: Text(
              s.tr('浸水想定の凡例・出典', 'Flood legend & sources', 'みずの ふかさの いろと しりょう'),
            ),
          ),
        ],
        const SizedBox(height: 14),
        if (s.isEmergency && _current == null)
          TextButton(
            onPressed: () {
              setState(() => _practiceMarker = !_practiceMarker);
              if (_practiceMarker) _map.move(_area, 15.2);
            },
            child: Text(
              _practiceMarker
                  ? s.tr(
                      '訓練の現在地を隠す',
                      'Hide practice location',
                      'くんれんの ばしょを かくす',
                    )
                  : s.tr(
                      '訓練の現在地を表示',
                      'Show practice location',
                      'くんれんの ばしょを みる',
                    ),
            ),
          ),
        PageHeader(
          title: _flood
              ? s.tr(
                  '洪水時の一時避難施設',
                  'Temporary flood refuges',
                  'こうずいの とき にげる ばしょ',
                )
              : s.tr(
                  '地震時の拠点避難所',
                  'Base shelters for earthquakes',
                  'じしんの ときの ひなんじょ',
                ),
        ),
        if (!_flood)
          TextButton(
            onPressed: () => _openSource(context, _earthquakeAreas),
            child: Text(
              s.tr(
                '大島・北砂団地一帯の避難場所を確認',
                'Check Ojima–Kitasuna’s designated evacuation area',
                'おおじま・きたすなの ひなんばしょを みる',
              ),
            ),
          ),
        for (final place in places) ...[
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 5,
            ),
            title: Text(place.name.forDemo(s)),
            subtitle: Text(
              _flood
                  ? s.tr(
                      '${place.address} · 3階以上の共用部',
                      '${place.address} · Shared spaces, floor 3+',
                      '${place.address} · 3かい いじょう',
                    )
                  : place.address,
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showShelter(place),
          ),
          const Divider(),
        ],
        TextButton(
          onPressed: () => _openSource(context, _wardMap),
          child: Text(
            s.tr(
              '江東区の防災マップ・避難所一覧',
              'Koto City maps & shelter information',
              'こうとうくの ちずと ひなんじょ',
            ),
          ),
        ),
      ],
    );
    return widget.inTab ? content : DetailPage(title: title, child: content);
  }
}
