import 'dart:async';
import 'dart:math';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../demo/demo.dart';
import '../demo/silent_source.dart';
import '../models.dart';
import 'nova_shuffle.dart';
import 'sleep_timer.dart';
import 'transition.dart';
import 'stats_service.dart';

class PlayerService {
  PlayerService(this._stats) {
    player.currentIndexStream.listen((i) {
      if (i == null || i < 0 || i >= _queue.length) return;
      _cur = i;
      // Ganti lagu: langsung set volume awal lagu baru (gak nunggu ticker).
      _tickFade();
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
    player.playingStream.listen((_) => _syncFadeTicker());
    // Ulang 1 lagu cuma buat lagu itu: begitu pindah lagu (next, prev, tap lagu lain,
    // widget, notifikasi), balik ke ulang semua.
    current.addListener(() {
      final id = current.value?.id;
      if (id == _loopSongId) return;
      final had = _loopSongId != null;
      _loopSongId = id;
      if (had && player.loopMode == LoopMode.one) player.setLoopMode(LoopMode.all);
    });
  }

  int? _loopSongId;

  /// Durasi transisi halus antar lagu dalam detik (0 = mati).
  final ValueNotifier<int> fadeSeconds = ValueNotifier<int>(2);
  late final VolumeMixer _volume = VolumeMixer(player.setVolume);
  Timer? _fadeTicker;

  Future<void> initPlayback() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getInt('fadeSeconds') ?? 2;
    fadeSeconds.value = transitionChoices.contains(v) ? v : 2;
    _syncFadeTicker();
    await _listenFocus();
  }

  Timer? _duckTimer;
  bool _pausedByOther = false;

  /// Kayak app musik lain: app lain bunyi → Nova minggir.
  /// - Bunyi sebentar (notifikasi): cukup dikecilin sistem, gak dijeda.
  /// - Bunyi lama walau "minta dikecilin" (video SW WA, IG): dijeda setelah 1,5 detik,
  ///   lanjut sendiri pas videonya ditutup.
  /// - Telepon: jeda, lanjut sendiri pas selesai.
  /// - App lain ambil alih total (TikTok, YouTube): jeda, gak lanjut sendiri.
  /// - Headset dicabut: jeda.
  Future<void> _listenFocus() async {
    final session = await AudioSession.instance;
    session.becomingNoisyEventStream.listen((_) => player.pause());
    session.interruptionEventStream.listen((e) {
      if (e.begin) {
        _duckTimer?.cancel();
        switch (e.type) {
          case AudioInterruptionType.duck:
            _duckTimer = Timer(const Duration(milliseconds: 1500), () {
              if (player.playing) {
                _pausedByOther = true;
                player.pause();
              }
            });
          case AudioInterruptionType.pause:
            if (player.playing) {
              _pausedByOther = true;
              player.pause();
            }
          case AudioInterruptionType.unknown:
            _pausedByOther = false;
            if (player.playing) player.pause();
        }
      } else {
        _duckTimer?.cancel();
        _duckTimer = null;
        if (e.type != AudioInterruptionType.unknown && _pausedByOther && !player.playing) {
          player.play();
        }
        _pausedByOther = false;
      }
    });
  }

  Future<void> setFadeSeconds(int v) async {
    fadeSeconds.value = v;
    _syncFadeTicker();
    (await SharedPreferences.getInstance()).setInt('fadeSeconds', v);
  }

  void _syncFadeTicker() {
    final on = fadeSeconds.value > 0 && player.playing;
    if (on && _fadeTicker == null) {
      _tickFade();
      _fadeTicker = Timer.periodic(const Duration(milliseconds: 100), (_) => _tickFade());
    } else if (!on) {
      _fadeTicker?.cancel();
      _fadeTicker = null;
      if (fadeSeconds.value == 0) _volume.setFade(1);
    }
  }

  void _tickFade() {
    if (fadeSeconds.value == 0) return _volume.setFade(1);
    _volume.setFade(transitionGain(
      pos: player.position,
      dur: player.duration,
      fade: Duration(seconds: fadeSeconds.value),
    ));
  }

  final StatsService _stats;
  // Gangguan dari app lain diurus sendiri di [_listenFocus] (bawaan just_audio
  // cuma ngecilin suara kalau app lain minta "duck", kayak SW WA).
  final AudioPlayer player = AudioPlayer(handleInterruptions: false);

  final ValueNotifier<Song?> current = ValueNotifier<Song?>(null);

  /// Timer tidur (berhenti otomatis).
  late final SleepTimer sleep = SleepTimer(pause: player.pause, setVolume: _volume.setSleep);

  /// Asal antrean, misal "Daftar putar · Terbaru" atau nama album.
  final ValueNotifier<String> source = ValueNotifier<String>('Daftar putar');

  /// Urutan sumber antrean (sejajar sama [_source]). Diubah lewat playNext/addToQueue/move/removeAt.
  List<Song> _queue = [];
  ConcatenatingAudioSource? _source;
  NovaShuffleOrder? _shuffle;
  int? _lastMarked;

  /// Indeks sumber lagu sekarang, dicatat sendiri & disesuaikan langsung saat antrean
  /// diubah (player baru ngabarin setelah jeda async).
  int? _cur;

  int? get currentSourceIndex => _cur;

  /// Urutan main (indeks sumber): urutan acak kalau mode acak nyala.
  List<int> get playOrder {
    final shuffle = _shuffle;
    if (player.shuffleModeEnabled && shuffle != null && shuffle.indices.length == _queue.length) {
      return List.of(shuffle.indices);
    }
    return List.generate(_queue.length, (i) => i);
  }

  /// Naik tiap isi/urutan antrean berubah (buat lembar Antrean).
  final ValueNotifier<int> queueVersion = ValueNotifier<int>(0);

  List<Song> get queue => List.unmodifiable(_queue);

  void _queueChanged() => queueVersion.value++;

  /// Info lagu diubah di Nova: perbarui salinan di antrean & lagu yang lagi diputar.
  void refreshSong(Song updated) {
    var changed = false;
    for (var i = 0; i < _queue.length; i++) {
      if (_queue[i].id == updated.id) {
        _queue[i] = updated;
        changed = true;
      }
    }
    if (current.value?.id == updated.id) current.value = updated;
    if (changed) _queueChanged();
  }

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
    _queue = List.of(songs);
    _cur = index;
    if (from != null) source.value = from;
    current.value = songs[index];
    _shuffle = NovaShuffleOrder();
    _source = ConcatenatingAudioSource(
      children: songs.map(_toSource).toList(),
      shuffleOrder: _shuffle,
    );
    _queueChanged();
    await player.setAudioSource(_source!, initialIndex: index, initialPosition: startAt);
    // Gak di-await: future play() baru selesai pas lagu berhenti.
    player.play();
  }

