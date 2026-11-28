import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Gagang gulir cepat di tepi kanan buat daftar panjang.
///
/// Muncul pas daftar digulir, hilang sendiri kalau diam. Gagangnya bisa
/// ditarik buat lompat; selama ditarik ada gelembung penanda (huruf awal,
/// atau bulan lagu masuk) biar tau lagi di mana.
///
/// Gak butuh ScrollController: posisi gulir diambil dari notifikasi daftar
/// di dalamnya.
class FastScroller extends StatefulWidget {
  const FastScroller({
    super.key,
    required this.child,
    required this.itemCount,
    required this.itemExtent,
    this.listKey,
    this.labelAt,
    this.pinnedExtent = 0,
    this.padding = EdgeInsets.zero,
    this.minItems = 40,
  });

  final Widget child;
  final int itemCount;

  /// Tinggi tetap tiap baris (daftar harus SliverFixedExtentList).
  final double itemExtent;

  /// Key yang dipasang di sliver daftar, buat tau daftar mulai di piksel berapa.
  final GlobalKey? listKey;

  /// Penanda gelembung buat baris ke-i. Null = tanpa gelembung.
  final String Function(int index)? labelAt;

  /// Tinggi bilah yang nempel di atas (baris di bawahnya yang dianggap "sekarang").
  final double pinnedExtent;

  /// Jalur gagang: jarak dari atas & bawah (biar gak ketutup dek / bilah).
  final EdgeInsets padding;

  /// Di bawah jumlah ini gagang gak dipasang (daftar pendek gak butuh).
  final int minItems;

  @override
  State<FastScroller> createState() => _FastScrollerState();
}

class _FastScrollerState extends State<FastScroller> {
  static const _thumbH = 46.0;

  final _frac = ValueNotifier<double>(0);
  ScrollPosition? _pos;
  bool _visible = false;
  bool _dragging = false;
  String? _label;
  Timer? _hide;

  bool get _enabled => widget.itemCount >= widget.minItems;

  @override
  void dispose() {
    _hide?.cancel();
    _frac.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || !_enabled) return false;
    final ctx = n.context;
    if (ctx != null) _pos = Scrollable.maybeOf(ctx)?.position ?? _pos;
    final m = n.metrics;
    if (m.maxScrollExtent <= 0) return false;
    _frac.value = (m.pixels / m.maxScrollExtent).clamp(0.0, 1.0);
    if (n is ScrollUpdateNotification) _show();
    if (n is ScrollEndNotification && !_dragging) _scheduleHide();
    if (_dragging) _updateLabel(m.pixels);
    return false;
  }

  void _show() {
    _hide?.cancel();
    if (!_visible) setState(() => _visible = true);
  }

  void _scheduleHide() {
    _hide?.cancel();
    _hide = Timer(const Duration(milliseconds: 1400), () {
      if (mounted && !_dragging) setState(() => _visible = false);
    });
  }

  double _listStart() {
    final ro = widget.listKey?.currentContext?.findRenderObject();
    if (ro is! RenderSliver) return 0;
    try {
      return ro.constraints.precedingScrollExtent;
    } catch (_) {
      return 0;
    }
  }

  void _updateLabel(double pixels) {
    final at = widget.labelAt;
    if (at == null || widget.itemCount == 0) return;
    final i = ((pixels + widget.pinnedExtent - _listStart()) / widget.itemExtent)
        .floor()
        .clamp(0, widget.itemCount - 1);
    final l = at(i);
    if (l == _label) return;
    if (_label != null) HapticFeedback.selectionClick();
    setState(() => _label = l);
  }

  void _jump(double dy, double trackH) {
    final p = _pos;
    if (p == null || trackH <= _thumbH) return;
    final f = ((dy - _thumbH / 2) / (trackH - _thumbH)).clamp(0.0, 1.0);
    p.jumpTo(f * p.maxScrollExtent);
    _updateLabel(p.pixels);
  }

  @override
  Widget build(BuildContext context) {
    final list = NotificationListener<ScrollNotification>(onNotification: _onScroll, child: widget.child);
    if (!_enabled) return list;

    return Stack(
      children: [
        list,
        Positioned(
          top: widget.padding.top,
          bottom: widget.padding.bottom,
          right: 0,
          width: 40,
          child: IgnorePointer(
            ignoring: !_visible,
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: Motion.fast,
              child: LayoutBuilder(
                builder: (context, box) {
                  final trackH = box.maxHeight;
                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onVerticalDragStart: (d) {
                      _hide?.cancel();
                      setState(() => _dragging = true);
                      _jump(d.localPosition.dy, trackH);
                    },
                    onVerticalDragUpdate: (d) => _jump(d.localPosition.dy, trackH),
                    onVerticalDragEnd: (_) {
                      setState(() {
                        _dragging = false;
                        _label = null;
                      });
                      _scheduleHide();
                    },
                    child: ValueListenableBuilder<double>(
                      valueListenable: _frac,
                      builder: (context, f, _) {
                        final y = f * (trackH - _thumbH);
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              right: 6,
                              top: y,
                              child: AnimatedContainer(
                                duration: Motion.fast,
                                curve: Motion.standard,
                                width: _dragging ? 8 : 5,
                                height: _thumbH,
                                decoration: BoxDecoration(
                                  color: _dragging ? Nv.accent : Nv.text.withAlpha(105),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            if (_dragging && _label != null)
                              Positioned(
                                right: 30,
                                top: y + _thumbH / 2 - 27,
                                child: _Bubble(label: _label!),
                              ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      constraints: const BoxConstraints(minWidth: 54),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Nv.accent,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 6))],
      ),
      child: Text(label, style: disp(TS.h2, spacing: -0.5, color: Nv.onAccent)),
    );
  }
}

/// Bilah yang nempel di atas daftar (urutan / tab). Bening waktu diam,
/// jadi padat begitu ada isi daftar yang lewat di bawahnya.
class PinnedBarDelegate extends SliverPersistentHeaderDelegate {
  PinnedBarDelegate({required this.child, this.height = 54});

  final Widget child;
  final double height;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return AnimatedContainer(
      duration: Motion.fast,
      decoration: BoxDecoration(
        color: overlapsContent ? Nv.bg.withAlpha(245) : Nv.bg.withAlpha(0),
        border: Border(bottom: BorderSide(color: overlapsContent ? Nv.rule : Nv.rule.withAlpha(0))),
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(PinnedBarDelegate old) => true;
}

/// Penanda gelembung: huruf awal judul (A–Z), angka & simbol jadi "#".
String letterOf(String s) {
  final t = s.trim().replaceFirst(RegExp(r'^[^\p{L}\p{N}]+', unicode: true), '');
  if (t.isEmpty) return '#';
  final c = t.substring(0, 1).toUpperCase();
  return RegExp(r'\p{L}', unicode: true).hasMatch(c) ? c : '#';
}

const _bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

/// Penanda gelembung: bulan lagu masuk HP ("Nov 2026").
String monthOf(int epochSeconds) {
  if (epochSeconds <= 0) return '—';
  final d = DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000);
  return '${_bulan[d.month - 1]} ${d.year}';
}
