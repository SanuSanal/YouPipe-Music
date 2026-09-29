import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../innertube/models.dart';
import '../providers.dart';

/// Expanded/collapsed state of the player panel, so any screen can collapse it before navigating.
final playerPanelProvider = NotifierProvider<PlayerPanelController, bool>(PlayerPanelController.new);

class PlayerPanelController extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool expanded) => state = expanded;
  void expand() => state = true;
  void collapse() => state = false;
}

const _branches = ['home', 'explore', 'library'];

/// Detail pages are pushed inside the current bottom-nav branch (like YouTube Music),
/// so every branch has the same child routes under its own prefix.
String branchPrefix(BuildContext context) {
  final segments = GoRouter.of(context).routerDelegate.currentConfiguration.uri.pathSegments;
  final first = segments.firstOrNull;
  return '/${_branches.contains(first) ? first : 'home'}';
}

void _push(BuildContext context, WidgetRef ref, String path, {Object? extra}) {
  ref.read(playerPanelProvider.notifier).collapse();
  context.push('${branchPrefix(context)}$path', extra: extra);
}

void openAlbum(BuildContext context, WidgetRef ref, String browseId) => _push(context, ref, '/album/$browseId');

void openArtist(BuildContext context, WidgetRef ref, String browseId) => _push(context, ref, '/artist/$browseId');

void openPlaylist(BuildContext context, WidgetRef ref, String playlistId) =>
    _push(context, ref, '/playlist/$playlistId');

void openLocalPlaylist(BuildContext context, WidgetRef ref, int id) => _push(context, ref, '/local/$id');

void openBrowse(BuildContext context, WidgetRef ref, BrowseEndpoint endpoint, {String? title}) =>
    _push(context, ref, '/browse', extra: (endpoint: endpoint, title: title));

void openSearch(BuildContext context, WidgetRef ref) => _push(context, ref, '/search');

void openLibraryList(BuildContext context, WidgetRef ref, String kind) => _push(context, ref, '/list/$kind');

void openSettings(BuildContext context, WidgetRef ref) {
  ref.read(playerPanelProvider.notifier).collapse();
  context.push('/settings');
}

/// What tapping any card/row does.
void openItem(BuildContext context, WidgetRef ref, YTItem item) {
  switch (item) {
    case SongItem():
      ref.read(playerActionsProvider).playSong(item);
    case AlbumItem():
      openAlbum(context, ref, item.browseId);
    case ArtistItem():
      openArtist(context, ref, item.browseId);
    case PlaylistItem(isRadio: true):
      ref.read(playerActionsProvider).playEndpoint(WatchEndpoint(playlistId: item.id), title: item.title);
    case PlaylistItem():
      openPlaylist(context, ref, item.id);
  }
}
