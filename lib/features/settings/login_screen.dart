import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../data/account.dart';
import '../../ui/theme/ytm_theme.dart';

/// Google's own sign-in page, landing on YouTube Music. The user types their credentials into
/// Google's page; the app only reads the resulting session cookie.
const _loginUrl =
    'https://accounts.google.com/ServiceLogin?ltmpl=music&service=youtube&uilel=3&passive=true'
    '&continue=https%3A%2F%2Fwww.youtube.com%2Fsignin%3Faction_handle_signin%3Dtrue%26app%3Ddesktop%26hl%3Den'
    '%26next%3Dhttps%253A%252F%252Fmusic.youtube.com%252F&hl=en';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(onProgress: (p) => setState(() => _progress = p), onPageFinished: _onPageFinished),
      )
      ..loadRequest(Uri.parse(_loginUrl));
  }

  Future<void> _onPageFinished(String url) async {
    if (_finishing || !url.startsWith('https://music.youtube.com')) return;
    _finishing = true;
    final ok = await ref.read(authProvider.notifier).completeSignIn();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      _finishing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in'),
        bottom: _progress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(value: _progress / 100, minHeight: 2, color: YtmColors.brandRed),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
