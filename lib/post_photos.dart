import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive_ce_flutter/hive_flutter.dart';

class PostPhotos {
  static const prefix = 'post/photo/';
  final LazyBox<dynamic>? _disk;
  final _temporary = <String, Uint8List>{};
  int _sequence = 0;

  PostPhotos([this._disk]);

  Future<Uint8List?> read(String key) async {
    if (key.startsWith('assets/samples/')) {
      final data = await rootBundle.load(key);
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    }
    return _disk == null ? _temporary[key] : await _disk.get(key) as Uint8List?;
  }

  Future<String> save(Uint8List bytes) async {
    final disk = _disk;
    final stamp = DateTime.now().microsecondsSinceEpoch;
    String key;
    do {
      key = '$prefix$stamp-${_sequence++}';
    } while (disk?.containsKey(key) ?? _temporary.containsKey(key));
    if (disk == null) {
      _temporary[key] = bytes;
    } else {
      await disk.put(key, bytes);
    }
    return key;
  }
}
