/// Plain data models produced by the InnerTube parsers.
library;

class Thumbnail {
  const Thumbnail({required this.url, this.width, this.height});

  final String url;
  final int? width;
  final int? height;

  /// YouTube Music art URLs end in `=w60-h60-...`; rewriting the size gives any resolution.
  String sized(int size) {
    final i = url.lastIndexOf('=w');
    if (i == -1 || !url.contains('googleusercontent.com')) return url;
    return '${url.substring(0, i)}=w$size-h$size-l90-rj';
  }
}

extension ThumbnailList on List<Thumbnail> {
  /// Best URL for a square image of roughly [size] logical pixels.
  String? best(int size) {
    if (isEmpty) return null;
    final largest = reduce((a, b) => (a.width ?? 0) >= (b.width ?? 0) ? a : b);
    // Local files and video thumbnails (i.ytimg.com) can't be resized through the URL.
    return largest.url.contains('googleusercontent.com') ? largest.sized(size) : largest.url;
  }
}

class BrowseEndpoint {
  const BrowseEndpoint(this.browseId, {this.params});

  final String browseId;
  final String? params;

  @override
  bool operator ==(Object other) => other is BrowseEndpoint && other.browseId == browseId && other.params == params;

  @override
  int get hashCode => Object.hash(browseId, params);
}

class WatchEndpoint {
  const WatchEndpoint({this.videoId, this.playlistId, this.params, this.index});

  final String? videoId;
  final String? playlistId;
  final String? params;
  final int? index;
}

class ArtistRef {
  const ArtistRef({required this.name, this.id});

  final String name;

  /// Channel browseId (`UC...`), null for plain-text artists.
  final String? id;
}

class AlbumRef {
  const AlbumRef({required this.name, required this.id});

  final String name;

  /// Album browseId (`MPREb_...`).
  final String id;
}

/// Anything YouTube Music can show as a card or row.
sealed class YTItem {
  const YTItem();

  String get id;
  String get title;
  List<Thumbnail> get thumbnails;

  /// Secondary line exactly as YouTube Music renders it, e.g. `Album • Coldplay • 2000`.
  String get subtitle;

  @override
  bool operator ==(Object other) => other.runtimeType == runtimeType && (other as YTItem).id == id;

  @override
  int get hashCode => Object.hash(runtimeType, id);
}

class SongItem extends YTItem {
  const SongItem({
    required this.videoId,
    required this.title,
    required this.artists,
    this.album,
    this.duration,
    this.thumbnails = const [],
    this.isVideo = false,
    this.explicit = false,
    this.subtitle = '',
    this.setVideoId,
  });

  final String videoId;
  @override
  final String title;
  final List<ArtistRef> artists;
  final AlbumRef? album;
  final Duration? duration;
  @override
  final List<Thumbnail> thumbnails;

  /// True for music videos (OMV/UGC) as opposed to audio-track songs (ATV).
  final bool isVideo;
  final bool explicit;
  @override
  final String subtitle;

  /// Position id inside a playlist/queue (`playlistSetVideoId`).
  final String? setVideoId;

  @override
  String get id => videoId;

  String get artistNames => artists.map((a) => a.name).join(', ');

  Thumbnail? get thumbnail => thumbnails.isEmpty ? null : thumbnails.last;

  SongItem copyWith({List<ArtistRef>? artists, AlbumRef? album, List<Thumbnail>? thumbnails}) => SongItem(
    videoId: videoId,
    title: title,
    artists: artists ?? this.artists,
    album: album ?? this.album,
    duration: duration,
    thumbnails: thumbnails ?? this.thumbnails,
    isVideo: isVideo,
    explicit: explicit,
    subtitle: subtitle,
    setVideoId: setVideoId,
  );
}

class AlbumItem extends YTItem {
  const AlbumItem({
    required this.browseId,
    required this.title,
    this.playlistId,
    this.artists = const [],
    this.year,
    this.thumbnails = const [],
    this.typeLabel,
    this.explicit = false,
    this.subtitle = '',
  });

  final String browseId;

  /// `OLAK5uy_...` playlist that plays the album.
  final String? playlistId;
  @override
  final String title;
  final List<ArtistRef> artists;
  final String? year;
  @override
  final List<Thumbnail> thumbnails;

  /// "Album", "Single" or "EP".
  final String? typeLabel;
  final bool explicit;
  @override
  final String subtitle;

  @override
  String get id => browseId;
}

class ArtistItem extends YTItem {
  const ArtistItem({required this.browseId, required this.title, this.thumbnails = const [], this.subtitle = ''});

  final String browseId;
  @override
  final String title;
  @override
  final List<Thumbnail> thumbnails;
  @override
  final String subtitle;

  @override
  String get id => browseId;
}

class PlaylistItem extends YTItem {
  const PlaylistItem({
    required this.id,
    required this.title,
    this.author,
    this.thumbnails = const [],
    this.subtitle = '',
    this.songCountText,
    this.isRadio = false,
  });

