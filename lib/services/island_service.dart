import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../demo/demo.dart';
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

  /// Pulau ngilang sendiri setelah beberapa detik, muncul lagi pas ganti lagu / play-jeda.
  bool autoHide = true;

  /// Layanan Aksesibilitas Nova aktif: pulau native tipis tampil di notch, di dalam
  /// maupun di luar app (pulau Flutter disembunyikan).
  bool precise = false;

  bool get nativeEverywhere => precise && outside;
  bool _waitingPermission = false;

  Future<void> init(PlayerService audio, StatsService stats) async {
    if (kDemo) {
      inApp = false;
      outside = false;
      return;
    }
    final p = await SharedPreferences.getInstance();
    _p = p;
    inApp = p.getBool('islandInApp') ?? true;
    outside = p.getBool('islandOutside') ?? false;
    autoHide = p.getBool('islandAutoHide') ?? true;
    if (outside && !await canDraw()) outside = false;
    await _send('setAutoHide', autoHide);
    await _send('setEnabled', outside);

    precise = await _isPrecise();
    WidgetsBinding.instance.addObserver(this);
    void push() => _send('update', {
          'id': audio.current.value?.id ?? -1,
          'title': audio.current.value?.title ?? '',
          'artist': audio.current.value?.artist ?? '',
          'playing': audio.player.playing,
        });
    audio.current.addListener(push);
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

  Future<bool> _isPrecise() async {
    try {
      return await _ch.invokeMethod<bool>('precise') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> openAccessibility() => _send('openAccessibility', null);

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

  void setAutoHide(bool v) {
    autoHide = v;
    _p?.setBool('islandAutoHide', v);
    _send('setAutoHide', v);
    notifyListeners();
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
    if (state == AppLifecycleState.resumed) {
      _isPrecise().then((p) {
        if (p != precise) {
          precise = p;
          notifyListeners();
        }
      });
    }
    if (state == AppLifecycleState.resumed && _waitingPermission) {
      _waitingPermission = false;
      canDraw().then((ok) {
        if (ok) setOutside(true);
      });
    }
  }
}
