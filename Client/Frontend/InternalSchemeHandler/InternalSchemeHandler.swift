// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import WebKit
import Shared

enum InternalPageSchemeHandlerError: Error {
    case badURL
    case noResponder
    case responderUnableToHandle
    case notAuthorized
}

protocol InternalSchemeResponse {
    func response(forRequest: URLRequest) -> (URLResponse, Data)?
}

class InternalSchemeHandler: NSObject, WKURLSchemeHandler {

    static func response(forUrl url: URL) -> URLResponse {
        return URLResponse(url: url, mimeType: "text/html", expectedContentLength: -1, textEncodingName: "utf-8")
    }

    // Responders are looked up based on the path component, for instance responder["about/license"] is used for 'internal://local/about/license'
    static var responders = [String: InternalSchemeResponse]()

    // Unprivileged internal:// urls might be internal resources in the app bundle ( i.e. <link href="errorpage-resource/NetError.css"> )
    func downloadResource(urlSchemeTask: WKURLSchemeTask) -> Bool {
        guard let url = urlSchemeTask.request.url else { return false }

        let allowedInternalResources = [
            "/errorpage-resource/NetError.css",
            "/errorpage-resource/CertError.css",
           // "/reader-mode/..."
        ]

        // Handle resources from internal pages. For example 'internal://local/errorpage-resource/CertError.css'.
        if allowedInternalResources.contains(where: { url.path == $0 }) {
            let path = url.lastPathComponent
            if let res = Bundle.main.path(forResource: path, ofType: nil), let str = try? String(contentsOfFile: res, encoding: .utf8), let data = str.data(using: .utf8) {
                urlSchemeTask.didReceive(URLResponse(url: url, mimeType: nil, expectedContentLength: -1, textEncodingName: nil))
                urlSchemeTask.didReceive(data)
                urlSchemeTask.didFinish()
                return true
            }
        }

        return false
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else {
            urlSchemeTask.didFailWithError(InternalPageSchemeHandlerError.badURL)
            return
        }

        let path = url.path.starts(with: "/") ? String(url.path.dropFirst()) : url.path

        // For non-main doc URL, try load it as a resource
        if !urlSchemeTask.request.isPrivileged, urlSchemeTask.request.mainDocumentURL != urlSchemeTask.request.url, downloadResource(urlSchemeTask: urlSchemeTask) {
            return
        }

        if !urlSchemeTask.request.isPrivileged {
            urlSchemeTask.didFailWithError(InternalPageSchemeHandlerError.notAuthorized)
            return
        }

        guard let responder = InternalSchemeHandler.responders[path] else {
            urlSchemeTask.didFailWithError(InternalPageSchemeHandlerError.noResponder)
            return
        }

        guard let (urlResponse, data) = responder.response(forRequest: urlSchemeTask.request) else {
            urlSchemeTask.didFailWithError(InternalPageSchemeHandlerError.responderUnableToHandle)
            return
        }

        urlSchemeTask.didReceive(urlResponse)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}
}
