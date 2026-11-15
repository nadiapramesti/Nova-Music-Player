import 'dart:math';

import 'package:just_audio/just_audio.dart';

/// Ke mana lagu yang baru ditambah diselipin di urutan acak.
enum InsertHint { random, afterCurrent, end }

/// Urutan acak Nova. Sama kayak DefaultShuffleOrder, tapi lagu yang ditambah lewat
/// "Putar berikutnya" diselipin tepat setelah lagu yang lagi diputar, dan
/// "Tambah ke antrean" di paling akhir, walau mode acak nyala.
class NovaShuffleOrder extends ShuffleOrder {
  NovaShuffleOrder({Random? random}) : _random = random ?? Random();

  final Random _random;

  @override
  final List<int> indices = <int>[];

  /// Diset sebelum insert; balik ke random setelah dipakai.
  InsertHint hint = InsertHint.random;

  /// Indeks sumber lagu yang lagi diputar (buat [InsertHint.afterCurrent]).
  int? currentIndex;

  @override
  void shuffle({int? initialIndex}) {
    assert(initialIndex == null || indices.contains(initialIndex));
    if (indices.length <= 1) return;
    indices.shuffle(_random);
    if (initialIndex == null) return;
    indices.remove(initialIndex);
    indices.insert(0, initialIndex);
  }

  @override
  void insert(int index, int count) {
    for (var i = 0; i < indices.length; i++) {
      if (indices[i] >= index) indices[i] += count;
    }
    final added = List<int>.generate(count, (i) => index + i);
    switch (hint) {
      case InsertHint.afterCurrent:
        final cur = currentIndex;
        final adjusted = cur == null ? null : (cur >= index ? cur + count : cur);
        final at = adjusted == null ? 0 : indices.indexOf(adjusted) + 1;
        indices.insertAll(at.clamp(0, indices.length), added);
      case InsertHint.end:
        indices.addAll(added);
      case InsertHint.random:
        for (final a in added) {
          indices.insert(_random.nextInt(indices.length + 1), a);
        }
    }
    hint = InsertHint.random;
  }

  @override
  void removeRange(int start, int end) {
    final count = end - start;
    indices.removeWhere((i) => i >= start && i < end);
    for (var i = 0; i < indices.length; i++) {
      if (indices[i] >= end) indices[i] -= count;
    }
  }

  @override
  void clear() => indices.clear();
}
