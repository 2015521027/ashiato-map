import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_drawing/path_drawing.dart';
import 'package:xml/xml.dart';

import 'models.dart';

/// 1都道府県分の描画パス(SVG座標系: viewBox 0 0 1000 1000)
class PrefShape {
  final int code;
  final Path path;
  PrefShape(this.code, this.path);
}

/// 地図データ一式(都道府県パス+離島と本土の区切り線)
class JapanMapData {
  final List<PrefShape> shapes;
  final Path boundaries;
  JapanMapData(this.shapes, this.boundaries);
}

final RegExp _translateRe =
    RegExp(r'translate\(\s*([-\d.]+)[,\s]+([-\d.]+)\s*\)');
final RegExp _matrixRe = RegExp(r'matrix\(([^)]+)\)');

/// assets/japan.svg(geolonia/japanese-prefectures)を読み込み、
/// 都道府県ごとの描画・タップ判定用 Path に変換する。
Future<JapanMapData> loadJapanMap() async {
  final text = await rootBundle.loadString('assets/japan.svg');
  final doc = XmlDocument.parse(text);

  // 外側の g.svg-map に付く matrix(a,b,c,d,e,f) 変換を取得
  Float64List? outer;
  for (final g in doc.findAllElements('g')) {
    if (!(g.getAttribute('class') ?? '').contains('svg-map')) continue;
    final m = _matrixRe.firstMatch(g.getAttribute('transform') ?? '');
    if (m != null) {
      final v = m
          .group(1)!
          .split(RegExp(r'[,\s]+'))
          .where((s) => s.isNotEmpty)
          .map(double.parse)
          .toList();
      if (v.length == 6) {
        outer = Float64List.fromList([
          v[0], v[1], 0, 0, //
          v[2], v[3], 0, 0, //
          0, 0, 1, 0, //
          v[4], v[5], 0, 1, //
        ]);
      }
    }
    break;
  }

  final shapes = <PrefShape>[];
  for (final g in doc.findAllElements('g')) {
    final code = int.tryParse(g.getAttribute('data-code') ?? '');
    if (code == null) continue;

    double tx = 0, ty = 0;
    final tm = _translateRe.firstMatch(g.getAttribute('transform') ?? '');
    if (tm != null) {
      tx = double.parse(tm.group(1)!);
      ty = double.parse(tm.group(2)!);
    }

    var combined = Path();
    for (final p in g.findAllElements('path')) {
      final d = p.getAttribute('d');
      if (d != null) combined.addPath(parseSvgPathData(d), Offset.zero);
    }
    for (final poly in g.findAllElements('polygon')) {
      final pts = (poly.getAttribute('points') ?? '')
          .split(RegExp(r'[,\s]+'))
          .where((s) => s.isNotEmpty)
          .map(double.parse)
          .toList();
      if (pts.length >= 6) {
        final path = Path()..moveTo(pts[0], pts[1]);
        for (var i = 2; i + 1 < pts.length; i += 2) {
          path.lineTo(pts[i], pts[i + 1]);
        }
        path.close();
        combined.addPath(path, Offset.zero);
      }
    }

    combined = combined.shift(Offset(tx, ty));
    if (outer != null) combined = combined.transform(outer);
    shapes.add(PrefShape(code, combined));
  }

  // 離島(沖縄・奄美など)と本土を区切る線
  var boundaries = Path();
  for (final line in doc.findAllElements('line')) {
    final x1 = double.tryParse(line.getAttribute('x1') ?? '');
    final y1 = double.tryParse(line.getAttribute('y1') ?? '');
    final x2 = double.tryParse(line.getAttribute('x2') ?? '');
    final y2 = double.tryParse(line.getAttribute('y2') ?? '');
    if (x1 == null || y1 == null || x2 == null || y2 == null) continue;
    boundaries.moveTo(x1, y1);
    boundaries.lineTo(x2, y2);
  }
  if (outer != null) boundaries = boundaries.transform(outer);

  return JapanMapData(shapes, boundaries);
}

/// 日本地図ウィジェット。ランクに応じて塗り分け、タップで都道府県を通知する。
/// ピンチズーム対応(小さい県は拡大してタップできる)。
class JapanMap extends StatelessWidget {
  final JapanMapData data;
  final Map<int, int> rankByCode;
  final ValueChanged<int> onPrefTap;

  const JapanMap({
    super.key,
    required this.data,
    required this.rankByCode,
    required this.onPrefTap,
  });

  static const double _viewBox = 1000;

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      maxScale: 8,
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(builder: (context, c) {
            final scale = c.maxWidth / _viewBox;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) {
                final p = d.localPosition / scale;
                for (final s in data.shapes.reversed) {
                  if (s.path.contains(p)) {
                    onPrefTap(s.code);
                    return;
                  }
                }
              },
              child: CustomPaint(
                size: Size(c.maxWidth, c.maxWidth),
                painter: _JapanMapPainter(
                  data: data,
                  rankByCode: rankByCode,
                  scale: scale,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _JapanMapPainter extends CustomPainter {
  final JapanMapData data;
  final Map<int, int> rankByCode;
  final double scale;

  _JapanMapPainter({
    required this.data,
    required this.rankByCode,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(scale);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF546E7A)
      ..strokeWidth = 1.2;
    for (final s in data.shapes) {
      final fill = Paint()
        ..style = PaintingStyle.fill
        ..color = rankDef(rankByCode[s.code] ?? 0).color;
      canvas.drawPath(s.path, fill);
      canvas.drawPath(s.path, stroke);
    }
    // 離島と本土の区切り線(灰色の破線)
    final boundaryPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF9E9E9E)
      ..strokeWidth = 3;
    canvas.drawPath(
      dashPath(
        data.boundaries,
        dashArray: CircularIntervalList<double>([14, 10]),
      ),
      boundaryPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _JapanMapPainter old) =>
      old.rankByCode != rankByCode || old.data != data || old.scale != scale;
}
