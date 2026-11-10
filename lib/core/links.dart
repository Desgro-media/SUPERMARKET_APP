import 'package:url_launcher/url_launcher.dart';

/// Opens a web page, a phone number or an e-mail address in the matching app. Returns false when nothing can open it.
Future<bool> openLink(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

Uri phoneUri(String phone) => Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^+\d]'), ''));

Uri mailUri(String email) => Uri(scheme: 'mailto', path: email);