  /// Playlist id without the `VL` prefix (`PL...`, `RDCLAK...`, `OLAK...`, `RD...`).
  @override
  final String id;
  @override
  final String title;
  final ArtistRef? author;
  @override
  final List<Thumbnail> thumbnails;
  @override
  final String subtitle;
  final String? songCountText;

  /// Radio/mix entries play straight away (`watchPlaylistEndpoint`) instead of opening a page.
  final bool isRadio;

  String get browseId => 'VL$id';
}

/// A "Moods & genres" tile.
class MoodItem {
  const MoodItem({required this.title, required this.endpoint, this.color});

  final String title;
  final BrowseEndpoint endpoint;

  /// ARGB stripe color.
  final int? color;
}

class HomeChip {
  const HomeChip({required this.title, required this.endpoint, this.deselectEndpoint, this.selected = false});

  final String title;
  final BrowseEndpoint endpoint;
  final BrowseEndpoint? deselectEndpoint;
  final bool selected;
}

/// A titled row of items (carousel, list shelf or grid).
class Section {
  const Section({
    required this.title,
    required this.items,
    this.strapline,
    this.thumbnails = const [],
    this.moreEndpoint,
    this.itemsPerColumn,
    this.moods = const [],
  });

  final String title;
  final String? strapline;

  /// Avatar next to the title (e.g. "More from" an artist).
  final List<Thumbnail> thumbnails;
  final List<YTItem> items;
  final BrowseEndpoint? moreEndpoint;

  /// Set for "Quick picks"-style shelves that lay songs out in columns of N rows.
  final int? itemsPerColumn;
  final List<MoodItem> moods;
}

class HomePage {
  const HomePage({required this.chips, required this.sections, this.continuation});

  final List<HomeChip> chips;
  final List<Section> sections;
  final String? continuation;
}

class SectionsPage {
  const SectionsPage({required this.sections, this.continuation, this.title});

  final String? title;
  final List<Section> sections;
  final String? continuation;
}

class SearchPage {
  const SearchPage({required this.items, this.topResult, this.topResultItems = const [], this.continuation});

  final YTItem? topResult;

  /// Songs shown inside the top-result card.
  final List<YTItem> topResultItems;
  final List<YTItem> items;
  final String? continuation;
}

class SearchSuggestions {
  const SearchSuggestions({required this.queries, required this.items});

  final List<String> queries;
  final List<YTItem> items;
}

class AlbumPage {
  const AlbumPage({
    required this.album,
    required this.songs,
    this.description,
    this.secondSubtitle,
    this.otherSections = const [],
  });

  final AlbumItem album;
  final List<SongItem> songs;
  final String? description;

  /// e.g. `12 songs • 47 minutes`.
  final String? secondSubtitle;
  final List<Section> otherSections;
}

class ArtistPage {
  const ArtistPage({
    required this.artist,
    required this.sections,
    this.description,
    this.subscriberCount,
    this.channelId,
    this.monthlyAudience,
    this.shuffleEndpoint,
    this.radioEndpoint,
  });

  final ArtistItem artist;
  final List<Section> sections;
  final String? description;
  final String? subscriberCount;

  /// Channel id to (un)subscribe (may differ from the artist browseId).
  final String? channelId;
  final String? monthlyAudience;
  final WatchEndpoint? shuffleEndpoint;
  final WatchEndpoint? radioEndpoint;
}

class PlaylistPage {
  const PlaylistPage({
    required this.playlist,
    required this.songs,
    this.description,
    this.secondSubtitle,
    this.continuation,
  });

  final PlaylistItem playlist;
  final List<SongItem> songs;
  final String? description;
  final String? secondSubtitle;

  /// Loads more songs (or, once songs are exhausted, related sections).
  final String? continuation;
}

class PlaylistContinuation {
  const PlaylistContinuation({required this.songs, this.sections = const [], this.continuation});

  final List<SongItem> songs;
  final List<Section> sections;
  final String? continuation;
}

class NextPage {
  const NextPage({required this.items, this.playlistId, this.continuation, this.lyricsEndpoint, this.relatedEndpoint});

  final List<SongItem> items;
  final String? playlistId;
  final String? continuation;
  final BrowseEndpoint? lyricsEndpoint;
  final BrowseEndpoint? relatedEndpoint;
}

class Lyrics {
  const Lyrics({required this.text, this.source});

  final String text;
  final String? source;
}

class AccountInfo {
  const AccountInfo({required this.name, this.email, this.handle, this.photos = const []});

  final String name;
  final String? email;
  final String? handle;
  final List<Thumbnail> photos;
}

/// The signed-in library views (same browse ids as YouTube Music web).
enum LibraryPage {
  playlists('FEmusic_liked_playlists'),
  songs('FEmusic_liked_videos'),
  albums('FEmusic_liked_albums'),
  artists('FEmusic_library_corpus_track_artists'),
  subscriptions('FEmusic_library_corpus_artists');

  const LibraryPage(this.browseId);
  final String browseId;
}

class ExplorePage {
  const ExplorePage({required this.shortcuts, required this.sections});

  /// "New releases", "Charts", "Moods & genres" buttons.
  final List<MoodItem> shortcuts;
  final List<Section> sections;
}
