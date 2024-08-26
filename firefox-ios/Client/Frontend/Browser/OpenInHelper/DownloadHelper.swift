// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MobileCoreServices
import WebKit
import Shared
import UniformTypeIdentifiers

struct MIMEType {
    static let Bitmap = "image/bmp"
    static let CSS = "text/css"
    static let GIF = "image/gif"
    static let JavaScript = "text/javascript"
    static let JPEG = "image/jpeg"
    static let HTML = "text/html"
    static let OctetStream = "application/octet-stream"
    static let Passbook = "application/vnd.apple.pkpass"
    static let PDF = "application/pdf"
    static let PlainText = "text/plain"
    static let PNG = "image/png"
    static let WebP = "image/webp"
    static let Calendar = "text/calendar"
    static let USDZ = "model/vnd.usdz+zip"
    static let Reality = "model/vnd.reality"

    private static let webViewViewableTypes: [String] = [
        MIMEType.Bitmap,
        MIMEType.GIF,
        MIMEType.JPEG,
        MIMEType.HTML,
        MIMEType.PDF,
        MIMEType.PlainText,
        MIMEType.PNG,
        MIMEType.WebP]

    static func canShowInWebView(_ mimeType: String) -> Bool {
        return webViewViewableTypes.contains(mimeType.lowercased())
    }

    static func mimeTypeFromFileExtension(_ fileExtension: String) -> String {
        if let uti = UTType(filenameExtension: fileExtension),
           let mimeType = uti.preferredMIMEType {
            return mimeType as String
        }

        return MIMEType.OctetStream
    }

    static func fileExtensionFromMIMEType(_ mimeType: String) -> String? {
        if let uti = UTType(mimeType: mimeType),
           let fileExtension = uti.preferredFilenameExtension {
            return fileExtension as String
        }
        return nil
    }
}

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
        cookieStore: WKHTTPCookieStore,
        canShowInWebView: Bool,
        forceDownload: Bool
    ) {
        guard let request = request else { return nil }

        let mimeType = response.mimeType ?? MIMEType.OctetStream
        let isAttachment = mimeType == MIMEType.OctetStream

        // Bug 1474339 - Don't auto-download files served with 'Content-Disposition: attachment'
        // Leaving this here for now, but commented out. Checking this HTTP header is
        // what Desktop does should we ever decide to change our minds on this.
        // let contentDisposition = (response as? HTTPURLResponse)?.allHeaderFields["Content-Disposition"] as? String
        // let isAttachment = contentDisposition?.starts(with: "attachment") ?? (mimeType == MIMEType.OctetStream)

        guard isAttachment || !canShowInWebView || forceDownload else { return nil }

        self.cookieStore = cookieStore
        self.request = request
        self.preflightResponse = response
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
