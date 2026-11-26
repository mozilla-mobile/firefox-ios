// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// Only injected while the VPN proxy is on. Hides APIs that connect directly from the device and
// blocks cross-site WebAuthn related origin requests, since both would reveal the real IP.
// Touching an API the browser supports is reported to ProxyLeakGuardHelper.
// For more context, See https://docs.google.com/document/d/1oiTzWFyga97VnNnCED5AdYavJnBr7RtsNauysbVcfO4
const handler = window.webkit?.messageHandlers?.proxyLeakGuard;
const post = handler?.postMessage.bind(handler);
const report = (api, kind) => {
  try { post?.({ api, kind, token: APP_ID_TOKEN }); } catch (e) {}
};

["RTCPeerConnection", "webkitRTCPeerConnection"].forEach(name => {
  if (!(name in window)) return;
  let reported = false;
  const get = () => {
    if (!reported) {
      reported = true;
      report("DirectConnection", name);
    }
  };
  try { Object.defineProperty(window, name, { get, set() {}, configurable: false }); } catch (e) {}
});

// Page scripts run after us and may try to make WebKit see a different RP ID than the one we check:
//   - getters, Proxies or toString() returning a different value on each read
//   - rpId inherited from a polluted Object.prototype
//   - patched Function.prototype.apply / String.prototype.endsWith
//     (a patched apply would also receive `original`)
// So: built-ins are captured before any page script, options are copied into prototype-less
// objects, rpId is read exactly once, and WebKit only ever sees the copy.
const reflectApply = Reflect.apply;
const endsWith = String.prototype.endsWith;
const toStr = String;
const snapshotRpId = value => (value === undefined ? undefined : toStr(value));
const isObject = value => value !== null && typeof value === "object";

const credentialsProto = window.CredentialsContainer?.prototype;
["get", "create"].forEach(method => {
  const original = credentialsProto?.[method];
  if (!original) return;
  credentialsProto[method] = function (options) {
    if (!isObject(options)) return reflectApply(original, this, [options]);
    const snapshot = { __proto__: null, ...options };
    if (!isObject(snapshot.publicKey)) return reflectApply(original, this, [snapshot]);
    const publicKey = { __proto__: null, ...snapshot.publicKey };
    snapshot.publicKey = publicKey;

    let rpId;
    if (method === "get") {
      rpId = snapshotRpId(publicKey.rpId);
      publicKey.rpId = rpId;
    } else if (isObject(publicKey.rp)) {
      publicKey.rp = { __proto__: null, ...publicKey.rp };
      rpId = snapshotRpId(publicKey.rp.id);
      publicKey.rp.id = rpId;
    }

    const host = location.hostname;
    if (rpId && host !== rpId && !reflectApply(endsWith, host, ["." + rpId])) {
      report("WebAuthnRelatedOrigin", method);
      return Promise.reject(new DOMException("Not allowed", "NotAllowedError"));
    }
    return reflectApply(original, this, [snapshot]);
  };
});
