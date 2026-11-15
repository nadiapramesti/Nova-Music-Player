import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../demo/demo.dart';
import '../demo/demo_cover.dart';
import '../services/services.dart';
import '../theme.dart';

/// Cover lagu dari tag file. Gak ada cover = kotak kaca netral (atau [fallback]).
class Art extends StatelessWidget {
  const Art({
    super.key,
    required this.songId,
    this.size,
    this.radius = 10,
    this.big = false,
    this.fallback,
  });

  final int songId;
  final double? size;
  final double radius;
  final bool big;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    if (kDemo) {
      final cover = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: DemoCover(songId: songId),
      );
      return size == null ? cover : SizedBox.square(dimension: size, child: cover);
    }
    final box = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: FutureBuilder<Uint8List?>(
        future: Artwork.of(songId, big ? 720 : 160),
        builder: (context, snap) {
          final bytes = snap.data;
          if (bytes == null) {
            return fallback ??
                DecoratedBox(
                  decoration: BoxDecoration(color: Nv.cover),
                  child: SizedBox.expand(),
                );
          }
          return Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true);
        },
      ),
    );
    if (size == null) return box;
    return SizedBox.square(dimension: size, child: box);
  }
}
