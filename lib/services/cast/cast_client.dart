import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'cast_proto.dart';

const _nsConn = 'urn:x-cast:com.google.cast.tp.connection';
const _nsBeat = 'urn:x-cast:com.google.cast.tp.heartbeat';
const _nsRecv = 'urn:x-cast:com.google.cast.receiver';
const _nsMedia = 'urn:x-cast:com.google.cast.media';

/// Pemutar bawaan Chromecast (Default Media Receiver).
const _defaultReceiver = 'CC1AD845';

/// Status pemutaran di TV.
class CastMediaStatus {
  const CastMediaStatus({required this.state, required this.position, this.idleReason});

  /// PLAYING | PAUSED | BUFFERING | IDLE
  final String state;
  final Duration position;

  /// Kalau IDLE: FINISHED | CANCELLED | INTERRUPTED | ERROR
  final String? idleReason;
}

/// Klien CASTV2 kecil: sambung ke TV, buka pemutar bawaan, kirim lagu & perintah.
class CastClient {
  CastClient(this.host, this.port);
  final String host;
  final int port;

  SecureSocket? _socket;
  Timer? _beat;
  int _req = 1;
  String? _transport;
  int? _mediaSession;
  DateTime _lastPong = DateTime.now();
  final _pending = <int, Completer<Map<String, dynamic>>>{};

  final _status = StreamController<CastMediaStatus>.broadcast();
  final _closed = Completer<void>();

  Stream<CastMediaStatus> get status => _status.stream;

  /// Selesai kalau koneksi ke TV putus.
  Future<void> get closed => _closed.future;

  bool get connected => _socket != null && !_closed.isCompleted;

  Future<void> connect() async {
    // TV pakai sertifikat buatan sendiri: wajar diterima (cuma di jaringan lokal).
    final s = await SecureSocket.connect(host, port, onBadCertificate: (_) => true, timeout: const Duration(seconds: 6));
    _socket = s;
    final reader = CastFrameReader();
    s.listen(
      (data) {
        for (final m in reader.add(data)) {
          _onMessage(m);
        }
      },
      onError: (_) => _close(),
      onDone: _close,
      cancelOnError: true,
    );
    _send('receiver-0', _nsConn, {'type': 'CONNECT'});
    _beat = Timer.periodic(const Duration(seconds: 5), (_) {
      if (DateTime.now().difference(_lastPong) > const Duration(seconds: 20)) {
        _close(); // TV gak jawab lagi
        return;
      }
      _send('receiver-0', _nsBeat, {'type': 'PING'});
    });
    await _launch();
  }

  Future<void> _launch() async {
    final res = await _request('receiver-0', _nsRecv, {'type': 'LAUNCH', 'appId': _defaultReceiver});
    final apps = (res['status'] as Map?)?['applications'];
    final app = apps is List
        ? apps.whereType<Map>().firstWhere((a) => a['appId'] == _defaultReceiver, orElse: () => const {})
        : const {};
    final t = app['transportId'];
    if (t is! String) throw const CastException('TV gak bisa buka pemutar.');
    _transport = t;
    _send(t, _nsConn, {'type': 'CONNECT'});
  }

  /// Putar lagu di TV mulai dari [start].
  Future<void> load({
    required String url,
    required String contentType,
    required String title,
    required String artist,
    required String album,
    String? coverUrl,
    Duration start = Duration.zero,
    bool autoplay = true,
  }) async {
    final t = _transport ?? (throw const CastException('Belum nyambung ke TV.'));
    final res = await _request(t, _nsMedia, {
      'type': 'LOAD',
      'autoplay': autoplay,
      'currentTime': start.inMilliseconds / 1000,
      'media': {
        'contentId': url,
        'contentUrl': url,
        'contentType': contentType,
        'streamType': 'BUFFERED',
        'metadata': {
          'metadataType': 3, // MusicTrackMediaMetadata
          'title': title,
          'artist': artist,
          'albumName': album,
          if (coverUrl != null)
            'images': [
              {'url': coverUrl},
            ],
        },
      },
    }, timeout: const Duration(seconds: 15));
    if (res['type'] == 'LOAD_FAILED' || res['type'] == 'LOAD_CANCELLED') {
      throw const CastException('TV gagal muter lagu ini.');
    }
  }

