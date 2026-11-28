import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../../demo/demo.dart';
import '../library_service.dart';
import '../player_service.dart';
import 'cast_client.dart';
import 'media_server.dart';

class CastDevice {
  const CastDevice({required this.id, required this.name, required this.model, required this.host, required this.port});
  final String id;
  final String name;
  final String model;
  final String host;
  final int port;
}

enum CastState { idle, connecting, casting }

/// Muter lagu di TV (Chromecast / Google TV).
///
/// Cara kerjanya: pemutar di HP tetap jalan tapi dibisuin, jadi antrean, posisi,
/// notifikasi, pulau, lirik, & timer tidur tetap kerja seperti biasa. TV ngikutin:
/// ganti lagu, putar/jeda, & loncat posisi dikirim ke TV; lagunya diambil TV
/// langsung dari HP lewat WiFi.
class CastService extends ChangeNotifier {
  CastService(this._audio, this._library);
  final PlayerService _audio;
  final LibraryService _library;

  static const _ch = MethodChannel('nova/cast');

  final Map<String, CastDevice> devices = {};
  bool scanning = false;
  CastState state = CastState.idle;
  CastDevice? device;
  String? error;

  CastClient? _client;
  MediaServer? _server;
  final _subs = <StreamSubscription<dynamic>>[];
  final _undo = <void Function()>[];
  Timer? _drift;
  int? _loadedId;
  bool _loading = false;
  DateTime _lastCommand = DateTime(2000);
  CastMediaStatus? _tv;
  DateTime _tvAt = DateTime(2000);

  bool get casting => state == CastState.casting;

  void init() {
    _ch.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'found':
          final m = Map<String, dynamic>.from(call.arguments as Map);
          final d = CastDevice(
            id: m['id'] as String,
            name: m['name'] as String,
            model: (m['model'] as String?) ?? '',
            host: m['host'] as String,
            port: (m['port'] as num).toInt(),
          );
          devices[d.id] = d;
          notifyListeners();
        case 'lost':
          // NSD kadang "hilang-muncul"; daftar dibiarin, dibersihin pas scan ulang.
          break;
        case 'error':
          error = 'Gak bisa nyari TV. Pastiin WiFi nyala.';
          scanning = false;
          notifyListeners();
      }
    });
  }

  Future<void> startScan() async {
    if (kDemo) return;
    error = null;
    devices.clear();
    scanning = true;
    notifyListeners();
    try {
      await _ch.invokeMethod('start');
    } catch (_) {
      scanning = false;
      error = 'Gak bisa nyari TV.';
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    scanning = false;
    try {
      await _ch.invokeMethod('stop');
    } catch (_) {}
  }

  Future<void> connect(CastDevice d) async {
    if (state != CastState.idle) await disconnect();
    device = d;
    error = null;
    state = CastState.connecting;
    notifyListeners();
    try {
      final server = MediaServer(
        pathOf: (id) => _library.byId(id)?.path,
        coverOf: (id) => Artwork.of(id, 600),
      );
      await server.start();
      _server = server;
      final client = CastClient(d.host, d.port);
      await client.connect();
      _client = client;
      unawaited(_ch.invokeMethod('wifiLock', true));
      _audio.setCastMute(true);
      _hook(client);
      state = CastState.casting;
      notifyListeners();
      await _loadCurrent();
    } catch (e) {
      error = e is CastException
          ? e.message
          : 'Gak bisa nyambung ke ${d.name}. Pastiin HP & TV di WiFi yang sama.';
      await _teardown();
    }
  }

  /// Balik muter di HP, dari posisi yang sama.
  Future<void> disconnect() async {
    final c = _client;
    _client = null;
    await c?.stop();
    await _teardown();
  }

  Future<void> _teardown() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    for (final u in _undo) {
      u();
    }
    _undo.clear();
    _drift?.cancel();
    _drift = null;
    _client = null;
    await _server?.stop();
    _server = null;
    _loadedId = null;
    _tv = null;
    _audio.setCastMute(false);
    try {
      await _ch.invokeMethod('wifiLock', false);
    } catch (_) {}
    state = CastState.idle;
    notifyListeners();
  }

  void _hook(CastClient client) {
    void onSong() => _loadCurrent();
    _audio.current.addListener(onSong);
    _undo.add(() => _audio.current.removeListener(onSong));

    _subs.add(_audio.player.playingStream.skip(1).listen((playing) {
      if (_loading || _loadedId == null) return;
      _lastCommand = DateTime.now();
      playing ? client.play() : client.pause();
    }));

    // Loncat posisi di HP (geser seek bar, tap lirik) → TV ikut.
    _subs.add(_audio.player.positionDiscontinuityStream.listen((d) {
      if (d.reason == PositionDiscontinuityReason.seek && !_loading && _loadedId == _audio.current.value?.id) {
        _lastCommand = DateTime.now();
        client.seek(_audio.player.position);
      }
    }));

    _subs.add(client.status.listen((s) {
      _tv = s;
      _tvAt = DateTime.now();
      final recent = DateTime.now().difference(_lastCommand) < const Duration(seconds: 3);
      if (_loading || recent) return;
      // Dijeda / diputar pakai remote TV → HP ikut.
      if (s.state == 'PAUSED' && _audio.player.playing) _audio.player.pause();
      if (s.state == 'PLAYING' && !_audio.player.playing) _audio.player.play();
      if (s.state == 'IDLE' && s.idleReason == 'ERROR') {
        error = 'TV gagal muter lagu ini (format gak didukung?). Lanjut ke lagu berikutnya.';
        notifyListeners();
        if (_audio.player.hasNext) _audio.player.seekToNext();
      }
    }));

    // Jaga-jaga kalau TV & HP kelamaan beda posisi (mis. TV sempat buffering).
    _drift = Timer.periodic(const Duration(seconds: 4), (_) {
      final tv = _tv;
      if (tv == null || _loading || !_audio.player.playing || tv.state != 'PLAYING') return;
      final tvPos = tv.position + DateTime.now().difference(_tvAt);
      final diff = (tvPos - _audio.player.position).inMilliseconds.abs();
      if (diff > 3000 && DateTime.now().difference(_lastCommand) > const Duration(seconds: 6)) {
        _lastCommand = DateTime.now();
        client.seek(_audio.player.position);
      }
    });

    client.closed.then((_) {
      if (_client == client) {
        error = 'Sambungan ke ${device?.name ?? 'TV'} putus. Lanjut muter di HP.';
        _teardown();
      }
    });
  }

  Future<void> _loadCurrent() async {
    final client = _client, server = _server;
    final song = _audio.current.value;
    if (client == null || server == null || song == null || song.id == _loadedId) return;
    _loading = true;
    _loadedId = song.id;
    try {
      _lastCommand = DateTime.now();
      await client.load(
        url: server.songUrl(song.id),
        contentType: audioMime(song.path),
        title: song.title,
        artist: song.artist,
        album: song.album,
        coverUrl: server.coverUrl(song.id),
        start: _audio.player.position,
        autoplay: _audio.player.playing,
      );
    } on CastException catch (e) {
      error = e.message;
      notifyListeners();
    } finally {
      _loading = false;
    }
  }
}
