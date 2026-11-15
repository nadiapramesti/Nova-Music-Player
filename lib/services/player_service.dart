import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../demo/demo.dart';
import '../demo/silent_source.dart';
import '../models.dart';
import 'sleep_timer.dart';
import 'stats_service.dart';

class PlayerService {
  PlayerService(this._stats) {
    player.currentIndexStream.listen((i) {
      if (i == null || i < 0 || i >= _queue.length) return;
      final s = _queue[i];
      current.value = s;
      if (_lastMarked != s.id) {
        _lastMarked = s.id;
        _stats.played(s.id);
      }
    });
    // Timer tidur "akhir lagu": lagu pindah sendiri ke berikutnya, atau antrean habis.
    player.positionDiscontinuityStream.listen((d) {
      if (d.reason == PositionDiscontinuityReason.autoAdvance) sleep.onTrackEnded();
    });
    player.processingStateStream.listen((s) {
      if (s == ProcessingState.completed) sleep.onTrackEnded();
    });
  }

  final StatsService _stats;
  final AudioPlayer player = AudioPlayer();

  final ValueNotifier<Song?> current = ValueNotifier<Song?>(null);

  /// Timer tidur (berhenti otomatis).
  late final SleepTimer sleep = SleepTimer(pause: player.pause, setVolume: player.setVolume);

  /// Asal antrean, misal "Daftar putar · Terbaru" atau nama album.
  final ValueNotifier<String> source = ValueNotifier<String>('Daftar putar');

  List<Song> _queue = const [];
  int? _lastMarked;

  List<Song> get queue => _queue;

  AudioSource _toSource(Song s) {
    final tag = MediaItem(
      id: '${s.id}',
      title: s.title,
      artist: s.artist,
      album: s.album,
      duration: s.duration,
    );
    // Mode demo: audio senyap sepanjang durasi lagu (gak ada file asli).
    if (kDemo) return SilentAudioSource(durationMs: s.durationMs, tag: tag);
    return AudioSource.uri(Uri.parse(s.uri), tag: tag);
  }

  Future<void> playQueue(List<Song> songs, int index, {String? from, Duration startAt = Duration.zero}) async {
    if (songs.isEmpty) return;
    _queue = List.unmodifiable(songs);
    if (from != null) source.value = from;
    current.value = songs[index];
    await player.setAudioSource(
      ConcatenatingAudioSource(children: songs.map(_toSource).toList()),
      initialIndex: index,
      initialPosition: startAt,
    );
    // Gak di-await: future play() baru selesai pas lagu berhenti.
    player.play();
  }

  Future<void> shuffleQueue(List<Song> songs, {String? from}) async {
    if (songs.isEmpty) return;
    await player.setShuffleModeEnabled(true);
    await playQueue(songs, Random().nextInt(songs.length), from: from);
    await player.shuffle();
  }

  void togglePlay() => player.playing ? player.pause() : player.play();

  Future<void> toggleShuffle() async {
    final on = !player.shuffleModeEnabled;
    await player.setShuffleModeEnabled(on);
    if (on) await player.shuffle();
  }

  Future<void> cycleLoop() {
    switch (player.loopMode) {
      case LoopMode.off:
        return player.setLoopMode(LoopMode.all);
      case LoopMode.all:
        return player.setLoopMode(LoopMode.one);
      case LoopMode.one:
        return player.setLoopMode(LoopMode.off);
    }
  }

  /// Lagu berikutnya sesuai urutan main (ikut mode acak).
  Song? get upNext {
    final next = player.nextIndex;
    if (next == null || next < 0 || next >= _queue.length) return null;
    return _queue[next];
  }

  /// Posisi lagu sekarang dalam urutan main (1-based).
  int get positionInQueue {
    final i = player.currentIndex;
    if (i == null) return 0;
    final order = player.effectiveIndices;
    final pos = order?.indexOf(i) ?? i;
    return (pos < 0 ? i : pos) + 1;
  }
}
