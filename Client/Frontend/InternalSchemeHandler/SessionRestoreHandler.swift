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
        guard let _url = request.url, let url = InternalURL(_url) else { return nil }

        if let urlParam = url.extractedUrlParam {
            if let nestedInternalUrl = InternalURL(urlParam), nestedInternalUrl.isErrorPage,
                let original = nestedInternalUrl.originalURLFromErrorPage {
                ErrorPageHelper.redirecting.append(original)
                if let (response, data) = InternalSchemeHandler.responders[ErrorPageHandler.path]?.response(forRequest: URLRequest(url: nestedInternalUrl.url)) {
                    return (response, data)
                }
            }
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
