import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../innertube/innertube.dart';
import '../../providers.dart';
import '../../ui/navigation.dart';
import '../../ui/theme/ytm_theme.dart';
import '../../ui/widgets/item_menu.dart';
import '../../ui/widgets/item_tiles.dart';
import '../../ui/widgets/states.dart';
import '../../ui/widgets/thumbnail.dart';
import '../home/home_screen.dart' show YtChip;

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String _input = '';
  String? _submitted;
  SearchFilter? _filter;

  @override
  void initState() {
    super.initState();
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    _controller.text = q;
    _focus.unfocus();
    ref.read(libraryProvider).addSearch(q);
    setState(() {
      _input = q;
      _submitted = q;
      _filter = null;
    });
  }

  void _fill(String query) {
    _controller.value = TextEditingValue(
      text: '$query ',
      selection: TextSelection.collapsed(offset: query.length + 1),
    );
    setState(() => _input = _controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final showResults = _submitted != null && !_focus.hasFocus;
    return PopScope(
      canPop: !showResults || _submitted == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _submitted = null);
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: TextField(
            controller: _controller,
            focusNode: _focus,
            textInputAction: TextInputAction.search,
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: const InputDecoration(hintText: 'Search songs, artists, albums'),
            onTap: () => setState(() {}),
            onChanged: (v) => setState(() => _input = v),
            onSubmitted: _submit,
          ),
          actions: [
            if (_input.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  _controller.clear();
                  _focus.requestFocus();
                  setState(() => _input = '');
                },
              ),
          ],
        ),
        body: showResults
            ? _Results(query: _submitted!, filter: _filter, onFilter: (f) => setState(() => _filter = f))
            : _Suggestions(input: _input, onSubmit: _submit, onFill: _fill),
      ),
    );
  }
}

class _Suggestions extends ConsumerWidget {
  const _Suggestions({required this.input, required this.onSubmit, required this.onFill});

  final String input;
  final ValueChanged<String> onSubmit;
  final ValueChanged<String> onFill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (input.trim().isEmpty) {
      final history = ref.watch(searchHistoryProvider).value ?? const [];
      return ListView(
        children: [
          for (final q in history)
            ListTile(
              leading: const Icon(Icons.history, color: YtmColors.textPrimary),
              title: Text(q),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => ref.read(libraryProvider).removeSearch(q),
              ),
              onTap: () => onSubmit(q),
            ),
        ],
      );
    }
    final suggestions = ref.watch(searchSuggestionsProvider(input)).value;
    if (suggestions == null) return const SizedBox.shrink();
    return ListView(
      children: [
        for (final q in suggestions.queries)
          ListTile(
            leading: const Icon(Icons.search, color: YtmColors.textPrimary),
            title: _Highlighted(text: q, input: input.trim()),
            trailing: IconButton(icon: const Icon(Icons.north_west, size: 20), onPressed: () => onFill(q)),
            onTap: () => onSubmit(q),
          ),
        if (suggestions.items.isNotEmpty) const Divider(),
        for (final item in suggestions.items) ResponsiveListTile(item: item),
      ],
    );
  }
}

/// Bolds the part the user hasn't typed yet, as YouTube Music does.
class _Highlighted extends StatelessWidget {
  const _Highlighted({required this.text, required this.input});

  final String text;
  final String input;

