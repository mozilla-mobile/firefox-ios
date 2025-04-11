// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

enum WKInternalPageSchemeHandlerError: Error {
    case badURL
    case noResponder
    case responderUnableToHandle
    case notAuthorized
}

protocol WKInternalSchemeResponse {
    func response(forRequest: URLRequest) -> (URLResponse, Data)?
}

public protocol SchemeHandler: WKURLSchemeHandler {
    var scheme: String { get }
}

/// Will load resources with URL schemes that WebKit doesn’t handle like homepage and error page.
public class WKInternalSchemeHandler: NSObject, SchemeHandler {
    public let scheme = "internal"

    override public init() {}

    static func response(forUrl url: URL) -> URLResponse {
        return URLResponse(url: url, mimeType: "text/html", expectedContentLength: -1, textEncodingName: "utf-8")
    }

    // Responders are looked up based on the path component, for instance
    // responder["about/home"] is used for 'internal://local/about/home'
    static var responders = [String: WKInternalSchemeResponse]()

    public func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else {
            urlSchemeTask.didFailWithError(WKInternalPageSchemeHandlerError.badURL)
            return
        }

        let path = url.path.starts(with: "/") ? String(url.path.dropFirst()) : url.path

        //  If this is not a homepage or error page
        if !urlSchemeTask.request.isPrivileged {
            urlSchemeTask.didFailWithError(WKInternalPageSchemeHandlerError.notAuthorized)
            return
        }

        guard let responder = WKInternalSchemeHandler.responders[path] else {
            urlSchemeTask.didFailWithError(WKInternalPageSchemeHandlerError.noResponder)
            return
        }

        guard let (urlResponse, data) = responder.response(forRequest: urlSchemeTask.request) else {
            urlSchemeTask.didFailWithError(WKInternalPageSchemeHandlerError.responderUnableToHandle)
            return
        }

        urlSchemeTask.didReceive(urlResponse)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    public func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}
}
