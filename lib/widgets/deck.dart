import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models.dart';
import '../screens/now_playing_screen.dart';
import '../services/services.dart';
import '../theme.dart';
import 'art.dart';

/// Dek kaca di bawah: lagu yang diputar + navigasi Putar / Rak / Cari.
class Deck extends StatelessWidget {
  const Deck({super.key, this.tab, this.onTab});

  /// null = dek tanpa navigasi (dipakai di halaman detail).
  final int? tab;
  final ValueChanged<int>? onTab;

  static const tabs = ['Putar', 'Rak', 'Cari'];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Song?>(
      valueListenable: audio.current,
      builder: (context, song, _) {
        if (song == null && tab == null) return const SizedBox.shrink();
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 40, offset: Offset(0, 14))],
          ),
          child: Glass(
            strong: true,
            radius: 28,
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (song != null) _NowRow(song: song),
                if (song != null && tab != null) const SizedBox(height: 8),
                if (tab != null)
                  Row(
                    children: [
                      for (var i = 0; i < tabs.length; i++) ...[
                        if (i > 0) const SizedBox(width: 4),
                        Expanded(child: _NavPill(label: tabs[i], active: i == tab, onTap: () => onTab?.call(i))),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NowRow extends StatelessWidget {
  const _NowRow({required this.song});
  final Song song;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => openNowPlaying(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
          child: Row(
            children: [
              Art(songId: song.id, size: 42, radius: 10),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(song.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: disp(14, w: 700)),
                    StreamBuilder<Duration>(
                      stream: audio.player.positionStream,
                      builder: (context, snap) => Text(
                        '${fmt(snap.data ?? Duration.zero)} / ${fmt(song.duration)}',
                        style: mono(11.5, w: 500),
                      ),
                    ),
                  ],
                ),
              ),
              StreamBuilder<PlayerState>(
                stream: audio.player.playerStateStream,
                builder: (context, snap) {
                  final playing = snap.data?.playing ?? false;
                  return Semantics(
                    button: true,
                    label: playing ? 'Jeda' : 'Putar',
                    child: Material(
                      color: Nv.accent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: audio.togglePlay,
                        child: SizedBox.square(
                          dimension: 44,
                          child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Nv.onAccent, size: 24),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  const _NavPill({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(18);
    return Material(
      color: active ? Nv.text : Nv.chip,
      borderRadius: r,
      child: InkWell(
        borderRadius: r,
        onTap: onTap,
        child: SizedBox(
          height: 46,
          child: Center(
            child: Text(label, style: disp(13, w: active ? 800 : 700, color: active ? Nv.bg : Nv.text)),
          ),
        ),
      ),
    );
  }
}