  @override
  Widget build(BuildContext context) {
    final lower = text.toLowerCase();
    final prefix = lower.startsWith(input.toLowerCase()) ? input.length : 0;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: text.substring(0, prefix),
            style: const TextStyle(color: YtmColors.textSecondary),
          ),
          TextSpan(
            text: text.substring(prefix),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.query, required this.filter, required this.onFilter});

  final String query;
  final SearchFilter? filter;
  final ValueChanged<SearchFilter?> onFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (query: query, filter: filter);
    final results = ref.watch(searchResultsProvider(key));
    return Column(
      children: [
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(YtmSizes.pagePadding, 6, YtmSizes.pagePadding, 10),
            children: [
              for (final f in SearchFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: YtChip(label: f.label, selected: f == filter, onTap: () => onFilter(f == filter ? null : f)),
                ),
            ],
          ),
        ),
        Expanded(
          child: switch (results) {
            AsyncData(:final value) when value.value.items.isEmpty && value.value.topResult == null => EmptyView(
              icon: Icons.search_off,
              title: 'No results for "$query"',
            ),
            AsyncData(:final value) => NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.extentAfter < 500) ref.read(searchResultsProvider(key).notifier).loadMore();
                return false;
              },
              child: ListView(
                padding: const EdgeInsets.only(bottom: 120),
                children: [
                  if (value.value.topResult != null)
                    _TopResultCard(item: value.value.topResult!, songs: value.value.topResultItems),
                  for (final item in value.value.items) ResponsiveListTile(item: item),
                  if (value.loadingMore) const Padding(padding: EdgeInsets.all(16), child: LoadingView()),
                ],
              ),
            ),
            AsyncError(:final error) => ErrorView(
              error: error,
              onRetry: () => ref.invalidate(searchResultsProvider(key)),
            ),
            _ => const LoadingView(),
          },
        ),
      ],
    );
  }
}

/// The large "Top result" card with its action buttons and a few songs.
class _TopResultCard extends ConsumerWidget {
  const _TopResultCard({required this.item, required this.songs});

  final YTItem item;
  final List<YTItem> songs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final actions = ref.read(playerActionsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(YtmSizes.pagePadding, 4, YtmSizes.pagePadding, 12),
      child: Material(
        color: YtmColors.surface,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            InkWell(
              onTap: () => openItem(context, ref, item),
              onLongPress: () => showItemMenu(context, ref, item),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    YtImage(thumbnails: item.thumbnails, size: 72, circle: item is ArtistItem),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: theme.textTheme.titleLarge, maxLines: 2),
                          const SizedBox(height: 4),
                          Text(item.subtitle, style: theme.textTheme.bodyMedium, maxLines: 1),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: YtmColors.textPrimary,
                        foregroundColor: Colors.black,
                        shape: const StadiumBorder(),
                      ),
                      icon: Icon(item is ArtistItem ? Icons.shuffle : Icons.play_arrow),
                      label: Text(item is ArtistItem ? 'Shuffle' : 'Play'),
                      onPressed: () async {
                        switch (item) {
                          case ArtistItem():
                            final page = await ref.read(artistProvider(item.id).future);
                            if (page.shuffleEndpoint != null) {
                              await actions.playEndpoint(page.shuffleEndpoint!, title: item.title);
                            }
                          case AlbumItem(:final browseId):
                            final page = await ref.read(albumProvider(browseId).future);
                            await actions.playList(page.songs, title: item.title);
                          case _:
                            if (context.mounted) openItem(context, ref, item);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: YtmColors.textPrimary,
                        side: const BorderSide(color: Color(0x33FFFFFF)),
                        shape: const StadiumBorder(),
                      ),
                      icon: const Icon(Icons.sensors),
                      label: Text(item is SongItem ? 'Radio' : 'Mix'),
                      onPressed: () async {
                        switch (item) {
                          case SongItem song:
                            await actions.startRadio(song);
                          case ArtistItem():
                            final page = await ref.read(artistProvider(item.id).future);
                            if (page.radioEndpoint != null) {
                              await actions.playEndpoint(page.radioEndpoint!, title: '${item.title} Mix');
                            }
                          case AlbumItem(:final playlistId?):
                            await actions.playEndpoint(WatchEndpoint(playlistId: 'RDAMPL$playlistId'));
                          case PlaylistItem(:final id):
                            await actions.playEndpoint(WatchEndpoint(playlistId: 'RDAMPL$id'));
                          case _:
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            for (final song in songs) ResponsiveListTile(item: song),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
