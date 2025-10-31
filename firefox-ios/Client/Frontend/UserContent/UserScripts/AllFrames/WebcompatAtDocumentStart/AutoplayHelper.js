// // This Source Code Form is subject to the terms of the Mozilla Public
// // License, v. 2.0. If a copy of the MPL was not distributed with this
// // file, You can obtain one at http://mozilla.org/MPL/2.0/

// Ensure <video> elements play inline on iPhone.
// Required for muted autoplay to work when sites omit 'playsinline'.

if (/mobile/i.test(navigator.userAgent)) {
  const forceInline = (video) => {
    const inlineAttributes = ["playsinline", "webkit-playsinline"];
    inlineAttributes.forEach((attr) => {
      if (!video.hasAttribute(attr)) {
        video.setAttribute(attr, "");
      }
    });
  };

  // Apply to any <video> elements already parsed
  document.querySelectorAll("video").forEach(forceInline);

  // Monkey-patch document.createElement so future <video> elements also get playsinline
  const originalCreateElement = document.createElement;
  document.createElement = function (tag) {
    const el = originalCreateElement.call(this, tag);
    if (el.localName === "video") {
      forceInline(el);
    }
    return el;
  };

  // Observe dynamically inserted <video> elements
  const observer = new MutationObserver((muts) => {
    for (const m of muts) {
      for (const node of m.addedNodes) {
        if (node.nodeType !== 1) continue;
        if (node.localName === "video") {
          forceInline(node);
        }
        node.querySelectorAll?.("video").forEach(forceInline);
      }
    }
  });
  observer.observe(document, { childList: true, subtree: true });
}
