import 'dart:io';

import 'package:multicast_dns/multicast_dns.dart';

import '../services/cast/cast_service.dart';

/// Cari Chromecast / Google TV di WiFi lewat mDNS (versi laptop; HP pakai NsdManager).
class DesktopCastScan {
  DesktopCastScan({required this.onFound});
  final void Function(CastDevice device) onFound;

  MDnsClient? _client;
  bool _stopped = false;
  final _seen = <String>{};

  Future<void> start() async {
    // Windows gak dukung reusePort: socket dibikin sendiri tanpa itu.
    final client = MDnsClient(
      rawDatagramSocketFactory: (dynamic host, int port, {bool reuseAddress = true, bool reusePort = false, int ttl = 1}) =>
          RawDatagramSocket.bind(host, port, reuseAddress: true, reusePort: false, ttl: ttl),
    );
    _client = client;
    try {
      await client.start();
      // Diulang beberapa kali: TV yang baru bangun kadang telat jawab.
      for (var round = 0; round < 3 && !_stopped; round++) {
        await for (final ptr in client.lookup<PtrResourceRecord>(
          ResourceRecordQuery.serverPointer('_googlecast._tcp.local'),
          timeout: const Duration(seconds: 4),
        )) {
          if (_stopped) break;
          if (!_seen.add(ptr.domainName)) continue;
          await _resolve(client, ptr.domainName);
        }
      }
    } catch (_) {
      // WiFi mati / socket ditolak firewall: daftar tetap kosong, UI nampilin petunjuk.
    }
  }

  Future<void> _resolve(MDnsClient client, String name) async {
    final txt = <String, String>{};
    await for (final t in client.lookup<TxtResourceRecord>(ResourceRecordQuery.text(name),
        timeout: const Duration(seconds: 2))) {
      for (final line in t.text.split('\n')) {
        final i = line.indexOf('=');
        if (i > 0) txt[line.substring(0, i)] = line.substring(i + 1);
      }
      break;
    }
    await for (final srv in client.lookup<SrvResourceRecord>(ResourceRecordQuery.service(name),
        timeout: const Duration(seconds: 2))) {
      await for (final ip in client.lookup<IPAddressResourceRecord>(ResourceRecordQuery.addressIPv4(srv.target),
          timeout: const Duration(seconds: 2))) {
        if (_stopped) return;
        onFound(CastDevice(
          id: txt['id'] ?? name,
          name: txt['fn'] ?? name.split('._googlecast').first,
          model: txt['md'] ?? '',
          host: ip.address.address,
          port: srv.port,
        ));
        return;
      }
      return;
    }
  }

  void stop() {
    _stopped = true;
    try {
      _client?.stop();
    } catch (_) {}
    _client = null;
  }
}
