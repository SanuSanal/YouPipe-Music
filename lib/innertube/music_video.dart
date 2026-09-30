import 'models.dart';

/// Picks the music video for [song] from Videos search results: the first video whose title
/// contains the song's title and that shares an artist with it. Null when nothing matches well.
SongItem? pickMusicVideo(SongItem song, List<SongItem> candidates) {
  final title = _norm(_stripExtras(song.title));
  if (title.isEmpty) return null;
  final artists = {for (final a in song.artists) _norm(a.name)}..remove('');
  for (final v in candidates) {
    if (!v.isVideo) continue;
    final videoTitle = _norm(v.title);
    if (!videoTitle.contains(title)) continue;
    final videoArtists = {for (final a in v.artists) _norm(a.name)};
    final sharesArtist =
        artists.isEmpty ||
        videoArtists.any(artists.contains) ||
        artists.any((a) => a.isNotEmpty && videoTitle.contains(a));
    if (sharesArtist) return v;
  }
  return null;
}

/// "Zoo (From “Zootropolis 2”)" → "Zoo"; "Song [Remastered]" → "Song"; "Song - Live" stays.
/// Brackets are removed from the inside out, so nested ones ("[… (TM) …]") go too.
String _stripExtras(String s) {
  final group = RegExp(r'\s*(\([^()]*\)|\[[^\[\]]*\])');
  var text = s;
  while (true) {
    final next = text.replaceAll(group, '');
    if (next == text) return text.trim();
    text = next;
  }
}

String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ').trim();
