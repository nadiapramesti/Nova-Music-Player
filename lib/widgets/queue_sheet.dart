import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../services/services.dart';
import '../theme.dart';
import 'art.dart';

/// Lembar Antrean: lagu sekarang + berikutnya. Geser pegangan buat ngurutin,
/// swipe ke kiri buat hapus. Saat mode acak nyala, urutan gak bisa digeser
/// (urutannya ditentukan acakan), tapi hapus tetap bisa.
void showQueueSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    sheetAnimationStyle: Motion.sheet,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.62,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, controller) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: Glass(strong: true, radius: 28, child: _QueueList(controller: controller)),
      ),
    ),
  );
}

class _QueueList extends StatefulWidget {
  const _QueueList({required this.controller});
  final ScrollController controller;

  @override
  State<_QueueList> createState() => _QueueListState();
}

class _QueueListState extends State<_QueueList> {
  late final List<StreamSubscription<Object?>> _subs;

  @override
  void initState() {
    super.initState();
    void refresh(Object? _) {
      if (mounted) setState(() {});
    }

    _subs = [
      audio.player.currentIndexStream.listen(refresh),
      audio.player.shuffleModeEnabledStream.listen(refresh),
      audio.player.sequenceStateStream.listen(refresh),
    ];
    audio.queueVersion.addListener(_onQueue);
  }

  void _onQueue() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    audio.queueVersion.removeListener(_onQueue);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pakai catatan antrean Nova sendiri (selalu sinkron), bukan state player yang telat sedetik.
    final queue = audio.queue;
    final cur = audio.currentSourceIndex;
    final shuffled = audio.player.shuffleModeEnabled;
    final valid = audio.playOrder.where((i) => i >= 0 && i < queue.length).toList();
    final at = cur == null ? -1 : valid.indexOf(cur);
    final upcoming = at < 0 ? valid : valid.sublist(at + 1);
    final current = (cur != null && cur >= 0 && cur < queue.length) ? queue[cur] : null;

    return CustomScrollView(
      controller: widget.controller,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: Text('Antrean', style: disp(TS.h2, spacing: -0.6))),
                Text('${upcoming.length} BERIKUTNYA', style: mono(TS.label)),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
            child: Text(
              shuffled
                  ? 'Mode acak nyala: swipe ke kiri buat hapus. Matikan acak buat ngatur urutan.'
                  : 'Tahan & geser ≡ buat ngatur urutan, swipe ke kiri buat hapus.',
              style: disp(TS.caption, w: 500, color: Nv.muted, height: 1.35),
            ),
          ),
        ),
        if (current != null) ...[
          _label('SEDANG DIPUTAR'),
          SliverToBoxAdapter(child: _Row(song: current, active: true)),
        ],
        _label('BERIKUTNYA'),
        if (upcoming.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Text('Gak ada lagu berikutnya. Tahan lama lagu, lalu pilih "Putar berikutnya".',
                  style: disp(TS.body, w: 500, color: Nv.muted, height: 1.35)),
            ),
          )
        else
          SliverReorderableList(
            itemCount: upcoming.length,
            onReorder: (oldIndex, newIndex) {
              if (shuffled) return;
              if (newIndex > oldIndex) newIndex -= 1;
              if (newIndex == oldIndex) return;
              HapticFeedback.selectionClick();
              audio.move(upcoming[oldIndex], upcoming[newIndex]);
            },
            itemBuilder: (context, i) {
              final src = upcoming[i];
              final song = queue[src];
              return Material(
                key: ValueKey('q-$src-${song.id}'),
                type: MaterialType.transparency,
                child: Dismissible(
                  key: ValueKey('d-$src-${song.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    color: Nv.accentSoft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Hapus', style: disp(TS.body, w: 700, color: Nv.accent)),
                        const SizedBox(width: 6),
                        Icon(Icons.delete_outline_rounded, color: Nv.accent),
                      ],
                    ),
                  ),
                  onDismissed: (_) => audio.removeAt(src),
                  child: _Row(
                    song: song,
                    onTap: () => audio.player.seek(Duration.zero, index: src),
                    handle: shuffled
                        ? null
                        : ReorderableDragStartListener(
                            index: i,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Icon(Icons.drag_handle_rounded, color: Nv.muted),
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _label(String text) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
          child: Text(text, style: mono(TS.label, spacing: 1.2)),
        ),
      );
}

class _Row extends StatelessWidget {
  const _Row({required this.song, this.active = false, this.onTap, this.handle});
  final Song song;
  final bool active;
  final VoidCallback? onTap;
  final Widget? handle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, handle == null ? 20 : 8, 8),
        child: Row(
          children: [
            Art(songId: song.id, size: 42, radius: 9),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: disp(TS.title, w: 700, color: active ? Nv.accent : Nv.text)),
                  Text(song.artist,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: disp(TS.caption, w: 500, color: Nv.muted)),
                ],
              ),
            ),
            if (active) Icon(Icons.graphic_eq_rounded, color: Nv.accent, size: 20),
            if (handle != null) handle!,
          ],
        ),
      ),
    );
  }
}
