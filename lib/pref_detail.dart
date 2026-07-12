import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'models.dart';
import 'photo_store.dart';
import 'store.dart';

/// 都道府県詳細ページ: 経県ランクの設定と訪問記録(子レコード)の一覧・追加・編集・削除
class PrefDetailPage extends StatelessWidget {
  final int code;
  final Store store;

  const PrefDetailPage({super.key, required this.code, required this.store});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final rec = store.prefs[code]!;
        return Scaffold(
          appBar: AppBar(title: Text(kPrefNames[code]!)),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _editVisit(context),
            icon: const Icon(Icons.add),
            label: const Text('記録を追加'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Text('ランク', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in kRanks)
                    ChoiceChip(
                      avatar: CircleAvatar(backgroundColor: r.color, radius: 8),
                      label: Text('${r.label} ${r.value}点'),
                      tooltip: r.desc,
                      selected: rec.rank == r.value,
                      onSelected: (_) => store.setRank(code, r.value),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                rankDef(rec.rank).desc,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const Divider(height: 32),
              Text(
                '訪問記録(${rec.visits.length}件)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (rec.visits.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'まだ記録がありません。\n「記録を追加」からいつ・何で行ったかを残せます。',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              else
                for (final v in rec.visits)
                  _VisitCard(
                    visit: v,
                    onEdit: () => _editVisit(context, v),
                    onDelete: () => _confirmDelete(context, v),
                  ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editVisit(BuildContext context, [Visit? original]) async {
    final result = await Navigator.of(context).push<Visit>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => VisitEditPage(
          prefName: kPrefNames[code]!,
          original: original,
        ),
      ),
    );
    if (result != null) {
      // 編集で外された写真の実体を削除してから保存する
      for (final id in original?.photos ?? const <String>[]) {
        if (!result.photos.contains(id)) {
          PhotoStore.instance.delete(id);
        }
      }
      store.upsertVisit(code, result);
    }
  }

  Future<void> _confirmDelete(BuildContext context, Visit v) async {
    final label = v.title.isEmpty ? v.dateLabel : v.title;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('記録を削除'),
        content: Text(
            '「$label」を削除しますか?${v.photos.isNotEmpty ? '\n添付写真${v.photos.length}枚も削除されます。' : ''}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (ok == true) store.deleteVisit(code, v.id);
  }
}

class _VisitCard extends StatelessWidget {
  final Visit visit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VisitCard({
    required this.visit,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = kCategories[visit.category] ?? kCategories['その他']!;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      visit.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: catColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    visit.dateLabel,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: '削除',
                    onPressed: onDelete,
                  ),
                ],
              ),
              if (visit.title.isNotEmpty)
                Text(
                  visit.title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              if (visit.memo.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 8),
                  child: Text(visit.memo),
                ),
              if (visit.photos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    height: 64,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final id in visit.photos)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              onTap: () => _showPhoto(context, id),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _PhotoThumb(id: id, size: 64),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPhoto(BuildContext context, String id) async {
    final bytes = await PhotoStore.instance.load(id);
    if (bytes == null || !context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(8),
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(
              maxScale: 6,
              child: Center(child: Image.memory(bytes)),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// PhotoStore から読み込むサムネイル
class _PhotoThumb extends StatelessWidget {
  final String id;
  final double size;

  const _PhotoThumb({required this.id, required this.size});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: PhotoStore.instance.load(id),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Container(
            width: size,
            height: size,
            color: Colors.grey[200],
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final bytes = snap.data;
        if (bytes == null) {
          return Container(
            width: size,
            height: size,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        }
        return Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        );
      },
    );
  }
}

class _PendingPhoto {
  final String? id; // 既存写真ならID、新規追加なら null
  final Uint8List bytes;
  _PendingPhoto({this.id, required this.bytes});
}

/// 訪問記録の追加・編集フォーム(写真添付対応)
class VisitEditPage extends StatefulWidget {
  final String prefName;
  final Visit? original;

  const VisitEditPage({super.key, required this.prefName, this.original});

  @override
  State<VisitEditPage> createState() => _VisitEditPageState();
}

class _VisitEditPageState extends State<VisitEditPage> {
  late DateTime _date = widget.original?.date ?? DateTime.now();
  late String _category = widget.original?.category ?? '旅行';
  late final TextEditingController _titleCtrl =
      TextEditingController(text: widget.original?.title ?? '');
  late final TextEditingController _memoCtrl =
      TextEditingController(text: widget.original?.memo ?? '');

  List<_PendingPhoto> _photos = [];
  bool _loadingPhotos = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.original?.photos ?? const <String>[];
    if (existing.isNotEmpty) {
      _loadingPhotos = true;
      _loadExistingPhotos(existing);
    }
  }

  Future<void> _loadExistingPhotos(List<String> ids) async {
    final list = <_PendingPhoto>[];
    for (final id in ids) {
      final bytes = await PhotoStore.instance.load(id);
      if (bytes != null) list.add(_PendingPhoto(id: id, bytes: bytes));
    }
    if (!mounted) return;
    setState(() {
      _photos = list;
      _loadingPhotos = false;
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  String get _dateLabel =>
      '${_date.year}/${_date.month.toString().padLeft(2, '0')}/${_date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.original == null
            ? '${widget.prefName}の記録を追加'
            : '記録を編集'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: '日付',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today, size: 20),
              ),
              child: Text(_dateLabel),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: '種別',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final c in kCategories.keys)
                DropdownMenuItem(value: c, child: Text(c)),
            ],
            onChanged: (v) => setState(() => _category = v ?? 'その他'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'タイトル',
              hintText: '例: GW家族旅行、〇〇案件の出張',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _memoCtrl,
            minLines: 4,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: 'メモ',
              hintText: '行った場所、食べたもの、一緒に行った人、思い出など',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          Text('写真', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          if (_loadingPhotos)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _photos.length; i++)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _photos[i].bytes,
                          width: 84,
                          height: 84,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => setState(() => _photos.removeAt(i)),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(Icons.close,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                InkWell(
                  onTap: _addPhotos,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: Icon(Icons.add_a_photo, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1970),
      lastDate: DateTime.now().add(const Duration(days: 366)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _addPhotos() async {
    // Webはファイル選択のみ。モバイルはギャラリー/カメラを選ばせる。
    ImageSource source = ImageSource.gallery;
    if (!kIsWeb) {
      final picked = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('ギャラリーから選ぶ'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('カメラで撮る'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );
      if (picked == null) return;
      source = picked;
    }

    final picker = ImagePicker();
    final files = <XFile>[];
    try {
      if (source == ImageSource.gallery) {
        files.addAll(await picker.pickMultiImage(
            maxWidth: 1600, imageQuality: 80));
      } else {
        final shot = await picker.pickImage(
            source: ImageSource.camera, maxWidth: 1600, imageQuality: 80);
        if (shot != null) files.add(shot);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('写真の取得に失敗しました: $e')),
      );
      return;
    }

    for (final f in files) {
      var bytes = await f.readAsBytes();
      // ピッカーが縮小してくれなかった場合の保険(Web等)
      if (bytes.length > 400 * 1024) {
        bytes = await compute(downscaleImage, bytes);
      }
      _photos.add(_PendingPhoto(bytes: bytes));
    }
    if (mounted && files.isNotEmpty) setState(() {});
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ids = <String>[];
    for (final p in _photos) {
      ids.add(p.id ?? await PhotoStore.instance.save(p.bytes));
    }
    if (!mounted) return;
    Navigator.pop(
      context,
      Visit(
        id: widget.original?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        date: _date,
        category: _category,
        title: _titleCtrl.text.trim(),
        memo: _memoCtrl.text.trim(),
        photos: ids,
      ),
    );
  }
}
