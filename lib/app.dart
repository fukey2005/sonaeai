import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'mock/demo_state.dart';
import 'theme/app_theme.dart';
import 'screens/home.dart';

class NeoApp extends StatefulWidget {
  final DemoState? initialState;
  const NeoApp({super.key, this.initialState});
  @override
  State<NeoApp> createState() => _NeoAppState();
}

class _NeoAppState extends State<NeoApp> {
  late final state = widget.initialState ?? DemoState();
  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DemoScope(
    state: state,
    child: AnimatedBuilder(
      animation: state,
      builder: (context, _) => MaterialApp(
        title: 'そなえあい',
        debugShowCheckedModeBanner: false,
        theme: appTheme(state.highContrast),
        locale: Locale(state.language == AppLanguage.english ? 'en' : 'ja'),
        supportedLocales: const [Locale('ja'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => _DemoStage(state: state, child: child!),
        home: const HomeShell(),
      ),
    ),
  );
}

class _DemoStage extends StatelessWidget {
  final DemoState state;
  final Widget child;
  const _DemoStage({required this.state, required this.child});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final media = MediaQuery.of(context);
      final scale = math
          .max(media.textScaler.scale(1), state.fontScale)
          .clamp(1.0, 2.0);
      if (!kIsWeb || box.maxWidth < 600) {
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(scale)),
          child: child,
        );
      }
      final height = math.max(320.0, math.min(900.0, box.maxHeight - 32));
      return ColoredBox(
        color: const Color(0xFFFAFAFA),
        child: Center(
          child: Container(
            width: 432,
            height: height,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: line),
              borderRadius: BorderRadius.circular(22),
            ),
            child: MediaQuery(
              data: media.copyWith(
                size: Size(430, height - 2),
                padding: EdgeInsets.zero,
                viewPadding: EdgeInsets.zero,
                textScaler: TextScaler.linear(scale),
              ),
              child: child,
            ),
          ),
        ),
      );
    },
  );
}
