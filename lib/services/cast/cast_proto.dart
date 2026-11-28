import 'dart:convert';
import 'dart:typed_data';

/// Pesan protokol Cast (CASTV2). Isinya protobuf kecil:
///   1 protocol_version (enum, 0) · 2 source_id · 3 destination_id
///   4 namespace · 5 payload_type (enum, 0 = STRING) · 6 payload_utf8
/// Tiap pesan di socket diawali panjang 4 byte (big-endian).
class CastMessage {
  const CastMessage({
    required this.source,
    required this.destination,
    required this.namespace,
    required this.payload,
  });

  final String source;
  final String destination;
  final String namespace;
  final String payload;

  Map<String, dynamic>? get json {
    try {
      final j = jsonDecode(payload);
      return j is Map<String, dynamic> ? j : null;
    } catch (_) {
      return null;
    }
  }
}

void _varint(BytesBuilder b, int v) {
  while (v >= 0x80) {
    b.addByte((v & 0x7f) | 0x80);
    v >>= 7;
  }
  b.addByte(v);
}

void _str(BytesBuilder b, int field, String s) {
  final bytes = utf8.encode(s);
  _varint(b, (field << 3) | 2);
  _varint(b, bytes.length);
  b.add(bytes);
}

/// Pesan → byte siap kirim (sudah ada awalan panjang).
Uint8List encodeCast(CastMessage m) {
  final body = BytesBuilder();
  _varint(body, (1 << 3) | 0); // protocol_version
  _varint(body, 0); //            CASTV2_1_0
  _str(body, 2, m.source);
  _str(body, 3, m.destination);
  _str(body, 4, m.namespace);
  _varint(body, (5 << 3) | 0); // payload_type
  _varint(body, 0); //            STRING
  _str(body, 6, m.payload);
  final b = body.toBytes();
  final out = Uint8List(4 + b.length);
  ByteData.view(out.buffer).setUint32(0, b.length);
  out.setRange(4, out.length, b);
  return out;
}

/// Isi protobuf (tanpa awalan panjang) → pesan. Field yang gak dikenal dilewatin.
CastMessage? decodeCastBody(Uint8List b) {
  var i = 0;
  int readVarint() {
    var shift = 0, result = 0;
    while (true) {
      if (i >= b.length) throw const FormatException('varint kepotong');
      final byte = b[i++];
      result |= (byte & 0x7f) << shift;
      if (byte & 0x80 == 0) return result;
      shift += 7;
      if (shift > 63) throw const FormatException('varint kepanjangan');
    }
  }

  String? src, dst, ns, payload;
  try {
    while (i < b.length) {
      final key = readVarint();
      final field = key >> 3, wire = key & 7;
      if (wire == 0) {
        readVarint();
      } else if (wire == 2) {
        final len = readVarint();
        if (i + len > b.length) throw const FormatException('isi kepotong');
        final bytes = b.sublist(i, i + len);
        i += len;
        final s = utf8.decode(bytes, allowMalformed: true);
        switch (field) {
          case 2:
            src = s;
          case 3:
            dst = s;
          case 4:
            ns = s;
          case 6:
            payload = s;
        }
      } else if (wire == 5) {
        i += 4;
      } else if (wire == 1) {
        i += 8;
      } else {
        return null;
      }
    }
  } on FormatException {
    return null;
  }
  if (src == null || dst == null || ns == null) return null;
  return CastMessage(source: src, destination: dst, namespace: ns, payload: payload ?? '');
}

/// Potong aliran byte dari socket jadi pesan utuh; sisa yang belum lengkap disimpan.
class CastFrameReader {
  final _buf = BytesBuilder(copy: false);
  Uint8List _pending = Uint8List(0);

  List<CastMessage> add(List<int> chunk) {
    _buf.add(_pending);
    _buf.add(chunk);
    var data = _buf.takeBytes();
    final out = <CastMessage>[];
    var off = 0;
    while (data.length - off >= 4) {
      final len = ByteData.view(data.buffer, data.offsetInBytes + off, 4).getUint32(0);
      if (len > 1 << 20) {
        // Ngaco (> 1 MB): buang semua biar gak macet.
        _pending = Uint8List(0);
        return out;
      }
      if (data.length - off - 4 < len) break;
      final m = decodeCastBody(Uint8List.sublistView(data, off + 4, off + 4 + len));
      if (m != null) out.add(m);
      off += 4 + len;
    }
    _pending = Uint8List.fromList(data.sublist(off));
    return out;
  }
}
