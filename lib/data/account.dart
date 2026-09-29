import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../innertube/auth.dart';
import '../innertube/innertube.dart';
import '../providers.dart';

@immutable
class AuthState {
  const AuthState({this.signedIn = false, this.account});

  final bool signedIn;
  final AccountInfo? account;
}

const _cookieKey = 'ytm_cookie';
const _cookies = MethodChannel('youpipe/cookies');

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) => const FlutterSecureStorage());

/// Google sign-in state. The session cookie lives in encrypted storage and is handed to InnerTube.
final authProvider = AsyncNotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends AsyncNotifier<AuthState> {
  InnerTube get _yt => ref.read(innerTubeProvider);
  FlutterSecureStorage get _storage => ref.read(secureStorageProvider);

  @override
  Future<AuthState> build() async {
    final cookie = await _storage.read(key: _cookieKey);
    _yt.cookie = cookie;
    if (!_yt.signedIn) return const AuthState();
    try {
      return AuthState(signedIn: true, account: await _yt.accountInfo());
    } catch (e) {
      // Offline or YouTube hiccup: stay signed in, show the account later.
      debugPrint('YouPipe: account info failed: $e');
      return const AuthState(signedIn: true);
    }
  }

  /// Reads the WebView cookie jar after the login page lands on music.youtube.com.
  /// Returns false if the session isn't signed in yet.
  Future<bool> completeSignIn() async {
    final cookie = await _cookies.invokeMethod<String>('get', {'url': 'https://music.youtube.com'});
    if (cookie == null || !isSignedInCookie(cookie)) return false;
    await _storage.write(key: _cookieKey, value: cookie);
    _yt.cookie = cookie;
    final account = await _yt.accountInfo().catchError((Object _) => null);
    state = AsyncData(AuthState(signedIn: true, account: account));
    return true;
  }

  Future<void> signOut() async {
    await _storage.delete(key: _cookieKey);
    _yt.cookie = null;
    await _cookies.invokeMethod<bool>('clear');
    state = const AsyncData(AuthState());
  }
}

/// Keeps local library changes in sync with the YouTube Music account when signed in.
final accountActionsProvider = Provider<AccountActions>((ref) => AccountActions(ref));

class AccountActions {
  AccountActions(this._ref);

  final Ref _ref;

  bool get _signedIn => _ref.read(innerTubeProvider).signedIn;
  InnerTube get _yt => _ref.read(innerTubeProvider);

  /// Remote calls are best-effort: the local library is the source of truth for the UI.
  Future<void> _remote(Future<void> Function() call) async {
    if (!_signedIn) return;
    try {
      await call();
    } catch (e) {
      debugPrint('YouPipe: account sync failed: $e');
    }
  }

  Future<void> setLiked(SongItem song, bool liked) async {
    await _ref.read(libraryProvider).setLiked(song, liked);
    await _remote(() => liked ? _yt.like(song.videoId) : _yt.removeLike(song.videoId));
  }

  Future<void> setSaved(YTItem item, bool saved, {String? channelId}) async {
    await _ref.read(libraryProvider).setSaved(item, saved);
    await _remote(() async {
      switch (item) {
        case SongItem():
          await (saved ? _yt.like(item.videoId) : _yt.removeLike(item.videoId));
        case AlbumItem(:final playlistId?):
          await _yt.savePlaylist(playlistId, save: saved);
        case AlbumItem():
          break;
        case PlaylistItem():
          await _yt.savePlaylist(item.id, save: saved);
        case ArtistItem():
          await _yt.subscribe(channelId ?? item.browseId, subscribe: saved);
      }
    });
  }
}

/// The signed-in account's library (empty when signed out).
final accountLibraryProvider = FutureProvider.autoDispose.family<List<YTItem>, LibraryPage>((ref, page) async {
  final auth = await ref.watch(authProvider.future);
  if (!auth.signedIn) return const [];
  final result = await ref.watch(innerTubeProvider).library(page);
  return result.sections.expand((s) => s.items).toList();
});
