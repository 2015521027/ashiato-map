import 'package:flutter/material.dart';

/// 経県値ランク定義(値・名称・説明・地図の塗り色)。定義はこのファイルに集約する。
class RankDef {
  final int value;
  final String label;
  final String desc;
  final Color color;
  const RankDef(this.value, this.label, this.desc, this.color);
}

const List<RankDef> kRanks = [
  RankDef(5, '居住', '住んだ', Color(0xFFE53935)),
  RankDef(4, '宿泊', '泊まった', Color(0xFFFB8C00)),
  RankDef(3, '訪問', '歩いた', Color(0xFFFDD835)),
  RankDef(2, '接地', '降り立った', Color(0xFF43A047)),
  RankDef(1, '通過', '通過した', Color(0xFF42A5F5)),
  RankDef(0, '未踏', '行ってない', Color(0xFFCFD8DC)),
];

RankDef rankDef(int value) => kRanks.firstWhere((r) => r.value == value);

/// 訪問記録の種別と表示色
const Map<String, Color> kCategories = {
  '旅行': Color(0xFF1E88E5),
  '出張': Color(0xFF5E35B1),
  '帰省': Color(0xFF43A047),
  'イベント': Color(0xFFF4511E),
  'その他': Color(0xFF757575),
};

/// 訪問記録(都道府県の子レコード)
class Visit {
  String id;
  DateTime date;
  String category;
  String title;
  String memo;

  /// 添付写真のID一覧(実体は PhotoStore が管理)
  List<String> photos;

  Visit({
    required this.id,
    required this.date,
    required this.category,
    required this.title,
    required this.memo,
    List<String>? photos,
  }) : photos = photos ?? [];

  String get dateLabel =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'date':
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'category': category,
        'title': title,
        'memo': memo,
        'photos': photos,
      };

  factory Visit.fromJson(Map<String, dynamic> j) => Visit(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String),
        category: (j['category'] as String?) ?? 'その他',
        title: (j['title'] as String?) ?? '',
        memo: (j['memo'] as String?) ?? '',
        photos: ((j['photos'] as List?) ?? []).cast<String>(),
      );
}

/// 都道府県1件分の記録(ランク+訪問記録リスト)
class PrefRecord {
  int rank;
  List<Visit> visits;

  PrefRecord({this.rank = 0, List<Visit>? visits}) : visits = visits ?? [];

  Map<String, dynamic> toJson() => {
        'rank': rank,
        'visits': visits.map((v) => v.toJson()).toList(),
      };

  factory PrefRecord.fromJson(Map<String, dynamic> j) => PrefRecord(
        rank: (j['rank'] as num?)?.toInt() ?? 0,
        visits: ((j['visits'] as List?) ?? [])
            .map((e) => Visit.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// 都道府県コード(JIS X 0401)→名称
const Map<int, String> kPrefNames = {
  1: '北海道', 2: '青森県', 3: '岩手県', 4: '宮城県', 5: '秋田県',
  6: '山形県', 7: '福島県', 8: '茨城県', 9: '栃木県', 10: '群馬県',
  11: '埼玉県', 12: '千葉県', 13: '東京都', 14: '神奈川県', 15: '新潟県',
  16: '富山県', 17: '石川県', 18: '福井県', 19: '山梨県', 20: '長野県',
  21: '岐阜県', 22: '静岡県', 23: '愛知県', 24: '三重県', 25: '滋賀県',
  26: '京都府', 27: '大阪府', 28: '兵庫県', 29: '奈良県', 30: '和歌山県',
  31: '鳥取県', 32: '島根県', 33: '岡山県', 34: '広島県', 35: '山口県',
  36: '徳島県', 37: '香川県', 38: '愛媛県', 39: '高知県', 40: '福岡県',
  41: '佐賀県', 42: '長崎県', 43: '熊本県', 44: '大分県', 45: '宮崎県',
  46: '鹿児島県', 47: '沖縄県',
};
