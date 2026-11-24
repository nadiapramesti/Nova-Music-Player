import 'package:flutter_test/flutter_test.dart';
import 'package:nova/services/spotify/spotify.dart';

void main() {
  test('nama playlist gak bentrok', () {
    expect(uniquePlaylistName('Nyetir', ['Pagi']), 'Nyetir');
    expect(uniquePlaylistName('Nyetir', ['nyetir']), 'Nyetir (2)');
    expect(uniquePlaylistName('Nyetir', ['Nyetir', 'Nyetir (2)']), 'Nyetir (3)');
    expect(uniquePlaylistName('  ', []), 'Dari Spotify');
  });
}
