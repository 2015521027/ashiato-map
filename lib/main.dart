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
        colorSchemeSeed: const Color(0xFF00695C),
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
  late final Future<List<PrefShape>> _shapesFuture = loadJapanMap();
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
    return FutureBuilder<List<PrefShape>>(
      future: _shapesFuture,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('地図の読み込みに失敗しました: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            Expanded(
              child: JapanMap(
                shapes: snap.data!,
                rankByCode: _ranks,
                onPrefTap: _openPref,
              ),
            ),
            const _Legend(),
            const SizedBox(height: 8),
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
          const SnackBar(content: Text('バックアップJSONをクリップボードにコピーしました')),
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
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Card(
        elevation: 0,
        color: scheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: '経県値  '),
                    TextSpan(
                      text: '$score',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: scheme.primary,
                      ),
                    ),
                    const TextSpan(text: ' 点'),
                  ],
                ),
              ),
              const Spacer(),
              Text('経県 $visited / 47'),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        for (final r in kRanks)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: r.color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 4),
              Text('${r.value} ${r.label}',
                  style: const TextStyle(fontSize: 11)),
            ],
          ),
      ],
    );
  }
}
