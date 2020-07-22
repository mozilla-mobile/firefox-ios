/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebKit

class DownloadContentScript: TabContentScript {
    fileprivate weak var tab: Tab?

    // Non-blob URLs use the webview to download, by navigating in the webview to the requested URL.
    // Blobs however, use the JS content script to download using XHR
    fileprivate static var blobUrlForDownload: URL?

    class func name() -> String {
        return "DownloadContentScript"
    }

    required init(tab: Tab) {
        self.tab = tab
    }

    func scriptMessageHandlerName() -> String? {
        return "downloadManager"
    }

    static func requestDownload(url: URL, tab: Tab) {
        let safeUrl = url.absoluteString.replacingOccurrences(of: "'", with: "%27")
        blobUrlForDownload = url.scheme == "blob" ? URL(string: safeUrl) : nil
        tab.webView?.evaluateJavaScript("window.__firefox__.download('\(safeUrl)', '\(UserScriptManager.appIdToken)')")
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .downloadLinkButton)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        guard let browserViewController = tab?.browserViewController,
            let dictionary = message.body as? [String: Any?],
            let _url = dictionary["url"] as? String,
            let url = URL(string: _url),
            let mimeType = dictionary["mimeType"] as? String,
            let size = dictionary["size"] as? Int64,
            let base64String = dictionary["base64String"] as? String,
            let data = Bytes.decodeBase64(base64String) else {
            return
        }
        defer {
            browserViewController.pendingDownloadWebView = nil
            DownloadContentScript.blobUrlForDownload = nil
        }

        guard let requestedUrl = DownloadContentScript.blobUrlForDownload else {
            print("DownloadContentScript: no url was requested")
            return
        }

        guard requestedUrl == url else {
            print("DownloadContentScript: URL mismatch")
            return
        }

        // Note: url.lastPathComponent fails on blob: URLs (shrug).
        var filename = url.absoluteString.components(separatedBy: "/").last ?? "data"
        if filename.isEmpty {
            filename = "data"
        }

        if !filename.contains(".") {
            if let fileExtension = MIMEType.fileExtensionFromMIMEType(mimeType) {
                filename += ".\(fileExtension)"
            }
        }

        let download = BlobDownload(filename: filename, mimeType: mimeType, size: size, data: data)
        tab?.browserViewController?.downloadQueue.enqueue(download)
    }
}