  Future<void> shuffleQueue(List<Song> songs, {String? from}) async {
    if (songs.isEmpty) return;
    await player.setShuffleModeEnabled(true);
    await playQueue(songs, Random().nextInt(songs.length), from: from);
    await player.shuffle();
  }

  /// Selipin lagu tepat setelah lagu yang lagi diputar (juga saat mode acak).
  Future<void> playNext(Song song) async {
    final src = _source;
    final cur = _cur;
    if (src == null || cur == null || _queue.isEmpty) {
      await playQueue([song], 0, from: 'Antrean');
      return;
    }
    final at = cur + 1;
    _shuffle
      ?..currentIndex = cur
      ..hint = InsertHint.afterCurrent;
    _queue.insert(at, song);
    final pending = src.insert(at, _toSource(song));
    _queueChanged();
    await pending;
  }

  /// Tambah lagu di paling akhir antrean.
  Future<void> addToQueue(Song song) async {
    final src = _source;
    if (src == null || _queue.isEmpty) {
      await playQueue([song], 0, from: 'Antrean');
      return;
    }
    _shuffle?.hint = InsertHint.end;
    _queue.add(song);
    final pending = src.add(_toSource(song));
    _queueChanged();
    await pending;
  }

  /// Hapus lagu dari antrean (bukan yang lagi diputar). [index] = indeks sumber.
  Future<void> removeAt(int index) async {
    final src = _source;
    final cur = _cur;
    if (src == null || index < 0 || index >= _queue.length || index == cur) return;
    _queue.removeAt(index);
    if (cur != null && index < cur) _cur = cur - 1;
    // Langsung kabarin UI (sinkron) biar baris yang di-swipe hilang di frame yang sama.
    final pending = src.removeAt(index);
    _queueChanged();
    await pending;
  }

  /// Pindah urutan (indeks sumber). Dipakai saat mode acak mati.
  Future<void> move(int from, int to) async {
    final src = _source;
    if (src == null || from == to) return;
    if (from < 0 || to < 0 || from >= _queue.length || to >= _queue.length) return;
    final song = _queue.removeAt(from);
    _queue.insert(to, song);
    final cur = _cur;
    if (cur != null) {
      if (from == cur) {
        _cur = to;
      } else if (from < cur && to >= cur) {
        _cur = cur - 1;
      } else if (from > cur && to <= cur) {
        _cur = cur + 1;
      }
    }
    final pending = src.move(from, to);
    _queueChanged();
    await pending;
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
