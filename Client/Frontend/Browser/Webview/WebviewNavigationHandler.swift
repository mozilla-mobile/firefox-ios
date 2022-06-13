// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

/// This is the place where we decide what to do with a new navigation action. There are a number of special schemes
/// and http(s) urls that need to be handled in a different way. All the logic for that is inside this delegate
/// method.

/// Note that this is a work in progress to remove navigation handler code from BrowserViewController+WebViewDelegates
struct WebviewNavigationHandler {

    enum Scheme: String {
        case data
    }

    /// Filter top-level data scheme
    /// https://blog.mozilla.org/security/2017/11/27/blocking-top-level-navigations-data-urls-firefox-59/
    static func filterDataScheme(url: URL,
                                 decidePolicyFor navigationAction: WKNavigationAction,
                                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        // Only filter top-level navigation, not on data URL subframes.
        // If target frame is nil, we filter as well.
        guard navigationAction.targetFrame?.isMainFrame ?? true else {
            decisionHandler(.allow)
            return
        }

        let url = url.absoluteString
        // Allow certain image types
        if url.hasPrefix("data:image/") && !url.hasPrefix("data:image/svg+xml") {
            decisionHandler(.allow)
            return
        }

        // Allow video, and certain application types
        if url.hasPrefix("data:video/") || url.hasPrefix("data:application/pdf") || url.hasPrefix("data:application/json") {
            decisionHandler(.allow)
            return
        }

        // Allow plain text types.
        // Note the format of data URLs is `data:[<media type>][;base64],<data>` with empty <media type> indicating plain text.
        if url.hasPrefix("data:;base64,")
            || url.hasPrefix("data:,")
            || url.hasPrefix("data:text/plain,")
            || url.hasPrefix("data:text/plain;") {
            decisionHandler(.allow)
            return
        }

        decisionHandler(.cancel)
    }
}
