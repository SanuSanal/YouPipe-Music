import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/album/album_screen.dart';
import '../features/artist/artist_screen.dart';
import '../features/explore/browse_screen.dart';
import '../features/explore/explore_screen.dart';
import '../features/home/home_screen.dart';
import '../features/library/library_screen.dart';
import '../features/library/local_list_screens.dart';
import '../features/playlist/playlist_screen.dart';
import '../features/search/search_screen.dart';
import '../features/settings/login_screen.dart';
import '../features/settings/settings_screen.dart';
import '../innertube/models.dart';
import 'shell/app_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();

typedef BrowseArgs = ({BrowseEndpoint endpoint, String? title});

/// Pages that can be pushed inside any bottom-nav branch (keeps the nav bar and mini player visible).
List<RouteBase> _detailRoutes() => [
  GoRoute(path: 'search', builder: (_, _) => const SearchScreen()),
  GoRoute(
    path: 'album/:id',
    builder: (_, s) => AlbumScreen(browseId: s.pathParameters['id']!),
  ),
  GoRoute(
    path: 'artist/:id',
    builder: (_, s) => ArtistScreen(browseId: s.pathParameters['id']!),
  ),
  GoRoute(
    path: 'playlist/:id',
    builder: (_, s) => PlaylistScreen(playlistId: s.pathParameters['id']!),
  ),
  GoRoute(
    path: 'local/:id',
    builder: (_, s) => LocalPlaylistScreen(id: int.parse(s.pathParameters['id']!)),
  ),
  GoRoute(
    path: 'list/:kind',
    builder: (_, s) => LibraryListScreen(kind: s.pathParameters['kind']!),
  ),
  GoRoute(
    path: 'browse',
    builder: (_, s) {
      final args = s.extra! as BrowseArgs;
      return BrowseScreen(endpoint: args.endpoint, title: args.title);
    },
  ),
];

GoRouter buildRouter() => GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/home', builder: (_, _) => const HomeScreen(), routes: _detailRoutes())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/explore', builder: (_, _) => const ExploreScreen(), routes: _detailRoutes())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/library', builder: (_, _) => const LibraryScreen(), routes: _detailRoutes())],
        ),
      ],
    ),
    GoRoute(path: '/settings', parentNavigatorKey: _rootKey, builder: (_, _) => const SettingsScreen()),
    GoRoute(path: '/login', parentNavigatorKey: _rootKey, builder: (_, _) => const LoginScreen()),
  ],
);
