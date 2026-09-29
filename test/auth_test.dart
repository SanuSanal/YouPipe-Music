import 'package:flutter_test/flutter_test.dart';
import 'package:youpipe_music/innertube/auth.dart';

void main() {
  const cookie = 'PREF=f6=40000000&tz=UTC; SID=abc==; SAPISID=abcDEF/xyz; __Secure-3PAPISID=abcDEF/xyz';

  test('parseCookies keeps values containing "="', () {
    final c = parseCookies(cookie);
    expect(c['SID'], 'abc==');
    expect(c['PREF'], 'f6=40000000&tz=UTC');
    expect(c['SAPISID'], 'abcDEF/xyz');
  });

  test('isSignedInCookie', () {
    expect(isSignedInCookie(cookie), isTrue);
    expect(isSignedInCookie('PREF=x; VISITOR_INFO1_LIVE=y'), isFalse);
    expect(isSignedInCookie(null), isFalse);
  });

  test('SAPISIDHASH matches sha1("<ts> <SAPISID> <origin>")', () {
    final header = sapisidHashHeader(cookie, now: DateTime.fromMillisecondsSinceEpoch(1790000000 * 1000));
    // Expected value computed independently with Python's hashlib.
    expect(header, 'SAPISIDHASH 1790000000_989cce601afbcac4e96519e0017befcf9385afe3');
  });
}
