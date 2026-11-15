import 'package:flutter/material.dart';

import '../models.dart';
import '../services/services.dart';
import '../theme.dart';
import '../widgets/song_row.dart';
import 'now_playing_screen.dart';
import 'song_list_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _set(String v) {
    _controller.text = v;
    _controller.selection = TextSelection.collapsed(offset: v.length);
    setState(() => _q = v);
  }

  List<Song> _results() {
    final q = _q.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return library.songs
        .where((s) =>
            s.title.toLowerCase().contains(q) ||
            s.artist.toLowerCase().contains(q) ||
            s.album.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return ListenableBuilder(
      listenable: Listenable.merge([library, stats]),
      builder: (context, _) {
        final results = _results();
        final searching = _q.trim().isNotEmpty;
        return Stack(
          children: [
            const Glow(top: 20, left: -110, size: 360),
            ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(0, top + 14, 0, 200),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Cari', style: disp(40, spacing: -1.6)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Text('JUDUL, ARTIS, ATAU ALBUM', style: mono(TS.label, spacing: 1.2)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                  child: Glass(
                    radius: 18,
                    borderColor: const Color(0x52ECEEF5),
                    child: TextField(
                      controller: _controller,
                      onChanged: (v) => setState(() => _q = v),
                      onSubmitted: stats.addRecent,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.search,
                      style: disp(TS.title, w: 600),
                      decoration: InputDecoration(
                        hintText: 'Contoh: Hujan Bulan Juni',
                        hintStyle: disp(TS.title, w: 500, color: Nv.muted),
                        prefixIcon: Icon(Icons.search_rounded, color: Nv.text),
                        suffixIcon: _q.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Hapus',
                                icon: Icon(Icons.close_rounded, color: Nv.text),
                                onPressed: () => _set(''),
                              ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 17),
                      ),
                    ),
                  ),
                ),
                if (searching) ..._resultList(results) else ..._idle(context),
              ],
            ),
          ],
        );
      },
    );
  }

  List<Widget> _resultList(List<Song> results) {
    if (results.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
          child: Text('Gak ketemu. Coba kata kunci lain.',
              textAlign: TextAlign.center, style: disp(TS.body, w: 500, color: Nv.muted)),
        ),
      ];
    }
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        child: Text('${results.length} HASIL', style: mono(TS.label, spacing: 1)),
      ),
      for (final (i, s) in results.indexed)
        SongRow(
          song: s,
          number: i + 1,
          onTap: () {
            stats.addRecent(_q);
            playAndOpen(context, results, i, from: 'Hasil cari · ${_q.trim()}');
          },
        ),
    ];
  }

  List<Widget> _idle(BuildContext context) {
    final all = library.songs;
    final tiles = [
      (eyebrow: 'TOP 25', title: 'Paling sering diputar', songs: stats.mostPlayed(all),
          empty: 'Putar beberapa lagu dulu, nanti yang paling sering muncul di sini.'),
      (eyebrow: '> 90 HARI', title: 'Lama gak didengar', songs: stats.forgotten(all),
          empty: 'Semua lagu lu baru-baru ini didengar. Mantap.'),
      (eyebrow: 'MINGGU INI', title: 'Baru masuk HP', songs: stats.newThisWeek(all),
          empty: 'Gak ada lagu baru minggu ini.'),
      (eyebrow: 'FAVORIT', title: 'Yang lu sukai', songs: stats.favoriteSongs(all),
          empty: 'Tekan ikon hati di layar pemutar buat nambahin favorit.'),
    ];

    return [
      if (stats.recent.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
          child: Text('Terakhir dicari', style: disp(TS.h3, spacing: -0.5)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final r in stats.recent)
                Material(
                  color: Colors.transparent,
                  shape: StadiumBorder(side: BorderSide(color: Nv.line, width: 1.5)),
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: () => _set(r),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      child: Text(r, style: disp(TS.body, w: 700)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        child: Text('Putar dari catatan lu', style: disp(TS.h3, spacing: -0.5)),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final (i, t) in tiles.indexed)
              _Tile(
                eyebrow: t.eyebrow,
                title: t.title,
                highlight: i == 0,
                onTap: () => SongListScreen.open(
                  context,
                  eyebrow: t.eyebrow,
                  title: t.title,
                  songs: t.songs,
                  emptyText: t.empty,
                ),
              ),
          ],
        ),
      ),
    ];
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.eyebrow, required this.title, required this.highlight, required this.onTap});

  final String eyebrow;
  final String title;
  final bool highlight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = highlight ? Nv.onAccent : Nv.text;
    final content = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(eyebrow, style: mono(TS.label, color: highlight ? Nv.onAccent : Nv.muted)),
              Text(title, style: disp(TS.lead, height: 1.05, spacing: -0.4, color: fg)),
            ],
          ),
        ),
      ),
    );
    if (highlight) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: ColoredBox(color: Nv.accent, child: content),
      );
    }
    return Glass(radius: 18, child: content);
  }
}
