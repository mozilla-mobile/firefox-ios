(function () {
  'use strict';

  const themes = {};
  const requested = window.__FOX_DASH_THEME__ || new URLSearchParams(location.search).get('theme') || 'normal';
  const id = /^[a-z0-9_-]+$/.test(requested) ? requested : 'normal';

  window.FoxDashThemes = {
    id,
    register(themeId, definition) { themes[themeId] = definition; },
    current() { return themes[id] || themes.normal; },
  };

  document.write('<script src="themes/normal/theme.js"><\/script>');
  if (id !== 'normal') {
    document.write(`<link rel="stylesheet" href="themes/${id}/theme.css">`);
    document.write(`<script src="themes/${id}/theme.js"><\/script>`);
  }
})();
