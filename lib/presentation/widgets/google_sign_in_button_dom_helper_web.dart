// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Étend le conteneur du bouton Google (classe g_id_signin) à 100% pour que toute la zone soit cliquable.
void expandGoogleSignInButtonInDom() {
  try {
    final elements = html.document.querySelectorAll('.g_id_signin');
    for (final el in elements) {
      if (el is html.HtmlElement) {
        el.style.width = '100%';
        el.style.height = '100%';
        el.style.display = 'block';
        var parent = el.parent;
        var depth = 0;
        while (parent != null && parent is html.HtmlElement && depth < 6) {
          final p = parent;
          p.style
            ..width = '100%'
            ..height = '100%'
            ..boxSizing = 'border-box';
          parent = p.parent;
          depth++;
        }
      }
    }
    // Aussi les iframes Google (fallback)
    final iframes = html.document.querySelectorAll('iframe[src*="accounts.google.com"]');
    for (final el in iframes) {
      if (el is html.HtmlElement) {
        el.style.width = '100%';
        el.style.height = '100%';
        var parent = el.parent;
        var depth = 0;
        while (parent != null && parent is html.HtmlElement && depth < 6) {
          final p = parent;
          p.style
            ..width = '100%'
            ..height = '100%';
          parent = p.parent;
          depth++;
        }
      }
    }
  } catch (_) {
    // Ignore si le DOM n'est pas encore prêt ou pas en web
  }
}
