import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../demo/demo.dart';
import '../platform.dart';
import '../theme.dart';
import 'player_service.dart';
import 'stats_service.dart';

/// Pengaturan pulau di notch:
/// - [inApp]: tampil di dalam Nova.
/// - [outside]: tetap tampil di atas app lain (butuh izin "tampil di atas app lain").
class IslandService extends ChangeNotifier with WidgetsBindingObserver {
  static const _ch = MethodChannel('nova/overlay');

  SharedPreferences? _p;
  bool inApp = true;
  bool outside = false;

  /// Pulau selalu ngilang sendiri setelah beberapa detik, muncul lagi pas ganti
  /// lagu / play-jeda (dulu bisa dimatiin, sekarang otomatis).
  final bool autoHide = true;
  bool _waitingPermission = false;

  Future<void> init(PlayerService audio, StatsService stats) async {
    // Laptop punya pulau sendiri (lib/desktop/desktop_island.dart).
    if (kDemo || isDesktop) {
      inApp = false;
      outside = false;
      return;
    }
    final p = await SharedPreferences.getInstance();
    _p = p;
    // Bawaannya mati: di dalam Nova info lagu udah ada di pemutar mini.
    inApp = p.getBool('islandInApp') ?? false;
    outside = p.getBool('islandOutside') ?? false;
    if (outside && !await canDraw()) outside = false;
    await _send('setAutoHide', true);
    await _send('setEnabled', outside);

    WidgetsBinding.instance.addObserver(this);
    void push() => _send('update', {
          'id': audio.current.value?.id ?? -1,
          'title': audio.current.value?.title ?? '',
          'artist': audio.current.value?.artist ?? '',
          'playing': audio.player.playing,
          'accent': Nv.accent.toARGB32(),
        });
    audio.current.addListener(push);
    // Aksen ikut cover → kartu di luar app ikut ganti warna.
    paletteVersion.addListener(push);
    audio.player.playingStream.listen((_) => push());

    // Progres & favorit buat kartu di luar app (dikirim tiap ganti detik).
    var lastSec = -1;
    void pushProgress([Duration? p]) {
      if (!outside) return;
      final song = audio.current.value;
      if (song == null) return;
      final pos = p ?? audio.player.position;
      _send('progress', {
        'pos': pos.inMilliseconds,
        'dur': (audio.player.duration ?? song.duration).inMilliseconds,
        'fav': stats.isFav(song.id),
      });
    }

    audio.player.positionStream.listen((p) {
      if (p.inSeconds == lastSec) return;
      lastSec = p.inSeconds;
      pushProgress(p);
    });
    stats.addListener(pushProgress);

    // Tombol di kartu luar app: loncat & favorit.
    _ch.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'seek':
          final f = (call.arguments as num).toDouble();
          final d = audio.player.duration ?? audio.current.value?.duration;
          if (d != null) await audio.player.seek(d * f);
        case 'toggleFav':
          final id = audio.current.value?.id;
          if (id != null) stats.toggleFav(id);
      }
      return null;
    });
  }

  Future<bool> canDraw() async {
    try {
      return await _ch.invokeMethod<bool>('canDraw') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _send(String method, Object? args) async {
    try {
      await _ch.invokeMethod<void>(method, args);
    } catch (_) {}
  }

  /// Tampilkan pil di luar app selama 5 detik. Balikin pesan error, null kalau berhasil.
  Future<String?> test() async {
    try {
      return await _ch.invokeMethod<String>('test');
    } catch (e) {
      return e.toString();
    }
  }

  /// Buka halaman izin "tampil di atas app lain"; dicek lagi pas balik ke Nova.
  Future<void> requestPermission() async {
    _waitingPermission = true;
    await _send('requestPermission', null);
  }

  void setInApp(bool v) {
    inApp = v;
    _p?.setBool('islandInApp', v);
    notifyListeners();
  }

  Future<void> setOutside(bool v) async {
    if (v && !await canDraw()) {
      // Buka pengaturan izin; dicek lagi pas balik ke app.
      _waitingPermission = true;
      await _send('requestPermission', null);
      return;
    }
    outside = v;
    _p?.setBool('islandOutside', v);
    await _send('setEnabled', v);
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingPermission) {
      _waitingPermission = false;
      canDraw().then((ok) {
        if (ok) setOutside(true);
      });
    }
  }
}
