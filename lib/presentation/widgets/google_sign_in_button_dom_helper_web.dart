// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Déclenche un clic sur le bouton Google natif (pour ouvrir la popup après feedback visuel Flutter).
void triggerGoogleButtonClick() {
  try {
    final el = html.document.querySelector('.g_id_signin');
    if (el != null) {
      el.click();
    }
  } catch (_) {}
}

/// Étend le bouton Google à 100%, le met au premier plan (z-index) et applique un style
/// proche de l'app (coins arrondis, bordure cyan) pour que le clic ouvre la popup.
/// Le bouton natif reste VISIBLE pour que le clic soit bien reçu.
void expandGoogleSignInButtonInDom() {
  try {
    const zTop = '2147483647';
    final elements = html.document.querySelectorAll('.g_id_signin');
    for (final el in elements) {
      if (el is html.HtmlElement) {
        el.style.width = '100%';
        el.style.height = '100%';
        el.style.display = 'block';
        el.style.pointerEvents = 'auto';
        el.style.position = 'absolute';
        el.style.top = '0';
        el.style.left = '0';
        el.style.cursor = 'pointer';
        el.style.zIndex = zTop;
        el.style.borderRadius = '14px';
        el.style.overflow = 'hidden';
        var parent = el.parent;
        var depth = 0;
        while (parent != null && parent is html.HtmlElement && depth < 6) {
          final p = parent;
          p.style
            ..width = '100%'
            ..height = '100%'
            ..boxSizing = 'border-box'
            ..pointerEvents = 'auto'
            ..position = 'relative'
            ..zIndex = zTop
            ..borderRadius = '14px'
            ..overflow = 'hidden';
          parent = p.parent;
          depth++;
        }
      }
    }
    final iframes = html.document.querySelectorAll(
      'iframe[src*="accounts.google.com"]',
    );
    for (final el in iframes) {
      if (el is html.HtmlElement) {
        el.style.width = '100%';
        el.style.height = '100%';
        el.style.pointerEvents = 'auto';
        el.style.cursor = 'pointer';
        el.style.zIndex = zTop;
        var parent = el.parent;
        var depth = 0;
        while (parent != null && parent is html.HtmlElement && depth < 6) {
          final p = parent;
          p.style
            ..width = '100%'
            ..height = '100%'
            ..pointerEvents = 'auto'
            ..zIndex = zTop;
          parent = p.parent;
          depth++;
        }
      }
    }
  } catch (_) {
    // Ignore si le DOM n'est pas encore prêt ou pas en web
  }
}
