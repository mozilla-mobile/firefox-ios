// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

final class MockSchemeHandler: NSObject, WKURLSchemeHandler {
    private(set) var startedURLs: [URL] = []

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        if let url = urlSchemeTask.request.url {
            startedURLs.append(url)
        }

        guard let url = urlSchemeTask.request.url else { return }

        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "text/html"]
        )!

        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(Data()) // empty body
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) { }
}
