import 'package:flutter/services.dart';

const privacyPolicyUrl =
    'https://github.com/gregorym/quotes_app/blob/main/PRIVACY.md';
const termsOfUseUrl =
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
const supportUrl = 'https://github.com/gregorym/quotes_app/issues';

Future<bool> openExternalUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != 'https') return false;
  return await const MethodChannel('com.mars6.noexcuse/links')
          .invokeMethod<bool>('openURL', url) ??
      false;
}
