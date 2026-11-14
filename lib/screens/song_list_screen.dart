import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/controls.dart';
import '../widgets/island.dart';
import '../widgets/song_row.dart';
import 'now_playing_screen.dart';

/// Daftar lagu generik: album, artis, folder, favorit, pintasan.
class SongListScreen extends StatelessWidget {
  const SongListScreen({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.songs,
    this.emptyText = 'Belum ada lagu di sini.',
  });

  final String eyebrow;
  final String title;
  final List<Song> songs;
  final String emptyText;

  static void open(BuildContext context,
      {required String eyebrow, required String title, required List<Song> songs, String? emptyText}) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => SongListScreen(
        eyebrow: eyebrow,
        title: title,
        songs: songs,
        emptyText: emptyText ?? 'Belum ada lagu di sini.',
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final total = songs.fold<int>(0, (sum, s) => sum + s.durationMs);

    return Scaffold(
      body: Stack(
        children: [
          const Glow(top: -120, right: -140, size: 380),
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, top + 10, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlassCircleButton(
                        icon: Icons.arrow_back_rounded,
                        label: 'Kembali',
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(height: 18),
                      Text(eyebrow.toUpperCase(), style: mono(11, spacing: 1.2)),
                      const SizedBox(height: 4),
                      Text(title, style: disp(34, height: 1.0, spacing: -1.2)),
                      const SizedBox(height: 6),
                      Text('${songs.length} LAGU · ${fmt(Duration(milliseconds: total))}',
                          style: mono(12, w: 500)),
                      if (songs.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: WideButton(
                                label: 'Putar semua',
                                icon: Icons.play_arrow_rounded,
                                onTap: () => playAndOpen(context, songs, 0, from: title),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: WideButton(
                                label: 'Acak',
                                icon: Icons.shuffle_rounded,
                                primary: false,
                                onTap: () => shuffleAndOpen(context, songs, from: title),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
              if (songs.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                    child: Text(emptyText,
                        textAlign: TextAlign.center, style: disp(14, w: 500, color: Nv.muted)),
                  ),
                )
              else
                SliverList.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, i) => SongRow(
                    song: songs[i],
                    number: i + 1,
                    onTap: () => playAndOpen(context, songs, i, from: title),
                  ),
                ),
              SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.bottom + 24)),
            ],
          ),
          const Positioned.fill(child: NowIsland()),
        ],
      ),
    );
  }
}
