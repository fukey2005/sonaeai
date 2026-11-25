import 'package:flutter/material.dart';
import 'app.dart';
import 'local_records.dart';
import 'mock/demo_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = DemoState();
  final records = LocalRecords();
  await records.attach(state);
  runApp(NeoApp(initialState: state));
}
