/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import GCDWebServers
import Shared

func generateResponseThatRedirects(toUrl url: URL) -> (URLResponse, Data) {
    let html = """
    <html><head><script>
    location.replace('\(url.absoluteString)');
    </script></head></html>
    """

    let data = html.data(using: .utf8)!
    let response = InternalSchemeHandler.response(forUrl: url)
    return (response, data)
}

/// Handles requests to /about/sessionrestore to restore session history.
class SessionRestoreHandler: InternalSchemeResponse {
    static let path = "sessionrestore"

    private func redirect(toUrl: URL) -> (URLResponse, Data)? {
        // Catch if the url argument is nested like `url=internal://local/sessionrestore?url=`; this can be removed once this code is stable.
        assert(!toUrl.absoluteString.starts(with: "\(InternalScheme.url)/\(SessionRestoreHandler.path)?url="))
        print("(SRH redirect)" + toUrl.absoluteString)
        return generateResponseThatRedirects(toUrl: toUrl)
    }

    func response(forRequest request: URLRequest) -> (URLResponse, Data)? {
        guard let url = request.url else { return nil }

        // Handle 'url=' query param
        if let query = url.query, query.starts(with: "url=") {
            let urlParam = String(query.dropFirst("url=".count))

            guard let url = URL(string: urlParam) else {
                assertionFailure()
                return nil
            }

            // These don't need to be privileged as they can only be pushed on the history stack by a privileged request, thus the back/forth history isn't hackable,
            // and a page directly loading a 'sessionrestore?url=<some url>' will just load <some url>.
            return redirect(toUrl: url)
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
