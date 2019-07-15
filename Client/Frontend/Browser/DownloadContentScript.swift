/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebKit

class DownloadContentScript: TabContentScript {
    fileprivate weak var tab: Tab?

    class func name() -> String {
        return "DownloadContentScript"
    }

    required init(tab: Tab) {
        self.tab = tab
    }

    func scriptMessageHandlerName() -> String? {
        return "downloadManager"
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let browserViewController = appDelegate.browserViewController,
            let dictionary = message.body as? [String: Any?],
            var filename = dictionary["filename"] as? String,
            let mimeType = dictionary["mimeType"] as? String,
            let size = dictionary["size"] as? Int64,
            let base64String = dictionary["base64String"] as? String,
            let data = Bytes.decodeBase64(base64String) else {
            return
        }

        browserViewController.pendingDownloadWebView = nil

        if !filename.contains(".") {
            if let fileExtension = MIMEType.fileExtensionFromMIMEType(mimeType) {
                filename += ".\(fileExtension)"
            }
        }

        let download = BlobDownload(filename: filename, mimeType: mimeType, size: size, data: data)
        appDelegate.browserViewController.downloadQueue.enqueue(download)
    }
}
