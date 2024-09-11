// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import WebKit
import Common

class DownloadContentScript: TabContentScript {
    fileprivate weak var tab: Tab?

    // Non-blob URLs use the webview to download, by navigating in the webview to the requested URL.
    // Blobs however, use the JS content script to download using XHR
    fileprivate static var blobUrlForDownload: URL?
    private let downloadQueue: DownloadQueue
    private let notificationCenter: NotificationProtocol

    class func name() -> String {
        return "DownloadContentScript"
    }

    required init(tab: Tab,
                  downloadQueue: DownloadQueue = AppContainer.shared.resolve(),
                  notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.tab = tab
        self.downloadQueue = downloadQueue
        self.notificationCenter = notificationCenter
    }

    func scriptMessageHandlerNames() -> [String]? {
        return ["downloadManager"]
    }

    /// This function handles blob downloads
    ///  - Checks if the url has a blob url scheme, returns false early if not.
    ///  - If it is a blob, this function calls JS (DownloadHelper.js) to start handling the download of the blob.
    /// - Parameters:
    ///     - url: URL of item to be downloaded
    ///     - tab: Tab item is being downloaded from
    static func requestBlobDownload(url: URL, tab: Tab) -> Bool {
        let safeUrl = url.absoluteString.replacingOccurrences(of: "'", with: "%27")
        guard url.scheme == "blob" else {
            return false
        }
        blobUrlForDownload = URL(string: safeUrl, invalidCharacters: false)
        tab.webView?.evaluateJavascriptInDefaultContentWorld(
            "window.__firefox__.download('\(safeUrl)', '\(UserScriptManager.appIdToken)')"
        )
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .downloadLinkButton)
        return true
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceiveScriptMessage message: WKScriptMessage
    ) {
        guard let dictionary = message.body as? [String: Any?],
              let _url = dictionary["url"] as? String,
              let url = URL(string: _url, invalidCharacters: false),
              let mimeType = dictionary["mimeType"] as? String,
              let size = dictionary["size"] as? Int64,
              let base64String = dictionary["base64String"] as? String,
              let data = Bytes.decodeBase64(base64String)
        else { return }

        let windowManager: WindowManager = AppContainer.shared.resolve()
        let windowUUID = tab?.windowUUID ?? windowManager.windows.first?.key ?? .unavailable
        defer {
            notificationCenter.post(name: .PendingBlobDownloadAddedToQueue, withObject: nil)
            DownloadContentScript.blobUrlForDownload = nil
        }

        guard let requestedUrl = DownloadContentScript.blobUrlForDownload else {
            return
        }

        guard requestedUrl == url else {
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

        let download = BlobDownload(originWindow: windowUUID, filename: filename, mimeType: mimeType, size: size, data: data)
        downloadQueue.enqueue(download)
    }
}
