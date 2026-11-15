import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nova/services/nova_shuffle.dart';

void main() {
  NovaShuffleOrder make(int n) {
    final o = NovaShuffleOrder(random: Random(7));
    o.insert(0, n);
    return o;
  }

  bool isPermutation(List<int> xs, int n) =>
      xs.length == n && xs.toSet().length == n && xs.every((x) => x >= 0 && x < n);

  test('acak tetap permutasi lengkap & lagu awal di depan', () {
    final o = make(10)..shuffle(initialIndex: 4);
    expect(isPermutation(o.indices, 10), isTrue);
    expect(o.indices.first, 4);
  });

  test('Putar berikutnya: diselipin tepat setelah lagu sekarang', () {
    final o = make(6)..shuffle(initialIndex: 2);
    final pos = o.indices.indexOf(2);
    o
      ..currentIndex = 2
      ..hint = InsertHint.afterCurrent
      ..insert(3, 1); // sumber: disisipkan di indeks 3
    expect(isPermutation(o.indices, 7), isTrue);
    expect(o.indices[pos], 2, reason: 'lagu sekarang gak geser');
    expect(o.indices[pos + 1], 3, reason: 'lagu baru langsung berikutnya');
    expect(o.hint, InsertHint.random, reason: 'hint dipakai sekali');
  });

  test('Tambah ke antrean: masuk paling akhir', () {
    final o = make(5)..shuffle(initialIndex: 0);
    o
      ..hint = InsertHint.end
      ..insert(5, 2);
    expect(isPermutation(o.indices, 7), isTrue);
    expect(o.indices.sublist(5), [5, 6]);
  });

  test('hapus lagu: indeks setelahnya geser turun', () {
    final o = make(5);
    o.indices
      ..clear()
      ..addAll([3, 0, 4, 1, 2]);
    o.removeRange(1, 2); // hapus sumber #1
    expect(o.indices, [2, 0, 3, 1]);
    expect(isPermutation(o.indices, 4), isTrue);
  });

  test('sisip di tengah: indeks lama yang >= posisi ikut geser', () {
    final o = make(3);
    o.indices
      ..clear()
      ..addAll([2, 0, 1]);
    o
      ..currentIndex = 0
      ..hint = InsertHint.afterCurrent
      ..insert(1, 1);
    expect(o.indices, [3, 0, 1, 2]);
  });
}
