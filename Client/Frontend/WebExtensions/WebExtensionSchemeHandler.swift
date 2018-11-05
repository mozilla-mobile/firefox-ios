/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebKit

class WebExtensionSchemeHandler: NSObject {
    static let `default` = WebExtensionSchemeHandler()

    private override init() {
        super.init()
    }
}

extension WebExtensionSchemeHandler: WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url,
            let id = url.host else {
                urlSchemeTask.didFailWithError(URLError(.badURL))
                return
        }

        guard let webExtension = WebExtensionManager.default.webExtensions.find({ $0.id == id }) else {
            urlSchemeTask.didFailWithError(URLError(.fileDoesNotExist))
            return
        }

        let file: URL
        if url.path == "/__firefox__/web-extension-background-process" {
            file = Bundle.main.url(forResource: "WebExtensionBackgroundProcess", withExtension: "html")!
        } else {
            file = webExtension.tempDirectoryURL.appendingPathComponent(url.path)
        }

        do {
            let data = try Data(contentsOf: file)
            let mimeType = MIMEType.mimeTypeFromFileExtension(file.pathExtension)
            let response = URLResponse(url: url, mimeType: mimeType, expectedContentLength: data.count, textEncodingName: nil)
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(data)
            urlSchemeTask.didFinish()
        } catch {
            urlSchemeTask.didFailWithError(URLError(.fileDoesNotExist))
        }
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        // NOOP
    }
}
