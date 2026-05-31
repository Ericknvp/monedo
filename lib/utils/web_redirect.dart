// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void redirectToLanding() {
  html.window.location.replace('/landing.html');
}

String? getViewParam() {
  return Uri.parse(html.window.location.href).queryParameters['view'];
}

void openExternalUrl(String url) {
  html.window.open(url, '_blank');
}
