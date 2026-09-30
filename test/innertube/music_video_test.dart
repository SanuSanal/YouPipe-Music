import 'package:flutter_test/flutter_test.dart';
import 'package:youpipe_music/innertube/models.dart';
import 'package:youpipe_music/innertube/music_video.dart';

SongItem song(String id, String title, List<String> artists, {bool video = false}) => SongItem(
  videoId: id,
  title: title,
  artists: [for (final a in artists) ArtistRef(name: a)],
  isVideo: video,
);

void main() {
  final zoo = song('atv', 'Zoo (From "Zootropolis 2")', ['Disney', 'Shakira']);

  test('picks the first video that matches the title and an artist', () {
    final pick = pickMusicVideo(zoo, [
      song('lyric', 'Zoo lyrics fan edit', ['Some Channel'], video: true),
      song('omv', 'Shakira - Zoo (Official Video)', ['Shakira'], video: true),
      song('live', 'Zoo (Live)', ['Shakira'], video: true),
    ]);
    expect(pick?.videoId, 'omv');
  });

  test('accepts the artist named in the video title', () {
    final pick = pickMusicVideo(song('a', 'Touch', ['KATSEYE']), [
      song('v', 'KATSEYE - Touch (Official MV)', ['HYBE LABELS'], video: true),
    ]);
    expect(pick?.videoId, 'v');
  });

  test('strips nested brackets from the song title', () {
    final waka = song(
      'atv',
      'Waka Waka (This Time for Africa) [The Official 2010 FIFA World Cup (TM) Song] (feat. Freshlyground)',
      ['Shakira'],
    );
    expect(
      pickMusicVideo(waka, [
        song('omv', 'Waka Waka', ['Shakira'], video: true),
      ])?.videoId,
      'omv',
    );
  });

  test('ignores songs and unrelated videos', () {
    expect(
      pickMusicVideo(zoo, [
        song('s', 'Zoo', ['Shakira']),
        song('x', 'Waka Waka', ['Shakira'], video: true),
      ]),
      isNull,
    );
  });
}
