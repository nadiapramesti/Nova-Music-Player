import 'package:flutter/material.dart';

import '../models.dart';
import '../services/services.dart';
import '../theme.dart';
import 'art.dart';

/// Satu baris lagu: nomor mono, cover, judul, artis, durasi.
class SongRow extends StatelessWidget {
  const SongRow({super.key, required this.song, required this.number, required this.onTap});

  final Song song;
  final int number;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Song?>(
      valueListenable: audio.current,
      builder: (context, cur, _) {
        final on = cur?.id == song.id;
        return InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Nv.rule))),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: on
                      ? Icon(Icons.play_arrow_rounded, size: 16, color: Nv.accent)
                      : Text(twoDigits(number), style: mono(12)),
                ),
                Art(songId: song.id, size: 40, radius: 9),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: disp(15, w: 700, spacing: -0.2, color: on ? Nv.accent : Nv.text),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: disp(12.5, w: 500, color: Nv.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(fmt(song.duration), style: mono(12, w: 500)),
              ],
            ),
          ),
        );
      },
    );
  }
}
