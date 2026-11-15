import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

/// Sumber audio senyap (WAV 8 kHz, 8-bit, mono) sepanjang [durationMs].
/// Dipakai di mode demo supaya pemutar beneran jalan (posisi, antrean,
/// notifikasi) tanpa butuh file musik asli.
class SilentAudioSource extends StreamAudioSource {
  SilentAudioSource({required this.durationMs, super.tag});

  final int durationMs;

  static const _rate = 8000;
  static const _headerSize = 44;

  int get _dataSize => durationMs * _rate ~/ 1000;
  int get totalSize => _headerSize + _dataSize;

  Uint8List _header() {
    final b = ByteData(_headerSize);
    void ascii(int at, String s) {
      for (var i = 0; i < s.length; i++) {
        b.setUint8(at + i, s.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    b.setUint32(4, 36 + _dataSize, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    b.setUint32(16, 16, Endian.little); // ukuran chunk fmt
    b.setUint16(20, 1, Endian.little); // PCM
    b.setUint16(22, 1, Endian.little); // mono
    b.setUint32(24, _rate, Endian.little);
    b.setUint32(28, _rate, Endian.little); // byte rate
    b.setUint16(32, 1, Endian.little); // block align
    b.setUint16(34, 8, Endian.little); // bit per sample
    ascii(36, 'data');
    b.setUint32(40, _dataSize, Endian.little);
    return b.buffer.asUint8List();
  }

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final from = start ?? 0;
    final to = (end ?? totalSize).clamp(from, totalSize);
    final out = Uint8List(to - from);
    // Sampel 8-bit unsigned: 128 = hening.
    out.fillRange(0, out.length, 128);
    if (from < _headerSize) {
      final h = _header();
      for (var i = from; i < _headerSize && i < to; i++) {
        out[i - from] = h[i];
      }
    }
    return StreamAudioResponse(
      sourceLength: totalSize,
      contentLength: out.length,
      offset: from,
      stream: Stream.value(out),
      contentType: 'audio/wav',
    );
  }
}
