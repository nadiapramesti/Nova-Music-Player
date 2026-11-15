import 'package:flutter/material.dart';

import '../models.dart';
import '../services/lyrics.dart';
import '../services/services.dart';
import '../theme.dart';
import 'controls.dart';

/// Lirik di layar pemutar. Lirik sinkron: baris aktif menyala & otomatis
/// digulir ke tengah, tap baris = loncat ke situ.
class LyricsView extends StatefulWidget {
  const LyricsView({super.key, required this.song});
  final Song song;

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  late Future<Lyrics?> _future = lyrics.of(widget.song);
  final _scroll = ScrollController();
  List<GlobalKey> _keys = [];
  int _shown = -2;

  @override
  void didUpdateWidget(LyricsView old) {
    super.didUpdateWidget(old);
    if (old.song.id != widget.song.id) {
      _future = lyrics.of(widget.song);
      _shown = -2;
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _follow(int index) {
    if (index == _shown || index < 0 || index >= _keys.length) return;
    _shown = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _keys[index].currentContext;
      if (ctx != null && mounted) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.4,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Lyrics?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Center(child: SizedBox.square(dimension: 26, child: CircularProgressIndicator(strokeWidth: 2.5, color: Nv.accent)));
        }
        final data = snap.data;
        if (data == null) return _Empty(onRetry: () => setState(() => _future = lyrics.of(widget.song)));
        if (_keys.length != data.lines.length) {
          _keys = List.generate(data.lines.length, (_) => GlobalKey());
        }
        return ShaderMask(
          // Pudar di atas & bawah biar baris yang lewat gak kepotong kasar.
          shaderCallback: (r) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x00FFFFFF), Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0x00FFFFFF)],
            stops: [0, 0.12, 0.85, 1],
          ).createShader(r),
          blendMode: BlendMode.dstIn,
          child: data.synced ? _synced(data) : _plain(data),
        );
      },
    );
  }

  Widget _synced(Lyrics data) {
    return StreamBuilder<Duration>(
      stream: audio.player.positionStream,
      builder: (context, snap) {
        // Muncul sedikit lebih awal biar pas sama suara.
        final pos = (snap.data ?? Duration.zero) + const Duration(milliseconds: 250);
        final active = data.indexAt(pos);
        _follow(active);
        return ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.symmetric(vertical: 60),
          itemCount: data.lines.length + 1,
          itemBuilder: (context, i) {
            if (i == data.lines.length) return _sourceNote(data);
            final line = data.lines[i];
            final on = i == active;
            final passed = i < active;
            return InkWell(
              key: _keys[i],
              borderRadius: BorderRadius.circular(12),
              onTap: line.time == null ? null : () => audio.player.seek(line.time),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 260),
                  style: disp(
                    on ? 25 : 21,
                    w: 800,
                    spacing: -0.5,
                    height: 1.2,
                    color: on ? Nv.text : (passed ? Nv.muted.withAlpha(150) : Nv.muted),
                  ),
                  child: Text(line.text.isEmpty ? '♪' : line.text),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _plain(Lyrics data) {
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(6, 40, 6, 40),
      children: [
        for (final l in data.lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(l.text, style: disp(TS.h3, w: 700, height: 1.35, color: Nv.text)),
          ),
        _sourceNote(data),
      ],
    );
  }

  Widget _sourceNote(Lyrics data) => Padding(
        padding: const EdgeInsets.fromLTRB(6, 18, 6, 0),
        child: Text(
          data.synced ? 'LIRIK SINKRON · ${data.source.toUpperCase()}' : 'LIRIK · ${data.source.toUpperCase()}',
          style: mono(TS.monoTiny, spacing: 1.2),
        ),
      );
}

class _Empty extends StatefulWidget {
  const _Empty({required this.onRetry});
  final VoidCallback onRetry;

  @override
  State<_Empty> createState() => _EmptyState();
}

class _EmptyState extends State<_Empty> with WidgetsBindingObserver {
  bool? _access;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Balik dari halaman izin: cek ulang & coba cari lirik lagi.
    if (state == AppLifecycleState.resumed) {
      _check().then((_) {
        if (_access == true) {
          lyrics.clear();
          widget.onRetry();
        }
      });
    }
  }

  Future<void> _check() async {
    final ok = await lyrics.hasFileAccess();
    if (mounted) setState(() => _access = ok);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lyrics_outlined, size: 40, color: Nv.accent),
            const SizedBox(height: 12),
            Text('Lirik belum ada', style: disp(TS.h2, spacing: -0.5)),
            const SizedBox(height: 6),
            Text(
              'Nova baca lirik yang tertanam di file lagu, atau file .lrc dengan nama yang sama '
              'di folder lagunya (contoh: "Senja.mp3" + "Senja.lrc").',
              textAlign: TextAlign.center,
              style: disp(TS.body, w: 500, color: Nv.muted, height: 1.4),
            ),
            if (_access == false) ...[
              const SizedBox(height: 16),
              Text(
                'Buat baca file .lrc, Android minta izin "akses semua file".',
                textAlign: TextAlign.center,
                style: disp(TS.caption, w: 600, color: Nv.muted, height: 1.35),
              ),
              const SizedBox(height: 10),
              WideButton(
                label: 'Izinkan baca file .lrc',
                icon: Icons.folder_open_rounded,
                onTap: lyrics.requestFileAccess,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
