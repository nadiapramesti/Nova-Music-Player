import 'package:flutter_test/flutter_test.dart';
import 'package:nova/services/sleep_timer.dart';

void main() {
  late DateTime clock;
  late int pauses;
  late List<double> volumes;
  late SleepTimer timer;

  setUp(() {
    clock = DateTime(2026, 11, 15, 22);
    pauses = 0;
    volumes = [];
    timer = SleepTimer(
      pause: () => pauses++,
      setVolume: volumes.add,
      now: () => clock,
    );
  });

  tearDown(() => timer.dispose());

  test('hitung mundur lalu jeda tepat waktu, volume balik 100%', () async {
    timer.start(const Duration(minutes: 15));
    expect(timer.active, isTrue);
    expect(timer.left.value, const Duration(minutes: 15));

    clock = clock.add(const Duration(minutes: 10));
    timer.tick();
    expect(timer.left.value, const Duration(minutes: 5));
    expect(pauses, 0);
    expect(volumes, isEmpty, reason: 'belum masuk fase fade');

    clock = clock.add(const Duration(minutes: 4, seconds: 56));
    timer.tick();
    expect(volumes.last, closeTo(0.5, 0.01), reason: 'sisa 4 dtk dari fade 8 dtk');

    clock = clock.add(const Duration(seconds: 5));
    timer.tick();
    await Future<void>.delayed(Duration.zero);
    expect(pauses, 1);
    expect(timer.active, isFalse);
    expect(volumes.last, 1.0);
  });

  test('akhir lagu: cuma jeda kalau mode akhir lagu aktif', () async {
    timer.onTrackEnded();
    expect(pauses, 0);

    timer.startEndOfTrack();
    expect(timer.active, isTrue);
    timer.onTrackEnded();
    await Future<void>.delayed(Duration.zero);
    expect(pauses, 1);
    expect(timer.active, isFalse);
  });

  test('matikan timer: gak jeda, volume dibalikin', () async {
    timer.start(const Duration(seconds: 6));
    timer.tick(); // langsung di fase fade
    expect(volumes, isNotEmpty);
    timer.cancel();
    await Future<void>.delayed(Duration.zero);
    expect(timer.active, isFalse);
    expect(volumes.last, 1.0);
    clock = clock.add(const Duration(minutes: 1));
    timer.tick();
    expect(pauses, 0);
  });

  test('ganti pilihan timer menimpa yang lama', () {
    timer.startEndOfTrack();
    timer.start(const Duration(minutes: 30));
    expect(timer.endOfTrack.value, isFalse);
    expect(timer.left.value, const Duration(minutes: 30));
  });

  test('format hitung mundur', () {
    expect(formatCountdown(const Duration(minutes: 12, seconds: 5)), '12:05');
    expect(formatCountdown(const Duration(hours: 1, minutes: 2, seconds: 5)), '1:02:05');
  });
}
