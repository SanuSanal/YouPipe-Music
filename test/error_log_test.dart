import 'package:flutter_test/flutter_test.dart';
import 'package:youpipe_music/data/error_log.dart';

ErrorEntry _entry(int n, {String? detail}) =>
    ErrorEntry(time: DateTime(2026, 9, 30, 19, 0, n), source: 'player', message: 'Source error $n', detail: detail);

void main() {
  test('prefills a GitHub issue with the version, device and errors', () {
    final url = githubIssueUrl(
      repo: 'owner/repo',
      entries: [_entry(1, detail: 'abc · Song')],
      appVersion: '1.0.0 (5)',
      device: 'motorola edge 20, Android 13 (SDK 33)',
    );
    expect(url.host, 'github.com');
    expect(url.path, '/owner/repo/issues/new');
    expect(url.queryParameters['title'], 'Error: Source error 1');
    final body = url.queryParameters['body']!;
    expect(body, contains('**App:** 1.0.0 (5)'));
    expect(body, contains('**Device:** motorola edge 20, Android 13 (SDK 33)'));
    expect(body, contains('[player] Source error 1\nabc · Song'));
    expect(body, isNot(contains('more not included')));
  });

  test('leaves out entries that would make the link too long, and says so', () {
    final entries = [for (var i = 0; i < 200; i++) _entry(i, detail: 'x' * 100)];
    final url = githubIssueUrl(repo: 'owner/repo', entries: entries, appVersion: '1.0.0');
    expect(url.toString().length, lessThanOrEqualTo(6000));
    expect(url.queryParameters['title'], 'Error report (200 errors)');
    final body = url.queryParameters['body']!;
    expect(body, contains('Source error 0'));
    expect(RegExp(r'(\d+) more not included').firstMatch(body), isNotNull);
  });

  test('keeps at least the newest message when one entry alone is too long', () {
    final url = githubIssueUrl(
      repo: 'owner/repo',
      entries: [_entry(1, detail: 'y' * 20000)],
      appVersion: '1.0.0',
    );
    final body = url.queryParameters['body']!;
    expect(body, contains('Source error 1'));
    expect(body, isNot(contains('yyyy')));
  });
}
