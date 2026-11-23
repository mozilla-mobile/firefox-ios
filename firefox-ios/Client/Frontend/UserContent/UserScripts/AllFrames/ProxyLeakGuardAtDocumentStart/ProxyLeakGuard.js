// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// Only injected while the VPN proxy is on. Hides APIs that connect directly from the device and
// blocks cross-site WebAuthn related origin requests, since both would reveal the real IP.
// Touching an API the browser supports is reported to ProxyLeakGuardHelper.
// For more context, See https://docs.google.com/document/d/1oiTzWFyga97VnNnCED5AdYavJnBr7RtsNauysbVcfO4
const handler = window.webkit?.messageHandlers?.proxyLeakGuard;
const report = (api, kind) => {
  try { handler?.postMessage({ api, kind }); } catch (e) {}
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

const credentialsProto = window.CredentialsContainer?.prototype;
["get", "create"].forEach(method => {
  const original = credentialsProto?.[method];
  if (!original) return;
  credentialsProto[method] = function (options) {
    const rpId = method === "get" ? options?.publicKey?.rpId : options?.publicKey?.rp?.id;
    const host = location.hostname;
    if (rpId && host !== rpId && !host.endsWith("." + rpId)) {
      report("WebAuthnRelatedOrigin", method);
      return Promise.reject(new DOMException("Not allowed", "NotAllowedError"));
    }
    return original.apply(this, arguments);
  };
});
