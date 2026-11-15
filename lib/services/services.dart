import 'cover_tint.dart';
import 'island_service.dart';
import 'library_service.dart';
import 'lyrics.dart';
import 'player_service.dart';
import 'playlist_service.dart';
import 'stats_service.dart';

export 'cover_tint.dart';
export 'island_service.dart';
export 'library_service.dart';
export 'player_service.dart';
export 'playlist_service.dart';
export 'stats_service.dart';
export 'song_edits.dart';
export 'transition.dart';

// Top-level final di Dart itu lazy: baru dibuat pas pertama dipakai,
// jadi aman karena init di main() jalan duluan.
final stats = StatsService();
final library = LibraryService();
final audio = PlayerService(stats);
final island = IslandService();
final playlists = PlaylistService();
final lyrics = LyricsService();
final coverTint = CoverTintService(audio);
