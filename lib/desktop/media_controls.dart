import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:smtc_windows/smtc_windows.dart';

import '../services/services.dart';

/// Panel media Windows + tombol play/next di keyboard (kayak notifikasi musik di HP).
class DesktopMediaControls {
  DesktopMediaControls._();
  static SMTCWindows? _smtc;

  static Future<void> init() async {
    if (!Platform.isWindows) return;
    try {
      await SMTCWindows.initialize();
      final smtc = SMTCWindows(
        metadata: const MusicMetadata(title: 'Nova', artist: '', album: '', albumArtist: ''),
        timeline: const PlaybackTimeline(
          startTimeMs: 0,
          endTimeMs: 0,
          positionMs: 0,
          minSeekTimeMs: 0,
          maxSeekTimeMs: 0,
        ),
        config: const SMTCConfig(
          playEnabled: true,
          pauseEnabled: true,
          stopEnabled: false,
          nextEnabled: true,
          prevEnabled: true,
          fastForwardEnabled: false,
          rewindEnabled: false,
        ),
      );
      _smtc = smtc;
      smtc.buttonPressStream.listen((b) {
        switch (b) {
          case PressedButton.play:
            audio.player.play();
          case PressedButton.pause:
            audio.player.pause();
          case PressedButton.next:
            audio.player.seekToNext();
          case PressedButton.previous:
            audio.player.seekToPrevious();
          default:
            break;
        }
      });
      audio.current.addListener(_meta);
      audio.player.playingStream.listen((p) {
        try {
          smtc.setPlaybackStatus(p ? PlaybackStatus.playing : PlaybackStatus.paused);
        } catch (_) {}
      });
      _meta();
    } catch (_) {
      // Panel media gagal nyala: Nova tetap jalan, cuma tanpa tombol media Windows.
    }
  }

  static Future<void> _meta() async {
    final smtc = _smtc;
    final s = audio.current.value;
    if (smtc == null || s == null) return;
    String? thumb;
    try {
      final bytes = await Artwork.of(s.id, 300);
      if (bytes != null) {
        final f = File('${(await getTemporaryDirectory()).path}/nova-smtc-${s.id}.jpg');
        if (!await f.exists()) await f.writeAsBytes(bytes);
        thumb = f.uri.toString();
      }
    } catch (_) {}
    try {
      await smtc.updateMetadata(MusicMetadata(
        title: s.title,
        artist: s.artist,
        album: s.album,
        albumArtist: s.artist,
        thumbnail: thumb,
      ));
    } catch (_) {}
  }
}
