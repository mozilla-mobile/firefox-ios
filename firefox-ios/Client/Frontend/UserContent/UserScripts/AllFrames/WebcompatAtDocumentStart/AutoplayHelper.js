// // This Source Code Form is subject to the terms of the Mozilla Public
// // License, v. 2.0. If a copy of the MPL was not distributed with this
// // file, You can obtain one at http://mozilla.org/MPL/2.0/

// Firefox iOS WebCompat patch: ensure <video> elements play inline on iPhone
// Required for muted autoplay to work when sites omit 'playsinline'.
// Safe on all platforms (no effect where playsinline is ignored).

console.log("[Webcompat] General console log");

if (/iPhone|iPod/i.test(navigator.userAgent)) {
  (() => {
    if (window.__fxInlineVideoPatchApplied) return;
    window.__fxInlineVideoPatchApplied = true;

    const forceInline = (video) => {
      if (!video) return;
      video.setAttribute("playsinline", "");
      video.setAttribute("webkit-playsinline", "");
    };
      
    console.log("[Webcompat] Inline video patch applied");

    // Apply to any <video> elements already in the DOM
    document.querySelectorAll("video").forEach(forceInline);

    // Watch for newly added videos
    const observer = new MutationObserver((muts) => {
      for (const m of muts) {
        for (const node of m.addedNodes) {
          if (node.nodeType !== 1) continue;
          if (node.localName === "video") forceInline(node);
          node.querySelectorAll?.("video").forEach(forceInline);
        }
      }
    });
    observer.observe(document, { childList: true, subtree: true });
  })();
}
