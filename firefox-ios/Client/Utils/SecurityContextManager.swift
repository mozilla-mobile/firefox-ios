// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct SecurityContextManager {
    /// Determines if a frame is loaded in a secure context.
    /// A frame is considered secure only when BOTH the top-level webView
    /// and the frame itself are loaded via HTTPS. This prevents
    /// autofill/sensitive features from operating in mixed content scenarios.
    /// `hasOnlySecureContent` is deliberately not used here
    /// since it will return false if any external resource on the page is loaded via
    /// an insecure connection (i.e styles, images, ...), which might be too strict for most applications.
    /// - Parameters:
    ///   - webViewURL: The URL of the top-level WKWebView
    ///   - frameURL: The URL of the specific frame
    /// - Returns: True if both URLs use HTTPS, false otherwise
  static func isSecureContext(webViewURL: URL?, frameScheme: String?) -> Bool {
      return webViewURL?.scheme == "https" && frameScheme == "https"
  }
}
