// ============================================================================
//  PEMUTAR NOVA DI TV — ISI APP ID DI SINI
//  Dari Google Cast SDK Developer Console > Applications > Custom Receiver.
//  Kosong = pakai pemutar bawaan Google ("Default Media Receiver").
// ============================================================================
const String novaReceiverAppId = '';

/// Pemutar bawaan Google (gak perlu daftar).
const String defaultReceiverAppId = 'CC1AD845';

String get castAppId => novaReceiverAppId.trim().isEmpty ? defaultReceiverAppId : novaReceiverAppId.trim();
