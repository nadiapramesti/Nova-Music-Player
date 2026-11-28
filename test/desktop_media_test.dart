import 'package:flutter_test/flutter_test.dart';
import 'package:nova/desktop/desktop_media.dart';

void main() {
  test('id lagu stabil, gak peduli garis miring & huruf besar', () {
    final a = DesktopMedia.idOf(r'C:\Users\Nadia\Music\Lagu.mp3');
    final b = DesktopMedia.idOf('c:/users/nadia/music/lagu.mp3');
    expect(a, b);
    expect(a, isNot(DesktopMedia.idOf('C:/Users/Nadia/Music/Lagu2.mp3')));
    expect(a, greaterThanOrEqualTo(0));
    expect(a, lessThan(1 << 53));
  });

  test('path dinormalisasi pakai /', () {
    expect(DesktopMedia.norm(r'D:\Lagu\K-pop\a.flac'), 'D:/Lagu/K-pop/a.flac');
  });
}
