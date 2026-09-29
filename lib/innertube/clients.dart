/// InnerTube client identities.
///
/// Versions drift: when YouTube starts rejecting requests, refresh these from YouTube Music web
/// (`INNERTUBE_CLIENT_VERSION` in music.youtube.com page source) or from SimpMusic's
/// `YouTubeClient.kt`.
class YouTubeClient {
  const YouTubeClient({
    required this.clientName,
    required this.clientVersion,
    required this.clientId,
    required this.userAgent,
    this.origin,
  });

  final String clientName;
  final String clientVersion;

  /// Numeric id sent as `X-YouTube-Client-Name`.
  final int clientId;
  final String userAgent;
  final String? origin;

  Map<String, dynamic> context({required String hl, required String gl, String? visitorData}) => {
    'client': {
      'clientName': clientName,
      'clientVersion': clientVersion,
      'hl': hl,
      'gl': gl,
      'visitorData': ?visitorData,
    },
  };

  Map<String, String> headers({String? visitorData}) => {
    'User-Agent': userAgent,
    'X-YouTube-Client-Name': '$clientId',
    'X-YouTube-Client-Version': clientVersion,
    'Origin': ?origin,
    if (origin != null) 'Referer': '$origin/',
    'X-Goog-Visitor-Id': ?visitorData,
  };

  /// YouTube Music web. Used for every browse/search/next call.
  static const webRemix = YouTubeClient(
    clientName: 'WEB_REMIX',
    clientVersion: '1.20260304.03.00',
    clientId: 67,
    userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36',
    origin: 'https://music.youtube.com',
  );
}
