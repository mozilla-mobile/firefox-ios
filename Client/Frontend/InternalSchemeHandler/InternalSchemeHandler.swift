/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit
import Shared

enum InternalPageSchemeHandlerError: Error {
    case badURL
    case noResponder
    case responderUnableToHandle
}

protocol InternalSchemeResponse {
    func response(forRequest: URLRequest) -> (URLResponse, Data)?
}

private var downloadTasks = WeakList<WKURLSchemeTask>()

class InternalSchemeHandler: NSObject, WKURLSchemeHandler {

    static func response(forUrl url: URL) -> URLResponse {
        return URLResponse(url: url, mimeType: "text/html", expectedContentLength: -1, textEncodingName: "utf-8")
    }

    // Responders are looked up based on the path component, for instance responder["about/license"] is used for 'internal://local/about/license'
    static var responders = [String: InternalSchemeResponse]()

    // Unprivileged internal:// urls are probably resources on the page. Change to https:// and try download them.
    func downloadResource(urlSchemeTask: WKURLSchemeTask) -> Bool {
        guard let https = urlSchemeTask.request.url?.absoluteString.replacingOccurrences(of: "internal://", with: "https://"), let url = URL(string: https) else {
            return false
        }

        print(url)

        if url.absoluteString.contains("local/reader-mode/") {
            let path = url.lastPathComponent
            if let res = Bundle.main.path(forResource: path, ofType: nil), let str = try? String(contentsOfFile: res, encoding: .utf8), let data = str.data(using: .utf8) {
                urlSchemeTask.didReceive(URLResponse(url: url, mimeType: nil, expectedContentLength: -1, textEncodingName: nil))
                urlSchemeTask.didReceive(data)
                urlSchemeTask.didFinish()
                return true
            }
        }

        downloadTasks.insert(urlSchemeTask)
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                guard downloadTasks.remove(urlSchemeTask) != nil else {
                    return
                }
                guard let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                    let mimeType = response?.mimeType, let data = data
                    else {
                        urlSchemeTask.didFailWithError(InternalPageSchemeHandlerError.noResponder)
                        return
                }

                urlSchemeTask.didReceive(URLResponse(url: url, mimeType: mimeType, expectedContentLength: -1, textEncodingName: nil))
                urlSchemeTask.didReceive(data)
                urlSchemeTask.didFinish()
            }
        }
        task.resume()
        return true
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else {
            urlSchemeTask.didFailWithError(InternalPageSchemeHandlerError.badURL)
            return
        }

        let path = url.path.starts(with: "/") ? String(url.path.dropFirst()) : url.path
        print("(ISH) [\(path)]  [\(url.absoluteString)]")

        // History urls are unprivileged, but other unprivileged urls are treated as page resources and downloaded
        let historyUrlParam = "sessionrestore?url="
        if !urlSchemeTask.request.isPrivileged, !url.path.contains(historyUrlParam),
            urlSchemeTask.request.mainDocumentURL != urlSchemeTask.request.url, downloadResource(urlSchemeTask: urlSchemeTask) {
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

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        _ = downloadTasks.remove(urlSchemeTask)
        print(" STOP \(urlSchemeTask.request.url)")
    }
}
