import 'package:flutter_test/flutter_test.dart';
import 'package:nova/services/spotify/spotify_api.dart';
import 'package:nova/services/spotify/spotify_auth.dart';

void main() {
  test('PKCE challenge sesuai contoh RFC 7636', () {
    expect(pkceChallenge('dBjftJeZ4CVP-mJ92K9mWhs7tAJ3s-dnjnRe6vgBcK4'), 'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM');
  });

  test('verifier 64 huruf yang diizinkan', () {
    final v = pkceVerifier();
    expect(v.length, 64);
    expect(RegExp(r'^[A-Za-z0-9\-._~]+$').hasMatch(v), isTrue);
  });

  test('token bolak-balik & refresh lama dipertahankan', () {
    final t = SpotifyToken.fromResponse({'access_token': 'a', 'expires_in': 3600}, previousRefresh: 'r0');
    expect(t.refresh, 'r0');
    expect(t.expired, isFalse);
    final back = SpotifyToken.decode(t.encode())!;
    expect(back.access, 'a');
    expect(SpotifyToken.decode('rusak'), isNull);
    expect(SpotifyToken.fromResponse({'access_token': 'a', 'expires_in': 30}).expired, isTrue);
  });

  group('trackFromItem', () {
    test('format baru (item) & lama (track)', () {
      final a = trackFromItem({
        'item': {
          'type': 'track',
          'name': 'Animals',
          'duration_ms': 231000,
          'artists': [
            {'name': 'Maroon 5'},
          ],
          'album': {'name': 'V'},
        },
      })!;
      expect(a.title, 'Animals');
      expect(a.artists, ['Maroon 5']);
      expect(a.durationMs, 231000);
      final b = trackFromItem({
        'track': {'type': 'track', 'name': 'Yellow', 'artists': []},
      })!;
      expect(b.title, 'Yellow');
    });

    test('podcast, kosong, & data aneh dilewatin', () {
      expect(trackFromItem({'item': {'type': 'episode', 'name': 'Podcast'}}), isNull);
      expect(trackFromItem({'item': null, 'track': null}), isNull);
      expect(trackFromItem('aneh'), isNull);
      expect(trackFromItem({'item': {'type': 'track', 'name': '  '}}), isNull);
    });
  });

  test('playlist: jumlah dari items/tracks, milik sendiri atau bukan', () {
    final p = SpotifyPlaylist.fromJson({
      'id': 'x',
      'name': 'Nyetir',
      'items': {'total': 12},
      'owner': {'id': 'me', 'display_name': 'Nadia'},
      'images': [
        {'url': 'big', 'width': 640},
        {'url': 'small', 'width': 300},
        {'url': 'tiny', 'width': 60},
      ],
    }, 'me')!;
    expect(p.total, 12);
    expect(p.mine, isTrue);
    expect(p.imageUrl, 'small');
    final other = SpotifyPlaylist.fromJson({
      'id': 'y',
      'name': '',
      'tracks': {'total': 3},
      'owner': {'id': 'orang'},
    }, 'me')!;
    expect(other.total, 3);
    expect(other.mine, isFalse);
    expect(other.name, 'Tanpa nama');
  });
}
