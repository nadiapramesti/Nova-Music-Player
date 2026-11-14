import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models.dart';
import '../screens/now_playing_screen.dart';
import '../services/services.dart';
import '../theme.dart';
import 'art.dart';

/// Tag Hero: cover kecil di dek "terbang" jadi cover besar di layar pemutar.
const novaArtHero = 'nova-art';

/// Dek kaca di bawah: lagu yang diputar + navigasi Putar / Rak / Cari.
class Deck extends StatelessWidget {
  const Deck({super.key, required this.tab, required this.onTab});

  final int tab;
  final ValueChanged<int> onTab;

  static const tabs = ['Putar', 'Rak', 'Cari'];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 40, offset: Offset(0, 14))],
      ),
      child: Glass(
        strong: true,
        radius: 28,
        padding: const EdgeInsets.all(8),
        child: ValueListenableBuilder<Song?>(
          valueListenable: audio.current,
          builder: (context, song, _) => AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (song != null) ...[_NowRow(song: song), const SizedBox(height: 8)],
                _NavBar(tab: tab, onTab: onTab),
              ],
            ),
          ),
        ),
      ),
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
              Hero(
                tag: novaArtHero,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Art(key: ValueKey(song.id), songId: song.id, size: 42, radius: 10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween(begin: const Offset(0, 0.35), end: Offset.zero).animate(anim),
                      child: child,
                    ),
                  ),
                  layoutBuilder: (cur, prev) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [...prev, if (cur != null) cur],
                  ),
                  child: Column(
                    key: ValueKey(song.id),
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
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                            child: Icon(
                              playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              key: ValueKey(playing),
                              color: Nv.onAccent,
                              size: 24,
                            ),
                          ),
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

/// Tiga tab dengan "kapsul" terang yang meluncur ke tab aktif.
class _NavBar extends StatelessWidget {
  const _NavBar({required this.tab, required this.onTab});
  final int tab;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    const gap = 4.0;
    const h = 46.0;
    return LayoutBuilder(builder: (context, c) {
      final w = (c.maxWidth - gap * (Deck.tabs.length - 1)) / Deck.tabs.length;
      return SizedBox(
        height: h,
        child: Stack(
          children: [
            Row(
              children: [
                for (var i = 0; i < Deck.tabs.length; i++) ...[
                  if (i > 0) const SizedBox(width: gap),
                  Container(
                    width: w,
                    height: h,
                    decoration: BoxDecoration(color: Nv.chip, borderRadius: BorderRadius.circular(18)),
                  ),
                ],
              ],
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutBack,
              left: tab * (w + gap),
              top: 0,
              width: w,
              height: h,
              child: Container(
                decoration: BoxDecoration(color: Nv.text, borderRadius: BorderRadius.circular(18)),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < Deck.tabs.length; i++) ...[
                  if (i > 0) const SizedBox(width: gap),
                  SizedBox(
                    width: w,
                    height: h,
                    child: Semantics(
                      button: true,
                      selected: i == tab,
                      child: Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => onTab(i),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 250),
                              style: disp(13, w: i == tab ? 800 : 700, color: i == tab ? Nv.bg : Nv.text),
                              child: Text(Deck.tabs[i]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    });
  }
}