  void play() => _media({'type': 'PLAY'});
  void pause() => _media({'type': 'PAUSE'});
  void seek(Duration to) => _media({'type': 'SEEK', 'currentTime': to.inMilliseconds / 1000});

  /// Atur volume TV (0..1).
  void setVolume(double v) =>
      _send('receiver-0', _nsRecv, {'type': 'SET_VOLUME', 'volume': {'level': v.clamp(0.0, 1.0)}, 'requestId': _req++});

  void _media(Map<String, dynamic> m) {
    final t = _transport, s = _mediaSession;
    if (t == null || s == null) return;
    _send(t, _nsMedia, {...m, 'mediaSessionId': s, 'requestId': _req++});
  }

  /// Tutup pemutar di TV & putus.
  Future<void> stop() async {
    try {
      if (_transport != null) {
        await _request('receiver-0', _nsRecv, {'type': 'STOP'}, timeout: const Duration(seconds: 3));
      }
    } catch (_) {}
    _close();
  }

  void _onMessage(CastMessage m) {
    final j = m.json;
    if (j == null) return;
    final type = j['type'];
    if (m.namespace == _nsBeat) {
      _lastPong = DateTime.now();
      if (type == 'PING') _send(m.source, _nsBeat, {'type': 'PONG'});
      return;
    }
    if (m.namespace == _nsConn && type == 'CLOSE') {
      _close();
      return;
    }
    final id = j['requestId'];
    if (id is int && id != 0) _pending.remove(id)?.complete(j);
    if (m.namespace == _nsMedia && type == 'MEDIA_STATUS') {
      final list = j['status'];
      if (list is List && list.isNotEmpty && list.first is Map) {
        final st = list.first as Map;
        if (st['mediaSessionId'] is int) _mediaSession = st['mediaSessionId'] as int;
        final secs = st['currentTime'];
        _status.add(CastMediaStatus(
          state: (st['playerState'] as String?) ?? 'IDLE',
          position: Duration(milliseconds: secs is num ? (secs * 1000).round() : 0),
          idleReason: st['idleReason'] as String?,
        ));
      }
    }
    if (m.namespace == _nsRecv && type == 'RECEIVER_STATUS') {
      // Pemutar di TV ditutup dari luar (mis. pindah input / app lain dibuka).
      final apps = (j['status'] as Map?)?['applications'];
      if (_transport != null && (apps is! List || !apps.any((a) => a is Map && a['transportId'] == _transport))) {
        _close();
      }
    }
  }

  Future<Map<String, dynamic>> _request(String dest, String ns, Map<String, dynamic> body,
      {Duration timeout = const Duration(seconds: 8)}) {
    final id = _req++;
    final c = Completer<Map<String, dynamic>>();
    _pending[id] = c;
    _send(dest, ns, {...body, 'requestId': id});
    return c.future.timeout(timeout, onTimeout: () {
      _pending.remove(id);
      throw const CastException('TV gak jawab.');
    });
  }

  void _send(String dest, String ns, Map<String, dynamic> body) {
    final s = _socket;
    if (s == null || _closed.isCompleted) return;
    try {
      s.add(encodeCast(CastMessage(source: 'sender-0', destination: dest, namespace: ns, payload: jsonEncode(body))));
    } catch (_) {
      _close();
    }
  }

  void _close() {
    if (_closed.isCompleted) return;
    _beat?.cancel();
    try {
      _socket?.destroy();
    } catch (_) {}
    _socket = null;
    for (final c in _pending.values) {
      if (!c.isCompleted) c.completeError(const CastException('Sambungan ke TV putus.'));
    }
    _pending.clear();
    _closed.complete();
    _status.close();
  }
}

class CastException implements Exception {
  const CastException(this.message);
  final String message;
  @override
  String toString() => message;
}
