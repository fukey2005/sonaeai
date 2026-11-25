import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'mock/demo_state.dart';

typedef PickPhoto = Future<Uint8List?> Function(ImageSource source);

bool get canTakePhoto =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.android;

Future<Uint8List?> pickPhoto(ImageSource source) async {
  final file = await ImagePicker().pickImage(
    source: source,
    maxWidth: 1440,
    maxHeight: 1440,
    imageQuality: 87,
    requestFullMetadata: false,
  );
  if (file == null) return null;
  if (await file.length() > 20 * 1024 * 1024) {
    throw const FormatException('Photo exceeds the size limit');
  }

  // Decode once so errors can be reported before showing an empty preview.
  // Re-encoding also keeps camera metadata out of posts and shared images.
  final codec = await ui.instantiateImageCodecWithSize(
    await ui.ImmutableBuffer.fromUint8List(await file.readAsBytes()),
    getTargetSize: (width, height) => width >= height
        ? ui.TargetImageSize(width: width.clamp(1, 1440))
        : ui.TargetImageSize(height: height.clamp(1, 1440)),
  );
  try {
    final frame = await codec.getNextFrame();
    try {
      final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw const FormatException('Photo cannot be decoded');
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } finally {
      frame.image.dispose();
    }
  } finally {
    codec.dispose();
  }
}

Future<ImageSource?> choosePhotoSource(BuildContext context) {
  if (!canTakePhoto) return Future.value(ImageSource.gallery);
  final s = DemoScope.of(context);
  return showModalBottomSheet<ImageSource>(
    context: context,
    useSafeArea: true,
    builder: (context) => SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(s.tr('写真を撮る', 'Take a photo', 'しゃしんを とる')),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_outlined),
            title: Text(s.tr('写真を選ぶ', 'Choose a photo', 'しゃしんを えらぶ')),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          ListTile(
            title: Text(s.tr('キャンセル', 'Cancel', 'やめる')),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    ),
  );
}

String photoError(DemoState s, Object error) {
  if (error is PlatformException) {
    if (error.code.contains('access_denied') ||
        error.code.contains('access_restricted')) {
      return s.tr(
        '写真にアクセスできません。端末の設定で許可するか、別の方法で写真を追加してください。',
        'Photo access is blocked. Check device permissions or use the other photo option.',
        'しゃしんを つかえません。たんまつの せっていを みるか、べつの ほうほうで えらんでください。',
      );
    }
    if (error.code.contains('camera')) {
      return s.tr(
        'カメラを開けません。撮影済みの写真を選べます。',
        'The camera could not open. You can choose an existing photo.',
        'カメラを ひらけません。とった しゃしんを えらべます。',
      );
    }
  }
  return s.tr(
    '写真を開けませんでした。別の写真を選んでください。',
    'The photo could not be opened. Choose another image.',
    'しゃしんを ひらけませんでした。べつの しゃしんを えらんでください。',
  );
}
