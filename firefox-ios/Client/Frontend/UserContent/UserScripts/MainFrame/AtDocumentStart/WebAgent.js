// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

"use strict";

const ACTIONABLE = ["a", "button", "input", "textarea", "select"];
const INTERACTIVE_ROLES = ["button", "link", "checkbox", "tab", "menuitem", "switch", "radio"];

const documentReady = () => new Promise((resolve) => {
  if (document.readyState !== "loading") {
    resolve();
  } else {
    document.addEventListener("readystatechange", () => {
      if (document.readyState !== "loading") {
        resolve();
      }
    }, { once: true });
  }
});

const actionFor = (el) => {
  const tag = el.tagName.toLowerCase();
  const type = (el.getAttribute("type") || "").toLowerCase();
  if (tag === "select") return "select";
  if (tag === "textarea") return "type";
  if (tag === "input") {
    if (["button", "submit", "checkbox", "radio", "image", "reset"].includes(type)) return "click";
    return "type";
  }
  return "click";
};

const labelFor = (el) => {
  const text = (el.textContent || "").replace(/\s+/g, " ").trim();
  return (
    el.getAttribute("aria-label") ||
    el.getAttribute("placeholder") ||
    el.getAttribute("value") ||
    el.getAttribute("title") ||
    el.getAttribute("alt") ||
    (text.length > 0 && text.length <= 120 ? text : "") ||
    el.getAttribute("name") ||
    ""
  );
};

const visibilityOf = (el) => {
  const rect = el.getBoundingClientRect();
  if (rect.width === 0 || rect.height === 0) return { visible: false, reason: "zero-size" };

  const style = window.getComputedStyle(el);
  if (style.display === "none") return { visible: false, reason: "display:none" };
  if (style.visibility === "hidden") return { visible: false, reason: "visibility:hidden" };
  if (parseFloat(style.opacity) === 0) return { visible: false, reason: "opacity:0" };
  if (el.disabled) return { visible: false, reason: "disabled" };

  const vw = window.innerWidth, vh = window.innerHeight;
  const onScreen = rect.bottom > 0 && rect.right > 0 && rect.top < vh && rect.left < vw;

  const cx = rect.left + rect.width / 2;
  const cy = rect.top + rect.height / 2;
  let covered = false;
  if (onScreen && cx >= 0 && cy >= 0 && cx < vw && cy < vh) {
    const top = document.elementFromPoint(cx, cy);
    covered = !(top === el || el.contains(top) || (top && top.contains(el)));
  }

  return {
    visible: onScreen && !covered,
    inViewport: onScreen,
    covered: covered,
    rect: {
      x: Math.round(rect.left),
      y: Math.round(rect.top),
      w: Math.round(rect.width),
      h: Math.round(rect.height)
    }
  };
};

const selectorFor = (el) => {
  if (el.id) return "#" + el.id;
  const name = el.getAttribute("name");
  const tag = el.tagName.toLowerCase();
  if (name) return tag + '[name="' + name + '"]';
  return tag;
};

const nearbyContext = (el) => {
  const bits = [];
  if (el.id) {
    const lbl = document.querySelector('label[for="' + el.id + '"]');
    if (lbl) bits.push(lbl.textContent.trim());
  }
  const wrap = el.closest("label");
  if (wrap) bits.push(wrap.textContent.trim());
  const prev = el.previousElementSibling;
  if (prev && prev.textContent) bits.push(prev.textContent.trim());
  return [...new Set(bits)]
    .map((s) => s.replace(/\s+/g, " ").trim())
    .filter(Boolean)
    .join(" | ")
    .slice(0, 140);
};

const visibleText = () => {
  const SKIP = new Set(["SCRIPT", "STYLE", "NOSCRIPT", "NAV", "FOOTER", "HEADER"]);
  const out = [];
  const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, null);
  let node;
  while ((node = walker.nextNode())) {
    const t = node.nodeValue.replace(/\s+/g, " ").trim();
    if (t.length < 2) continue;
    const el = node.parentElement;
    if (!el || SKIP.has(el.tagName)) continue;
    const style = window.getComputedStyle(el);
    if (style.display === "none" || style.visibility === "hidden") continue;
    const rect = el.getBoundingClientRect();
    if (rect.bottom < 0 || rect.top > window.innerHeight || rect.height === 0) continue;
    out.push(t);
  }
  return out.join(" ").replace(/\s+/g, " ").trim().slice(0, 4000);
};

