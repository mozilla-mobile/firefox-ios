// // This Source Code Form is subject to the terms of the Mozilla Public
// // License, v. 2.0. If a copy of the MPL was not distributed with this
// // file, You can obtain one at http://mozilla.org/MPL/2.0/

/// NOTE: This regex will match real google (sub)domains + some invalid ones.
/// Examples of valid matches: `google.com`, `www.google.com`, `google.co.uk`.
/// False positive like `google.something-weird` isn't a practical concern for our use case. 
/// It's fine to match that too.
const DOMAIN_PATTERN = /(\.|^)google\./;

/// NOTE: We only want to run this on Google search result pages.
/// There is no need to modify other pages.
if (DOMAIN_PATTERN.test(location.hostname)) {
  /// NOTE: CSS to hide specific popup elements on Google search result pages.
  /// This targets known popup structures as of the time of writing.
  /// Future changes to the markup may require updates to this CSS.
  /// This is a temporary workaround until a more robust solution is implemented.
  const css = `
  div[role="dialog"]:has(basic-promo-image),
  div[role="dialog"][jsname="XKSfm"],
  div[role="dialog"][aria-describedby="promo_desc_id"], 
  div[role="dialog"] div#stUuGf {
    display: none !important;
    visibility: hidden !important;
  }
  `;
  const style = document.createElement('style');
  style.textContent = css;
  document.documentElement.appendChild(style);
}