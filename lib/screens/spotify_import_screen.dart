import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/services.dart';
import '../services/spotify/spotify.dart';
import '../theme.dart';
import '../widgets/art.dart';
import '../widgets/controls.dart';
import '../widgets/song_actions.dart';
import 'song_list_screen.dart';

// ---------------------------------------------------------------------------
// Kerangka layar: kilau, tombol kembali, judul, isi, dan bilah aksi di bawah.
// ---------------------------------------------------------------------------

class _Frame extends StatelessWidget {
  const _Frame({
    required this.eyebrow,
    required this.title,
    required this.body,
    this.subtitle,
    this.trailing,
    this.bottom,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget body;

  /// Tombol aksi utama, nempel di bawah.
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;
    return Scaffold(
      body: Stack(
        children: [
          const Glow(top: -140, right: -150, size: 400),
          Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20, pad.top + 10, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GlassCircleButton(
                          icon: Icons.arrow_back_rounded,
                          label: 'Kembali',
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        const Spacer(),
                        if (trailing != null) trailing!,
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(eyebrow.toUpperCase(), style: mono(TS.label, spacing: 1.2)),
                    const SizedBox(height: 4),
                    Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: disp(34, height: 1.02, spacing: -1.1)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(subtitle!, style: disp(TS.body, w: 500, color: Nv.muted, height: 1.35)),
                    ],
                    const SizedBox(height: 14),
                  ],
                ),
              ),
              Expanded(child: body),
              if (bottom != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 10, 16, pad.bottom + 14),
                  child: bottom,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Isi tengah buat loading / kosong / error: ikon dalam lingkaran kaca + teks.
class _State extends StatelessWidget {
  const _State({required this.icon, required this.title, required this.body, this.loading = false, this.action});

  final IconData icon;
  final String title;
  final String body;
  final bool loading;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Glass(
              radius: 36,
              child: SizedBox.square(
                dimension: 72,
                child: loading
                    ? Padding(
                        padding: const EdgeInsets.all(22),
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Nv.accent),
                      )
                    : Icon(icon, size: 30, color: Nv.accent),
              ),
            ),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: disp(TS.h3, spacing: -0.4)),
            const SizedBox(height: 6),
            Text(body, textAlign: TextAlign.center, style: disp(TS.body, w: 500, color: Nv.muted, height: 1.45)),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}

/// Cover playlist dari Spotify (butuh internet); kalau gagal, kotak bergradasi.
class _Cover extends StatelessWidget {
  const _Cover({required this.url, this.size = 56});
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Nv.accent.withAlpha(90), Nv.chip], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Center(child: Icon(Icons.queue_music_rounded, size: size * 0.42, color: Nv.text)),
    );
    final u = url;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: SizedBox.square(
        dimension: size,
        child: u == null
            ? fallback
            : Image.network(
                u,
                fit: BoxFit.cover,
                cacheWidth: (size * 3).round(),
                errorBuilder: (_, __, ___) => fallback,
                loadingBuilder: (_, child, p) => p == null ? child : ColoredBox(color: Nv.chip),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Login + pilih playlist
// ---------------------------------------------------------------------------

enum _Stage { checking, notConfigured, loggedOut, signingIn, loading, ready, error }

class SpotifyImportScreen extends StatefulWidget {
  const SpotifyImportScreen({super.key});

  static void open(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SpotifyImportScreen()));

  @override
  State<SpotifyImportScreen> createState() => _SpotifyImportScreenState();
}

class _SpotifyImportScreenState extends State<SpotifyImportScreen> {
  _Stage _stage = _Stage.checking;
  String _error = '';
  List<SpotifyPlaylist> _lists = const [];

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    if (!spotifyConfigured) return setState(() => _stage = _Stage.notConfigured);
    final ok = await spotifyAuth.loggedIn;
    if (!mounted) return;
    if (!ok) return setState(() => _stage = _Stage.loggedOut);
    await _load();
  }

  Future<void> _load() async {
    setState(() => _stage = _Stage.loading);
    try {
      final lists = await spotifyApi.myPlaylists();
      if (!mounted) return;
      setState(() {
        _lists = lists;
        _stage = _Stage.ready;
      });
    } on SpotifyAuthException catch (e) {
      if (mounted) setState(() => (_stage, _error) = (_Stage.loggedOut, e.message));
    } on SpotifyApiException catch (e) {
      if (!mounted) return;
      final relogin = e.status == 401;
      setState(() => (_stage, _error) = (relogin ? _Stage.loggedOut : _Stage.error, e.message));
    } catch (_) {
      if (mounted) setState(() => (_stage, _error) = (_Stage.error, 'Ada yang gak beres pas baca playlist. Coba lagi.'));
    }
  }

  Future<void> _login() async {
    setState(() => (_stage, _error) = (_Stage.signingIn, ''));
    try {
      await spotifyAuth.login();
      if (mounted) await _load();
    } on SpotifyAuthException catch (e) {
      if (mounted) setState(() => (_stage, _error) = (_Stage.loggedOut, e.cancelled ? '' : e.message));
    } catch (_) {
      if (mounted) setState(() => (_stage, _error) = (_Stage.loggedOut, 'Login gagal. Cek internet terus coba lagi.'));
    }
  }

  Future<void> _logout() async {
    await spotifyAuth.logout();
    if (mounted) setState(() => (_stage, _lists, _error) = (_Stage.loggedOut, const [], ''));
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = _stage == _Stage.ready || _stage == _Stage.loading || _stage == _Stage.error;
    return _Frame(
      eyebrow: 'Import',
      title: 'Playlist Spotify',
      subtitle: _stage == _Stage.ready && _lists.isNotEmpty
          ? '${_lists.length} playlist. Pilih satu buat dicocokin sama lagu di HP.'
          : 'Ambil daftar lagu dari Spotify, cocokin sama lagu yang udah ada di HP. Gak ada yang didownload.',
      trailing: signedIn ? GlassCircleButton(icon: Icons.logout_rounded, label: 'Keluar dari Spotify', onTap: _logout) : null,
      body: AnimatedSwitcher(duration: Motion.base, switchInCurve: Motion.enter, child: KeyedSubtree(key: ValueKey(_stage), child: _body())),
      bottom: switch (_stage) {
        _Stage.loggedOut => WideButton(label: 'Masuk ke Spotify', icon: Icons.login_rounded, onTap: _login),
        _Stage.error => WideButton(label: 'Coba lagi', icon: Icons.refresh_rounded, onTap: _load),
        _ => null,
      },
    );
  }

  Widget _body() {
    switch (_stage) {
      case _Stage.checking:
        return const SizedBox.shrink();
      case _Stage.notConfigured:
        return const _State(
          icon: Icons.key_rounded,
          title: 'Client ID belum diisi',
          body: 'Buka lib/services/spotify/spotify_config.dart, isi spotifyClientId dengan '
              'Client ID dari dashboard Spotify, lalu build ulang Nova.',
        );
      case _Stage.loggedOut:
        return _State(
          icon: Icons.link_rounded,
          title: _error.isEmpty ? 'Sambungin akun Spotify' : 'Belum nyambung',
          body: _error.isEmpty
              ? 'Nova cuma minta izin baca daftar playlist lu. Gak bisa ngubah, '
                  'gak bisa muter, gak download apa pun.'
              : _error,
        );
      case _Stage.signingIn:
        return const _State(
          icon: Icons.link_rounded,
          loading: true,
          title: 'Nunggu login…',
          body: 'Selesaiin login di halaman Spotify, nanti otomatis balik ke Nova.',
        );
      case _Stage.loading:
        return const _State(icon: Icons.queue_music_rounded, loading: true, title: 'Baca playlist…', body: 'Bentar, lagi ngambil daftar dari Spotify.');
      case _Stage.error:
        return _State(icon: Icons.cloud_off_rounded, title: 'Gagal baca playlist', body: _error);
      case _Stage.ready:
        if (_lists.isEmpty) {
          return const _State(
            icon: Icons.playlist_remove_rounded,
            title: 'Belum ada playlist',
            body: 'Akun Spotify ini belum punya playlist. Bikin dulu di Spotify, terus balik ke sini.',
          );
        }
        return RefreshIndicator(
          color: Nv.accent,
          onRefresh: _load,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: _lists.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _PlaylistTile(
              p: _lists[i],
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => _PreviewScreen(playlist: _lists[i])),
              ),
            ),
          ),
        );
    }
  }
}