const buildMap = () => {
  const selector = ACTIONABLE
    .concat(INTERACTIVE_ROLES.map((r) => '[role="' + r + '"]'))
    .join(",");
  const nodes = Array.prototype.slice.call(document.querySelectorAll(selector));

  const elements = nodes.map((el, index) => {
    el.setAttribute("data-agent-id", String(index));
    const vis = visibilityOf(el);
    return {
      index: index,
      agentId: index,
      tag: el.tagName.toLowerCase(),
      role: el.getAttribute("role") || null,
      action: actionFor(el),
      label: labelFor(el),
      placeholder: el.getAttribute("placeholder") || null,
      ariaLabel: el.getAttribute("aria-label") || null,
      name: el.getAttribute("name") || null,
      id: el.id || null,
      selector: selectorFor(el),
      visible: vis.visible,
      inViewport: vis.inViewport || false,
      covered: vis.covered || false,
      rect: vis.rect || null,
      reason: vis.reason || null,
      context: nearbyContext(el)
    };
  });

  const visible = elements.filter((e) => e.visible);
  const scrollY = window.scrollY;
  const maxScroll = document.documentElement.scrollHeight - window.innerHeight;

  return {
    pageText: visibleText(),
    summary: {
      url: location.href,
      title: document.title || null,
      total: elements.length,
      visible: visible.length,
      typeable: visible.filter((e) => e.action === "type").length,
      clickable: visible.filter((e) => e.action === "click").length,
      selectable: visible.filter((e) => e.action === "select").length,
      scrollY: Math.round(scrollY),
      atTop: scrollY <= 2,
      atBottom: scrollY >= maxScroll - 2,
      belowFoldCount: elements.filter((e) => e.inViewport === false && !e.reason && e.label).length
    },
    elements: elements
  };
};

const extractPage = async () => {
  await documentReady();
  return buildMap();
};

const doAction = (id, type, text) => {
  if (type === "scroll") {
    const dir = text === "up" ? -1 : 1;
    window.scrollBy(0, dir * Math.round(window.innerHeight * 0.85));
    return "scrolled " + (text === "up" ? "up" : "down");
  }
  if (type === "navigate") {
    if (text) { window.location.href = text; return "navigating"; }
    return "navigate: no url";
  }
  const el = document.querySelector('[data-agent-id="' + id + '"]');
  if (!el) return "not-found";
  if (type === "click") {
    el.click();
    return "clicked";
  }
  if (type === "type") {
    el.focus();
    el.value = text || "";
    el.dispatchEvent(new Event("input", { bubbles: true }));
    el.dispatchEvent(new Event("change", { bubbles: true }));
    return "typed";
  }
  if (type === "typeSubmit") {
    el.focus();
    el.value = text || "";
    el.dispatchEvent(new Event("input", { bubbles: true }));
    el.dispatchEvent(new Event("change", { bubbles: true }));
    const opts = { bubbles: true, cancelable: true, key: "Enter", code: "Enter", keyCode: 13, which: 13 };
    el.dispatchEvent(new KeyboardEvent("keydown", opts));
    el.dispatchEvent(new KeyboardEvent("keypress", opts));
    el.dispatchEvent(new KeyboardEvent("keyup", opts));
    if (el.form && el.form.requestSubmit) { el.form.requestSubmit(); }
    return "typed+submit";
  }
  if (type === "select") {
    el.value = text || "";
    el.dispatchEvent(new Event("change", { bubbles: true }));
    return "selected";
  }
  return "unknown type: " + type;
};

Object.defineProperty(window.__firefox__, "WebAgent", {
  enumerable: false,
  configurable: false,
  writable: false,
  value: Object.freeze({ extractPage, doAction })
});
