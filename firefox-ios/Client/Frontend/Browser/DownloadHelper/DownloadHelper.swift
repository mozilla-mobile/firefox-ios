// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MobileCoreServices
import WebKit
import Shared

class DownloadHelper: NSObject {
    private let request: URLRequest
    private let preflightResponse: URLResponse
    private let cookieStore: WKHTTPCookieStore

    static func requestDownload(url: URL, tab: Tab) {
        let safeUrl = url.absoluteString.replacingOccurrences(of: "'", with: "%27")
        tab.webView?.evaluateJavascriptInDefaultContentWorld(
            "window.__firefox__.download('\(safeUrl)', '\(UserScriptManager.appIdToken)')"
        )
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .downloadLinkButton)
    }

    required init?(
        request: URLRequest?,
        response: URLResponse,
        cookieStore: WKHTTPCookieStore
    ) {
        guard let request = request else { return nil }

        self.cookieStore = cookieStore
        self.request = request
        self.preflightResponse = response
    }

    func shouldDownloadFile(canShowInWebView: Bool,
                            forceDownload: Bool,
                            isForMainFrame: Bool) -> Bool {
        let mimeType = preflightResponse.mimeType ?? MIMEType.OctetStream

        // Handles automatic Blob URL download
        if mimeType == MIMEType.OctetStream {
            return true
        }

        // Handles attachments downloads.
        // Only supports PDF and Words docs but can be expanded to support more extensions
        if shouldDownloadAttachment(isForMainFrame: isForMainFrame) {
            return true
        }

        // Handles forced downloads && MIMETypes not supported on webview
        return !canShowInWebView || forceDownload
    }

    func shouldDownloadAttachment(isForMainFrame: Bool) -> Bool {
        let contentDisposition = (preflightResponse as? HTTPURLResponse)?.allHeaderFields["Content-Disposition"] as? String
        let isAttachment = contentDisposition?.starts(with: "attachment") ?? false
        let canBeDownloaded = MIMEType.canBeDownloaded(preflightResponse.mimeType) && !isForMainFrame

        return isAttachment && canBeDownloaded
    }

    func downloadViewModel(windowUUID: WindowUUID,
                           okAction: @escaping (HTTPDownload) -> Void) -> PhotonActionSheetViewModel? {
        var requestUrl = request.url
        if let url = requestUrl, url.scheme == "blob" {
            requestUrl = url.removeBlobFromUrl()
        }

        guard let host = requestUrl?.host else { return nil }

        guard let download = HTTPDownload(originWindow: windowUUID,
                                          cookieStore: cookieStore,
                                          preflightResponse: preflightResponse,
                                          request: request)
        else { return nil }

        let expectedSize = download.totalBytesExpected != nil ? ByteCountFormatter.string(
            fromByteCount: download.totalBytesExpected!,
            countStyle: .file
        ) : nil

        var filenameItem: SingleActionViewModel
        var modelText = host

        // This size reflects the (possibly compressed) download size of the file, not necessarily its true size.
        // e.g. In the case of gzip content (FXIOS-9039)
        if let expectedSize = expectedSize {
            modelText = "\(expectedSize) — \(host)"
        }

        filenameItem = SingleActionViewModel(title: download.filename,
                                             text: modelText,
                                             iconString: "file",
                                             iconAlignment: .right,
                                             bold: true)
        filenameItem.customHeight = { _ in
            return 80
        }

        filenameItem.customRender = { label, contentView in
            label.numberOfLines = 2
            label.font = FXFontStyles.Bold.body.scaledFont()
            label.lineBreakMode = .byCharWrapping
        }

        let downloadFileItem = SingleActionViewModel(title: .OpenInDownloadHelperAlertDownloadNow,
                                                     iconString: StandardImageIdentifiers.Large.download) { _ in
            okAction(download)
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .downloadNowButton)
        }

        let actions = [[filenameItem.items], [downloadFileItem.items]]
        let viewModel = PhotonActionSheetViewModel(actions: actions,
                                                   closeButtonTitle: .CancelString,
                                                   title: download.filename,
                                                   modalStyle: .overCurrentContext)

        return viewModel
    }
}
