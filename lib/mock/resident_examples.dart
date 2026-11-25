import 'demo_state.dart';

const _exampleId = 'example-stairs';

DemoBoardPost residentExample(DemoState s) => (
  id: _exampleId,
  body: s.tr(
    '北側の階段で手すりのぐらつきに気づきました。通るときにご注意ください。',
    'The handrail on the north stairs feels loose. Take care when passing.',
    'きたの かいだんの てすりが ぐらぐらします。とおる ときに きを つけてください。',
  ),
  topic: BoardTopic.hazard,
  place: s.tr('2号棟・北側階段', 'Building 2 · North stairs', '2ごうとうの きたの かいだん'),
  time: DateTime(2026, 11, 21, 16, 20),
  photoKey: 'assets/samples/stairs.jpg',
);

bool isResidentExample(DemoBoardPost post) => post.id == _exampleId;
