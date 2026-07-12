import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'photo_store.dart';

/// アプリ全体のデータ保持と永続化(shared_preferences に JSON 文字列で保存)
class Store extends ChangeNotifier {
  static const _key = 'keiken_data_v1';

  final Map<int, PrefRecord> prefs = {
    for (final code in kPrefNames.keys) code: PrefRecord(),
  };

  /// 足跡スコア(全都道府県のランク合計。最大 235 点)
  int get score => prefs.values.fold(0, (sum, p) => sum + p.rank);

  int get visitedCount => prefs.values.where((p) => p.rank > 0).length;

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    if (raw == null) return;
    try {
      _applyJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // 壊れたデータは初期状態のまま起動する(上書き保存は次回操作時)
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, jsonEncode(_toJson()));
  }

  Map<String, dynamic> _toJson() => {
        'version': 1,
        'prefs': {
          for (final e in prefs.entries)
            if (e.value.rank != 0 || e.value.visits.isNotEmpty)
              '${e.key}': e.value.toJson(),
        },
      };

  void _applyJson(Map<String, dynamic> j) {
    final src = (j['prefs'] as Map<String, dynamic>?) ?? {};
    for (final code in kPrefNames.keys) {
      final rec = src['$code'];
      prefs[code] = rec == null
          ? PrefRecord()
          : PrefRecord.fromJson(rec as Map<String, dynamic>);
    }
  }

  void setRank(int code, int rank) {
    prefs[code]!.rank = rank;
    _save();
    notifyListeners();
  }

  void upsertVisit(int code, Visit visit) {
    final visits = prefs[code]!.visits;
    final i = visits.indexWhere((v) => v.id == visit.id);
    if (i >= 0) {
      visits[i] = visit;
    } else {
      visits.add(visit);
    }
    visits.sort((a, b) => b.date.compareTo(a.date));
    _save();
    notifyListeners();
  }

  void deleteVisit(int code, String visitId) {
    final visits = prefs[code]!.visits;
    final i = visits.indexWhere((v) => v.id == visitId);
    if (i >= 0) {
      for (final photoId in visits[i].photos) {
        PhotoStore.instance.delete(photoId);
      }
      visits.removeAt(i);
    }
    _save();
    notifyListeners();
  }

  /// バックアップ用 JSON 文字列(整形済み)
  String exportJson() => const JsonEncoder.withIndent('  ').convert(_toJson());

  /// JSON 文字列からの復元。成功したら true。
  bool importJson(String raw) {
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      if (j['prefs'] is! Map) return false;
      _applyJson(j);
      _save();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
