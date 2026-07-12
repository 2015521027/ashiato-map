import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'japan_map.dart';
import 'models.dart';
import 'pref_detail.dart';
import 'store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KeikenApp());
}

class KeikenApp extends StatelessWidget {
  const KeikenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '経県メモ',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFE07A2F),
        scaffoldBackgroundColor: const Color(0xFFF7F1E3),
        useMaterial3: true,
      ),
      locale: const Locale('ja'),
      supportedLocales: const [Locale('ja')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Store _store = Store();
  late final Future<JapanMapData> _mapFuture = loadJapanMap();
  bool _listMode = false;

  @override
  void initState() {
    super.initState();
    _store.load();
  }

  Map<int, int> get _ranks =>
      {for (final e in _store.prefs.entries) e.key: e.value.rank};

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('経県メモ'),
          actions: [
            PopupMenuButton<String>(
              onSelected: _onMenu,
              itemBuilder: (_) => const [
                PopupMenuItem(
                    value: 'export', child: Text('バックアップ(JSONをコピー)')),
                PopupMenuItem(
                    value: 'import', child: Text('復元(JSONを貼り付け)')),
                PopupMenuItem(value: 'about', child: Text('このアプリについて')),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            _ScoreHeader(score: _store.score, visited: _store.visitedCount),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                    value: false,
                    icon: Icon(Icons.map_outlined),
                    label: Text('地図')),
                ButtonSegment(
                    value: true,
                    icon: Icon(Icons.list),
                    label: Text('一覧')),
              ],
              selected: {_listMode},
              onSelectionChanged: (s) => setState(() => _listMode = s.first),
            ),
            const SizedBox(height: 8),
            Expanded(child: _listMode ? _buildList() : _buildMap()),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return FutureBuilder<JapanMapData>(
      future: _mapFuture,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('地図の読み込みに失敗しました: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return Stack(
          children: [
            Positioned.fill(
              child: JapanMap(
                data: snap.data!,
                rankByCode: _ranks,
                onPrefTap: _openPref,
              ),
            ),
            const Positioned(
              left: 16,
              top: 8,
              child: IgnorePointer(child: _LegendVertical()),
            ),
          ],
        );
      },
    );
  }

  Widget _buildList() {
    final codes = kPrefNames.keys.toList();
    return ListView.separated(
      itemCount: codes.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final code = codes[i];
        final rec = _store.prefs[code]!;
        final r = rankDef(rec.rank);
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: r.color,
            radius: 14,
            child: Text(
              '${rec.rank}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: rec.rank >= 4 ? Colors.white : Colors.black87,
              ),
            ),
          ),
          title: Text(kPrefNames[code]!),
          subtitle: Text('${r.label}・記録${rec.visits.length}件'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openPref(code),
        );
      },
    );
  }

  void _openPref(int code) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PrefDetailPage(code: code, store: _store),
      ),
    );
  }

  Future<void> _onMenu(String v) async {
    switch (v) {
      case 'export':
        await Clipboard.setData(ClipboardData(text: _store.exportJson()));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('バックアップJSONをコピーしました(写真は含まれません)')),
        );
        break;
      case 'import':
        _showImportDialog();
        break;
      case 'about':
        showAboutDialog(
          context: context,
          applicationName: '経県メモ',
          applicationVersion: '1.0.0',
          children: const [
            Text('都道府県ごとの経県ランクと訪問記録を残すアプリ。'),
            SizedBox(height: 8),
            Text('日本地図: geolonia/japanese-prefectures(MIT License)'),
          ],
        );
        break;
    }
  }

  Future<void> _showImportDialog() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('データを復元'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('バックアップJSONを貼り付けてください。現在のデータは上書きされます。'),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '{"version":1,"prefs":{...}}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('復元'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final success = _store.importJson(ctrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'データを復元しました' : 'JSONの形式が正しくありません'),
        ),
      );
    }
    ctrl.dispose();
  }
}

class _ScoreHeader extends StatelessWidget {
  final int score;
  final int visited;

  const _ScoreHeader({required this.score, required this.visited});

  @override
  Widget build(BuildContext context) {
    const brown = Color(0xFF5D4013);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9BE4B),
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Row(
          children: [
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: '経県値  ',
                    style: TextStyle(
                        color: brown, fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: '$score',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: brown,
                    ),
                  ),
                  const TextSpan(
                    text: ' 点',
                    style: TextStyle(
                        color: brown, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              '経県 $visited / 47',
              style: const TextStyle(
                  color: brown, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendVertical extends StatelessWidget {
  const _LegendVertical();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '点数',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B5E4F),
          ),
        ),
        const SizedBox(height: 4),
        for (final r in kRanks)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: r.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    '${r.value}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: (r.value == 3 || r.value == 0)
                          ? Colors.black87
                          : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  r.label,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  r.desc,
                  style: TextStyle(fontSize: 15, color: Colors.grey[800]),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
