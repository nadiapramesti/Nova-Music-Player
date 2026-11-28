import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nova/services/cast/cast_proto.dart';
import 'package:nova/services/cast/media_server.dart';

void main() {
  group('protokol Cast', () {
    const msg = CastMessage(
      source: 'sender-0',
      destination: 'receiver-0',
      namespace: 'urn:x-cast:com.google.cast.tp.connection',
      payload: '{"type":"CONNECT","judul":"Lagu ✨"}',
    );

    test('encode → decode utuh (termasuk huruf non-ASCII)', () {
      final bytes = encodeCast(msg);
      final len = ByteData.view(bytes.buffer).getUint32(0);
      expect(len, bytes.length - 4);
      final back = decodeCastBody(Uint8List.sublistView(bytes, 4))!;
      expect(back.source, 'sender-0');
      expect(back.destination, 'receiver-0');
      expect(back.namespace, msg.namespace);
      expect(back.json!['judul'], 'Lagu ✨');
    });

    test('payload panjang (> 127 byte, varint 2 byte)', () {
      final long = CastMessage(source: 'a', destination: 'b', namespace: 'c', payload: 'x' * 5000);
      final b = encodeCast(long);
      expect(decodeCastBody(Uint8List.sublistView(b, 4))!.payload.length, 5000);
    });

    test('pembaca frame: potongan acak & dua pesan nempel', () {
      final a = encodeCast(msg);
      final b = encodeCast(const CastMessage(source: 's', destination: 'd', namespace: 'n', payload: '{"type":"PING"}'));
      final all = [...a, ...b];
      final r = CastFrameReader();
      final got = <CastMessage>[];
      for (var i = 0; i < all.length; i += 7) {
        got.addAll(r.add(all.sublist(i, i + 7 > all.length ? all.length : i + 7)));
      }
      expect(got.length, 2);
      expect(got[1].json!['type'], 'PING');
    });

    test('data rusak gak bikin crash', () {
      expect(decodeCastBody(Uint8List.fromList([0x12, 0x50, 0x41])), isNull);
      expect(CastFrameReader().add([0xff, 0xff, 0xff, 0xff, 1, 2]), isEmpty);
    });
  });

  group('server lagu', () {
    test('Range', () {
      expect(parseRange('bytes=0-99', 1000), (start: 0, end: 99));
      expect(parseRange('bytes=500-', 1000), (start: 500, end: 999));
      expect(parseRange('bytes=-100', 1000), (start: 900, end: 999));
      expect(parseRange('bytes=900-5000', 1000), (start: 900, end: 999));
      expect(parseRange('bytes=1000-', 1000), isNull);
      expect(parseRange('bytes=50-10', 1000), isNull);
      expect(parseRange(null, 1000), isNull);
      expect(parseRange('ngaco', 1000), isNull);
    });

    test('tipe file', () {
      expect(audioMime('/m/a.MP3'), 'audio/mpeg');
      expect(audioMime('/m/a.m4a'), 'audio/mp4');
      expect(audioMime('/m/a.flac'), 'audio/flac');
      expect(audioMime('/m/a.opus'), 'audio/ogg');
      expect(audioMime('/m/tanpa-ekstensi'), 'audio/mpeg');
    });
  });
}
