import 'package:url_launcher/url_launcher.dart';

void redirectToLanding() {}

String? getViewParam() => null;

String? getUrlParam(String key) => null;

void openExternalUrl(String url) {
  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
