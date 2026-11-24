// ============================================================================
//  SPOTIFY — ISI CLIENT ID DI SINI
//  Ambil dari https://developer.spotify.com/dashboard → app kamu → Settings.
//  Client ID aman ditaruh di APK (pakai PKCE, gak ada client secret).
// ============================================================================
const String spotifyClientId = 'ISI_CLIENT_ID_SPOTIFY_DI_SINI';

/// Harus sama persis dengan Redirect URI di dashboard Spotify.
const String spotifyRedirectUri = 'nova://spotify-callback';
const String spotifyCallbackScheme = 'nova';

/// Cuma baca playlist, gak bisa ngubah apa pun di akun Spotify.
const List<String> spotifyScopes = ['playlist-read-private', 'playlist-read-collaborative'];

bool get spotifyConfigured => spotifyClientId.isNotEmpty && !spotifyClientId.startsWith('ISI_');