class _PlaylistTile extends StatelessWidget {
  const _PlaylistTile({required this.p, required this.onTap});
  final SpotifyPlaylist p;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 20,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                _Cover(url: p.imageUrl),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: disp(TS.title, w: 700)),
                      const SizedBox(height: 3),
                      Text(
                        p.mine ? '${p.total} lagu' : '${p.total} lagu · punya ${p.ownerName.isEmpty ? 'orang lain' : p.ownerName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: disp(TS.caption, w: 500, color: Nv.muted),
                      ),
                      if (!p.mine) ...[
                        const SizedBox(height: 5),
                        Text('MUNGKIN GAK BISA DIBACA', style: mono(TS.monoTiny, color: Nv.accent, spacing: 1)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: Nv.chip, shape: BoxShape.circle, border: Border.all(color: Nv.line)),
                  child: Icon(Icons.chevron_right_rounded, color: Nv.text, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Preview hasil cocok → Import
// ---------------------------------------------------------------------------

class _PreviewScreen extends StatefulWidget {
  const _PreviewScreen({required this.playlist});
  final SpotifyPlaylist playlist;

  @override
  State<_PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<_PreviewScreen> {
  bool _loading = true;
  int _read = 0;
  String? _error;
  MatchResult? _result;
  bool _showMissing = false;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() => (_loading, _error, _read) = (true, null, 0));
    try {
      final tracks = await spotifyApi.playlistTracks(
        widget.playlist.id,
        onProgress: (n) {
          if (mounted) setState(() => _read = n);
        },
      );
      // Pakai pustaka Nova yang udah kebaca (gak scan ulang memori HP).
      final r = matchTracks(tracks, library.songs);
      if (!mounted) return;
      setState(() {
        _result = r;
        _loading = false;
        _showMissing = r.matched.isEmpty && r.missing.isNotEmpty;
      });
    } on SpotifyAuthException catch (e) {
      if (mounted) setState(() => (_loading, _error) = (false, e.message));
    } on SpotifyApiException catch (e) {
      if (mounted) setState(() => (_loading, _error) = (false, e.message));
    } catch (_) {
      if (mounted) setState(() => (_loading, _error) = (false, 'Ada yang gak beres pas baca lagu. Coba lagi.'));
    }
  }

  void _import() {
    final r = _result;
    if (r == null || r.matched.isEmpty || _importing) return;
    _importing = true;
    final name = uniquePlaylistName(widget.playlist.name, playlists.items.map((p) => p.name));
    final p = playlists.create(name, songIds: r.songIds);
    if (p == null) {
      _importing = false;
      showToast(context, 'Gagal bikin playlist');
      return;
    }
    showToast(context, '${r.matched.length} lagu masuk ke "$name"');
    // Ganti layar preview jadi playlist barunya; daftar playlist Spotify tetap di belakang.
    Navigator.of(context).pop();
    SongListScreen.openPlaylist(context, p.id);
  }

  Future<void> _copyMissing() async {
    final r = _result;
    if (r == null || r.missing.isEmpty) return;
    final text = r.missing.map((t) => '${t.title} — ${t.artistLine}').join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) showToast(context, 'Daftar "belum punya" disalin');
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    return _Frame(
      eyebrow: 'Dari Spotify',
      title: widget.playlist.name,
      subtitle: '${widget.playlist.total} lagu di Spotify',
      body: AnimatedSwitcher(
        duration: Motion.base,
        switchInCurve: Motion.enter,
        child: KeyedSubtree(
          key: ValueKey(_loading ? 'load' : _error != null ? 'err' : 'ok'),
          child: _loading
              ? _State(
                  icon: Icons.manage_search_rounded,
                  loading: true,
                  title: 'Nyocokin lagu…',
                  body: _read == 0 ? 'Ngambil isi playlist dari Spotify.' : '$_read lagu kebaca, lagi dicocokin sama lagu di HP.',
                )
              : _error != null
                  ? _State(icon: Icons.lock_outline_rounded, title: 'Playlist gak bisa dibaca', body: _error!)
                  : r!.matched.isEmpty && r.missing.isEmpty
                      ? const _State(
                          icon: Icons.playlist_remove_rounded,
                          title: 'Playlist kosong',
                          body: 'Gak ada lagu di sini (podcast & episode dilewatin).',
                        )
                      : _results(r),
        ),
      ),
      bottom: _loading
          ? null
          : _error != null
              ? WideButton(label: 'Coba lagi', icon: Icons.refresh_rounded, onTap: _run)
              : r == null || r.matched.isEmpty
                  ? (r != null && r.missing.isNotEmpty
                      ? WideButton(label: 'Salin daftar belum punya', icon: Icons.copy_rounded, primary: false, onTap: _copyMissing)
                      : null)
                  : WideButton(label: 'Import ${r.matched.length} lagu ke Nova', icon: Icons.download_done_rounded, onTap: _import),
    );
  }

  Widget _results(MatchResult r) {
    final total = r.matched.length + r.missing.length;
    final ratio = total == 0 ? 0.0 : r.matched.length / total;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Glass(
              radius: 22,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: _Count(value: r.matched.length, label: 'KETEMU', color: Nv.accent)),
                      Expanded(child: _Count(value: r.missing.length, label: 'BELUM PUNYA', color: Nv.text)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: ratio),
                      duration: Motion.slow,
                      curve: Motion.enter,
                      builder: (_, v, __) => LinearProgressIndicator(value: v, minHeight: 6, color: Nv.accent, backgroundColor: Nv.track),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    r.matched.isEmpty
                        ? 'Belum ada satu pun yang ada di HP.'
                        : '${(ratio * 100).round()}% playlist ini udah ada di HP lu.',
                    style: disp(TS.caption, w: 500, color: Nv.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Pill(label: 'Ketemu · ${r.matched.length}', selected: !_showMissing, onTap: () => setState(() => _showMissing = false)),
                const SizedBox(width: 8),
                Pill(label: 'Belum punya · ${r.missing.length}', selected: _showMissing, onTap: () => setState(() => _showMissing = true)),
                const Spacer(),
                if (_showMissing && r.missing.isNotEmpty && r.matched.isNotEmpty)
                  GlassCircleButton(icon: Icons.copy_rounded, label: 'Salin daftar belum punya', size: 38, onTap: _copyMissing),
              ],
            ),
          ),
        ),
        if (!_showMissing)
          SliverList.builder(
            itemCount: r.matched.length,
            itemBuilder: (_, i) {
              final (t, s) = r.matched[i];
              return _TrackRow(
                leading: Art(songId: s.id, size: 46, radius: 10),
                title: s.title,
                subtitle: s.artist,
                note: t.title != s.title ? 'Spotify: ${t.title}' : null,
                done: true,
              );
            },
          )
        else
          SliverList.builder(
            itemCount: r.missing.length,
            itemBuilder: (_, i) {
              final t = r.missing[i];
              return _TrackRow(
                leading: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Nv.line, width: 1.5),
                  ),
                  child: Icon(Icons.music_off_rounded, size: 20, color: Nv.muted),
                ),
                title: t.title,
                subtitle: t.artistLine.isEmpty ? 'Artis gak diketahui' : t.artistLine,
                done: false,
              );
            },
          ),
        if (_showMissing && r.missing.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text('Semua lagu udah ada di HP. Mantap.', textAlign: TextAlign.center, style: disp(TS.body, w: 500, color: Nv.muted)),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.value, required this.label, required this.color});
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: value),
          duration: Motion.slow,
          curve: Motion.enter,
          builder: (_, v, __) => Text('$v', style: disp(40, height: 1, spacing: -1.4, color: color)),
        ),
        const SizedBox(height: 4),
        Text(label, style: mono(TS.label, spacing: 1.2)),
      ],
    );
  }
}

class _TrackRow extends StatelessWidget {
  const _TrackRow({required this.leading, required this.title, required this.subtitle, required this.done, this.note});
  final Widget leading;
  final String title;
  final String subtitle;
  final String? note;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: disp(TS.title, w: 700, color: done ? Nv.text : Nv.muted)),
                const SizedBox(height: 2),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: disp(TS.caption, w: 500, color: Nv.muted)),
                if (note != null) ...[
                  const SizedBox(height: 2),
                  Text(note!, maxLines: 1, overflow: TextOverflow.ellipsis, style: mono(TS.monoTiny)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(done ? Icons.check_circle_rounded : Icons.remove_circle_outline_rounded, size: 20, color: done ? Nv.accent : Nv.line),
        ],
      ),
    );
  }
}
