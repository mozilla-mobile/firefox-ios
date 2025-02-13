// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

class WKErrorPageHandler: WKInternalSchemeResponse {
    static let path = WKInternalURL.Path.errorpage.rawValue

    func response(forRequest request: URLRequest) -> (URLResponse, Data)? {
        guard let url = request.url else { return nil }
        let response = WKInternalSchemeHandler.response(forUrl: url)
        // Blank page with a color matching the background of the panels which
        // is displayed for a split-second until the panel shows.
        let html = """
            <!DOCTYPE html>
            <html>
              <body></body>
            </html>
        """
        guard let data = html.data(using: .utf8) else { return nil }
        return (response, data)
    }
}
