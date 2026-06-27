import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();
final _picker = ImagePicker();

/// 写真を撮影/選択し、アプリ領域へコピーして保存パスを返す。
/// Web では File 保存ができないため null を返す(写真なしで継続)。
Future<String?> pickAndStoreImage({bool fromCamera = false}) async {
  if (kIsWeb) return null;
  final XFile? picked = await _picker.pickImage(
    source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    maxWidth: 1600,
    imageQuality: 85,
  );
  if (picked == null) return null;

  final dir = await getApplicationDocumentsDirectory();
  final imagesDir = Directory('${dir.path}/images');
  if (!await imagesDir.exists()) {
    await imagesDir.create(recursive: true);
  }
  final ext = picked.name.contains('.') ? picked.name.split('.').last : 'jpg';
  final dest = '${imagesDir.path}/${_uuid.v4()}.$ext';
  await File(picked.path).copy(dest);
  return dest;
}
