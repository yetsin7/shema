/// Script JavaScript para personalizar la interfaz de YouTube en el WebView.
library;

/// Script JS que oculta la barra de navegación inferior de YouTube
/// manteniendo los menús y la funcionalidad intacta.
const youtubeCustomizationsJs = '''
(function() {
  const style = document.createElement('style');
  style.id = 'shema-custom-style';
  style.textContent = `
    /* Ocultar solo la barra de navegación inferior de YouTube */
    ytm-pivot-bar-renderer, ytm-mobile-bottom-bar-renderer {
      display: none !important;
      height: 0 !important;
      overflow: hidden !important;
    }
    body, html { overflow-x: hidden !important; }
  `;
  const oldStyle = document.getElementById('shema-custom-style');
  if (oldStyle) oldStyle.remove();
  document.head.appendChild(style);
})();
''';
