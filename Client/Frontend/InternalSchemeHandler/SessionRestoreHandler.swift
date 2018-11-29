/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import GCDWebServers
import Shared

func generateResponseThatRedirects(toUrl url: URL) -> (URLResponse, Data) {
    let startTags = "<!DOCTYPE html><html><head><script>"
    let endTags = "</script></head></html>"
    let html = startTags + "location.replace('\(url.absoluteString)');" + endTags

    let data = html.data(using: .utf8)!
    let response = InternalSchemeHandler.response(forUrl: url)
    return (response, data)
}

/// Handles requests to /about/sessionrestore to restore session history.
class SessionRestoreHandler: InternalSchemeResponse {
    static let path = "sessionrestore"

    func response(forRequest request: URLRequest) -> (URLResponse, Data)? {
        guard let url = request.url else { return nil }

        if let query = url.query, query.starts(with: "url=") {
            let urlParam = String(query.dropFirst("url=".count))

            // Handle 'url=' query param
            // These don't need to be privileged as they can only be pushed on the history stack by a privileged request,
            // and can only be loaded as a navigation type of backForward, see 'BrowserViewController.webView(decidePolicyFor:, navigationAction:)'.

            guard let nested = URL(string: urlParam), let secondaryUrl = InternalURL(nested) else {
                assertionFailure()
                return nil
            }

            if secondaryUrl.isErrorPage {
                if let original = secondaryUrl.originalURLFromErrorPage {
                    ErrorPageHelper.redirecting.append(original)
                }
                if let (res, data) = InternalSchemeHandler.responders[ErrorPageHandler.path]?.response(forRequest: URLRequest(url: nested)) {
                    return (InternalSchemeHandler.response(forUrl: url), data)
                }
            }

            return generateResponseThatRedirects(toUrl: url)
        }

        // From here on, handle 'history=' query param
        if !request.isPrivileged {
            assert(false, "History restore must be a privileged webView.load(request). (sessionrestore?url=... is not privileged however).")
            return nil
        }

        let response = InternalSchemeHandler.response(forUrl: url)
        guard let sessionRestorePath = Bundle.main.path(forResource: "SessionRestore", ofType: "html"), let html = try? String(contentsOfFile: sessionRestorePath), let data = html.data(using: .utf8) else {
            assert(false)
            return nil
        }

        return (response, data)
    }
}
