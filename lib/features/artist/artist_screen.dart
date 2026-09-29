import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/account.dart';

import '../../innertube/models.dart';
import '../../providers.dart';
import '../../ui/theme/ytm_theme.dart';
import '../../ui/widgets/collection_header.dart';
import '../../ui/widgets/item_menu.dart';
import '../../ui/widgets/shelves.dart';
import '../../ui/widgets/states.dart';
import '../../ui/widgets/thumbnail.dart';

class ArtistScreen extends ConsumerWidget {
  const ArtistScreen({super.key, required this.browseId});

  final String browseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(artistProvider(browseId));
    return switch (page) {
      AsyncData(:final value) => _ArtistView(page: value),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(error: error, onRetry: () => ref.invalidate(artistProvider(browseId))),
      ),
      _ => Scaffold(appBar: AppBar(), body: const LoadingView()),
    };
  }
}

class _ArtistView extends ConsumerWidget {
  const _ArtistView({required this.page});

  final ArtistPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artist = page.artist;
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final subscribed = ref.watch(isSavedProvider(artist)).value ?? false;
    final actions = ref.read(playerActionsProvider);

    final topInset = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Full-bleed image that collapses into a solid bar; the name shrinks into the toolbar.
          SliverAppBar(
            pinned: true,
            expandedHeight: width - topInset,
            backgroundColor: YtmColors.background,
            actions: [
              IconButton(icon: const Icon(Icons.more_vert), onPressed: () => showItemMenu(context, ref, artist)),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              expandedTitleScale: 2.4,
              titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 14, end: 56),
              title: Text(
                artist.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  YtImage(thumbnails: artist.thumbnails, size: width, radius: 0, fallbackIcon: Icons.person),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0, 0.25, 0.6, 1],
                        colors: [
                          Colors.black45,
                          Colors.transparent,
                          YtmColors.background.withValues(alpha: 0.6),
                          YtmColors.background,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: YtmSizes.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          [
                            page.monthlyAudience ?? '',
                            if (page.subscriberCount != null) '${page.subscriberCount} subscribers',
                          ].where((s) => s.isNotEmpty).join(' • '),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          ref.read(accountActionsProvider).setSaved(artist, !subscribed, channelId: page.channelId);
                          showSnack(context, subscribed ? 'Unsubscribed' : 'Subscribed');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: subscribed ? YtmColors.textSecondary : YtmColors.textPrimary,
                          backgroundColor: subscribed ? Colors.transparent : const Color(0x1AFFFFFF),
                          side: BorderSide(color: subscribed ? const Color(0x33FFFFFF) : Colors.transparent),
                          shape: const StadiumBorder(),
                        ),
                        child: Text(subscribed ? 'Subscribed' : 'Subscribe'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (page.shuffleEndpoint != null)
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => actions.playEndpoint(page.shuffleEndpoint!, title: artist.title),
                            style: FilledButton.styleFrom(
                              backgroundColor: YtmColors.textPrimary,
                              foregroundColor: Colors.black,
                              shape: const StadiumBorder(),
                            ),
                            icon: const Icon(Icons.shuffle),
                            label: const Text('Shuffle'),
                          ),
                        ),
                      if (page.shuffleEndpoint != null && page.radioEndpoint != null) const SizedBox(width: 8),
                      if (page.radioEndpoint != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => actions.playEndpoint(page.radioEndpoint!, title: '${artist.title} Mix'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: YtmColors.textPrimary,
                              side: const BorderSide(color: Color(0x33FFFFFF)),
                              shape: const StadiumBorder(),
                            ),
                            icon: const Icon(Icons.sensors),
                            label: const Text('Mix'),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverList.builder(
            itemCount: page.sections.length,
            itemBuilder: (context, i) => SectionView(section: page.sections[i], listLimit: 5),
          ),
          if (page.description != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(YtmSizes.pagePadding, 24, YtmSizes.pagePadding, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('About', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 12),
                    ExpandableText(page.description!, maxLines: 4),
                  ],
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 140)),
        ],
      ),
    );
  }
}
