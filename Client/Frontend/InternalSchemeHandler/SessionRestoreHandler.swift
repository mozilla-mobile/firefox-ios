/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import GCDWebServers
import Shared

private let apostropheEncoded = "%27"

extension WKWebView {
    // Use JS to redirect the page without adding a history entry
    func replaceLocation(with url: URL) {
        let safeUrl = url.absoluteString.replacingOccurrences(of: "'", with: apostropheEncoded)
        evaluateJavascriptInDefaultContentWorld("location.replace('\(safeUrl)')")
    }
}

func generateResponseThatRedirects(toUrl url: URL) -> (URLResponse, Data) {
    var urlString: String
    if InternalURL.isValid(url: url), let authUrl = InternalURL.authorize(url: url) {
        urlString = authUrl.absoluteString
    } else {
        urlString = url.absoluteString
    }

    urlString = urlString.replacingOccurrences(of: "'", with: apostropheEncoded)
    
    let startTags = "<!DOCTYPE html><html><head><script>"
    let endTags = "</script></head></html>"
    let html = startTags + "location.replace('\(urlString)');" + endTags

    let data = html.data(using: .utf8)!
    let response = InternalSchemeHandler.response(forUrl: url)
    return (response, data)
}

/// Handles requests to /about/sessionrestore to restore session history.
class SessionRestoreHandler: InternalSchemeResponse {
    static let path = "sessionrestore"

    func response(forRequest request: URLRequest) -> (URLResponse, Data)? {
        guard let _url = request.url, let url = InternalURL(_url) else { return nil }

        // Handle the 'url='query param
        if let urlParam = url.extractedUrlParam {
            return generateResponseThatRedirects(toUrl: urlParam)
        }

        // From here on, handle 'history=' query param
        let response = InternalSchemeHandler.response(forUrl: url.url)
        guard let sessionRestorePath = Bundle.main.path(forResource: "SessionRestore", ofType: "html"), let html = try? String(contentsOfFile: sessionRestorePath).replacingOccurrences(of: "%INSERT_UUID_VALUE%", with: InternalURL.uuid), let data = html.data(using: .utf8) else {
            assert(false)
            return nil
        }

        return (response, data)
    }
}
