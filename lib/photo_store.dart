import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 大きい画像を長辺1600px・JPEG品質80に縮小する(compute用のトップレベル関数)
Uint8List downscaleImage(Uint8List bytes) {
  try {
    var decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    decoded = img.bakeOrientation(decoded);
    if (decoded.width > 1600 || decoded.height > 1600) {
      decoded = decoded.width >= decoded.height
          ? img.copyResize(decoded, width: 1600)
          : img.copyResize(decoded, height: 1600);
    }
    return Uint8List.fromList(img.encodeJpg(decoded, quality: 80));
  } catch (_) {
    return bytes;
  }
}

/// 写真の保存先を抽象化する。
/// Android: アプリ内ドキュメントフォルダの photos/ 配下に JPEG ファイルで保存。
/// Web: shared_preferences(localStorage)に base64 で保存。
class PhotoStore {
  PhotoStore._();
  static final PhotoStore instance = PhotoStore._();

  final Map<String, Uint8List> _cache = {};

  Future<Directory> _photoDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/photos');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<String> save(Uint8List bytes) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    if (kIsWeb) {
      final sp = await SharedPreferences.getInstance();
      await sp.setString('photo_$id', base64Encode(bytes));
    } else {
      final dir = await _photoDir();
      await File('${dir.path}/$id.jpg').writeAsBytes(bytes);
    }
    _cache[id] = bytes;
    return id;
  }

  Future<Uint8List?> load(String id) async {
    final hit = _cache[id];
    if (hit != null) return hit;
    try {
      if (kIsWeb) {
        final sp = await SharedPreferences.getInstance();
        final b64 = sp.getString('photo_$id');
        if (b64 == null) return null;
        final bytes = base64Decode(b64);
        _cache[id] = bytes;
        return bytes;
      } else {
        final dir = await _photoDir();
        final f = File('${dir.path}/$id.jpg');
        if (!await f.exists()) return null;
        final bytes = await f.readAsBytes();
        _cache[id] = bytes;
        return bytes;
      }
    } catch (_) {
      return null;
    }
  }

  Future<void> delete(String id) async {
    _cache.remove(id);
    try {
      if (kIsWeb) {
        final sp = await SharedPreferences.getInstance();
        await sp.remove('photo_$id');
      } else {
        final dir = await _photoDir();
        final f = File('${dir.path}/$id.jpg');
        if (await f.exists()) await f.delete();
      }
    } catch (_) {
      // 削除失敗は致命的ではないため握りつぶす(次回起動時に孤児ファイルとして残るだけ)
    }
  }
}
