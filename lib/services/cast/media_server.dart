import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// Rentang byte dari header "Range: bytes=awal-akhir". Null = minta semua / gak valid.
({int start, int end})? parseRange(String? header, int size) {
  if (header == null || size <= 0) return null;
  final m = RegExp(r'^bytes=(\d*)-(\d*)$').firstMatch(header.trim());
  if (m == null) return null;
  final a = m[1]!, b = m[2]!;
  if (a.isEmpty && b.isEmpty) return null;
  if (a.isEmpty) {
    // "bytes=-500" = 500 byte terakhir
    final n = int.parse(b);
    if (n <= 0) return null;
    return (start: max(0, size - n), end: size - 1);
  }
  final start = int.parse(a);
  if (start >= size) return null;
  final end = b.isEmpty ? size - 1 : min(int.parse(b), size - 1);
  if (end < start) return null;
  return (start: start, end: end);
}

String audioMime(String path) {
  final ext = path.split('.').last.toLowerCase();
  return switch (ext) {
    'mp3' => 'audio/mpeg',
    'm4a' || 'mp4' || 'aac' => 'audio/mp4',
    'flac' => 'audio/flac',
    'ogg' || 'oga' || 'opus' => 'audio/ogg',
    'wav' => 'audio/wav',
    'webm' => 'audio/webm',
    _ => 'audio/mpeg',
  };
}

/// Server kecil di HP: TV ngambil file lagu & cover dari sini lewat WiFi.
/// Alamatnya pakai token acak, jadi perangkat lain di WiFi gak bisa asal ambil file.
class MediaServer {
  MediaServer({required this.pathOf, required this.coverOf});

  /// id lagu → path file di HP.
  final String? Function(int id) pathOf;

  /// id lagu → JPEG cover (boleh null).
  final Future<Uint8List?> Function(int id) coverOf;

  HttpServer? _server;
  String _host = '';
  final String _token = List.generate(16, (_) => Random.secure().nextInt(16).toRadixString(16)).join();

  bool get running => _server != null;

  Future<void> start() async {
    if (_server != null) return;
    _host = await localIp() ?? (throw const SocketException('HP belum nyambung WiFi'));
    final s = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    _server = s;
    s.listen(_handle, onError: (_) {});
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  String songUrl(int id) => 'http://$_host:${_server!.port}/$_token/song/$id';
  String coverUrl(int id) => 'http://$_host:${_server!.port}/$_token/cover/$id.jpg';

  /// Alamat IPv4 HP di jaringan lokal (WiFi).
  static Future<String?> localIp() async {
    final ifs = await NetworkInterface.list(type: InternetAddressType.IPv4);
    String? fallback;
    for (final i in ifs) {
      for (final a in i.addresses) {
        if (a.isLoopback) continue;
        final n = i.name.toLowerCase();
        if (n.startsWith('wlan') || n.startsWith('wifi') || n.startsWith('en')) return a.address;
        fallback ??= a.address;
      }
    }
    return fallback;
  }

  Future<void> _handle(HttpRequest req) async {
    final res = req.response;
    res.headers.set('Access-Control-Allow-Origin', '*');
    try {
      final seg = req.uri.pathSegments;
      if (seg.length != 3 || seg[0] != _token) {
        res.statusCode = HttpStatus.notFound;
        return;
      }
      if (seg[1] == 'cover') {
        final bytes = await coverOf(int.tryParse(seg[2].replaceAll('.jpg', '')) ?? -1);
        if (bytes == null) {
          res.statusCode = HttpStatus.notFound;
          return;
        }
        res.headers.contentType = ContentType('image', 'jpeg');
        res.contentLength = bytes.length;
        res.add(bytes);
        return;
      }
      final path = seg[1] == 'song' ? pathOf(int.tryParse(seg[2]) ?? -1) : null;
      final file = path == null ? null : File(path);
      if (file == null || !await file.exists()) {
        res.statusCode = HttpStatus.notFound;
        return;
      }
      final size = await file.length();
      final range = parseRange(req.headers.value(HttpHeaders.rangeHeader), size);
      res.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
      res.headers.contentType = ContentType.parse(audioMime(path!));
      if (range == null) {
        res.contentLength = size;
        if (req.method != 'HEAD') await res.addStream(file.openRead());
      } else {
        res.statusCode = HttpStatus.partialContent;
        res.headers.set(HttpHeaders.contentRangeHeader, 'bytes ${range.start}-${range.end}/$size');
        res.contentLength = range.end - range.start + 1;
        if (req.method != 'HEAD') await res.addStream(file.openRead(range.start, range.end + 1));
      }
    } catch (_) {
      // TV motong koneksi di tengah (biasa pas seek): abaikan.
    } finally {
      try {
        await res.close();
      } catch (_) {}
    }
  }
}
