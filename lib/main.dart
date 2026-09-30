import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/db/app_database.dart';
import 'data/stream_resolver.dart';
import 'innertube/innertube.dart';
import 'player/audio_handler.dart';
import 'providers.dart';
import 'ui/router.dart';
import 'ui/theme/ytm_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final prefs = await SharedPreferences.getInstance();
  final innerTube = InnerTube(visitorData: prefs.getString('visitorData'));
  final resolver = StreamResolver();
  final audioHandler = await AudioService.init<YouPipeAudioHandler>(
    builder: () => YouPipeAudioHandler(resolver),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.youpipe.music.playback',
      androidNotificationChannelName: 'Playback',
      androidNotificationIcon: 'drawable/ic_stat_youpipe',
      androidNotificationOngoing: true,
      androidBrowsableRootExtras: {
        AndroidContentStyle.supportedKey: true,
        AndroidContentStyle.browsableHintKey: AndroidContentStyle.listItemHintValue,
        AndroidContentStyle.playableHintKey: AndroidContentStyle.listItemHintValue,
      },
    ),
  );

  // Keep the anonymous session stable across launches.
  innerTube.ensureVisitorData().then((v) {
    if (v != null) prefs.setString('visitorData', v);
  }, onError: (_) {});

  runApp(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        innerTubeProvider.overrideWithValue(innerTube),
        streamResolverProvider.overrideWithValue(resolver),
        audioHandlerProvider.overrideWithValue(audioHandler),
        databaseProvider.overrideWithValue(AppDatabase()),
      ],
      child: const YouPipeApp(),
    ),
  );
}

class YouPipeApp extends ConsumerStatefulWidget {
  const YouPipeApp({super.key});

  @override
  ConsumerState<YouPipeApp> createState() => _YouPipeAppState();
}

class _YouPipeAppState extends ConsumerState<YouPipeApp> {
  final _router = buildRouter();

  @override
  void initState() {
    super.initState();
    ref.read(downloadManagerProvider).resumePending();
  }

  @override
  Widget build(BuildContext context) {
    // Applies saved region/language/quality to the services on startup.
    ref.watch(settingsProvider);
    ref.watch(audioEffectsProvider);
    ref.watch(downloadManagerProvider);
    ref.watch(autoBrowserProvider);
    ref.watch(lockScreenLikeProvider);
    ref.watch(castControllerProvider);
    return MaterialApp.router(
      // Short name shown by the system (recents); in-app branding stays "YouPipe Music".
      title: 'YP Music',
      debugShowCheckedModeBanner: false,
      theme: buildYtmTheme(),
      darkTheme: buildYtmTheme(),
      themeMode: ThemeMode.dark,
      routerConfig: _router,
    );
  }
}
