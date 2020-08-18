/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import MobileCoreServices
import PassKit
import WebKit
import QuickLook
import Shared

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

    private static let webViewViewableTypes: [String] = [MIMEType.Bitmap, MIMEType.GIF, MIMEType.JPEG, MIMEType.HTML, MIMEType.PDF, MIMEType.PlainText, MIMEType.PNG, MIMEType.WebP]

    static func canShowInWebView(_ mimeType: String) -> Bool {
        return webViewViewableTypes.contains(mimeType.lowercased())
    }

    static func mimeTypeFromFileExtension(_ fileExtension: String) -> String {
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension as CFString, nil)?.takeRetainedValue(), let mimeType = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
            return mimeType as String
        }

        return MIMEType.OctetStream
    }

    static func fileExtensionFromMIMEType(_ mimeType: String) -> String? {
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)?.takeRetainedValue(), let fileExtension = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassFilenameExtension)?.takeRetainedValue() {
            return fileExtension as String
        }
        return nil
    }
}

protocol OpenInHelper {
    init?(request: URLRequest?, response: URLResponse, canShowInWebView: Bool, forceDownload: Bool, browserViewController: BrowserViewController)
    func open()
}

class DownloadHelper: NSObject, OpenInHelper {
    fileprivate let request: URLRequest
    fileprivate let preflightResponse: URLResponse
    fileprivate let browserViewController: BrowserViewController

    static func requestDownload(url: URL, tab: Tab) {
        let safeUrl = url.absoluteString.replacingOccurrences(of: "'", with: "%27")
        tab.webView?.evaluateJavaScript("window.__firefox__.download('\(safeUrl)', '\(UserScriptManager.appIdToken)')")
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .downloadLinkButton)
    }
    
    required init?(request: URLRequest?, response: URLResponse, canShowInWebView: Bool, forceDownload: Bool, browserViewController: BrowserViewController) {
        guard let request = request else {
            return nil
        }

        let mimeType = response.mimeType ?? MIMEType.OctetStream
        let isAttachment = mimeType == MIMEType.OctetStream

        // Bug 1474339 - Don't auto-download files served with 'Content-Disposition: attachment'
        // Leaving this here for now, but commented out. Checking this HTTP header is
        // what Desktop does should we ever decide to change our minds on this.
        // let contentDisposition = (response as? HTTPURLResponse)?.allHeaderFields["Content-Disposition"] as? String
        // let isAttachment = contentDisposition?.starts(with: "attachment") ?? (mimeType == MIMEType.OctetStream)

        guard isAttachment || !canShowInWebView || forceDownload else {
            return nil
        }

        self.request = request
        self.preflightResponse = response
        self.browserViewController = browserViewController
    }

    func open() {
        guard let host = request.url?.host else {
            return
        }

        let download = HTTPDownload(preflightResponse: preflightResponse, request: request)

        let expectedSize = download.totalBytesExpected != nil ? ByteCountFormatter.string(fromByteCount: download.totalBytesExpected!, countStyle: .file) : nil

        var filenameItem: PhotonActionSheetItem
        if let expectedSize = expectedSize {
            let expectedSizeAndHost = "\(expectedSize) — \(host)"
            filenameItem = PhotonActionSheetItem(title: download.filename, text: expectedSizeAndHost, iconString: "file", iconAlignment: .right, bold: true)
        } else {
            filenameItem = PhotonActionSheetItem(title: download.filename, text: host, iconString: "file", iconAlignment: .right, bold: true)
        }
        filenameItem.customHeight = { _ in
            return 80
        }
        filenameItem.customRender = { label, contentView in
            label.numberOfLines = 2
            label.font = DynamicFontHelper.defaultHelper.DeviceFontSmallBold
            label.lineBreakMode = .byCharWrapping
        }

        let downloadFileItem = PhotonActionSheetItem(title: Strings.OpenInDownloadHelperAlertDownloadNow, iconString: "download") { _, _ in
            self.browserViewController.downloadQueue.enqueue(download)
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .downloadNowButton)
        }

        let actions = [[filenameItem], [downloadFileItem]]

        browserViewController.presentSheetWith(actions: actions, on: browserViewController, from: browserViewController.urlBar, closeButtonTitle: Strings.CancelString, suppressPopover: true)
    }
}

class OpenPassBookHelper: NSObject, OpenInHelper {
    fileprivate var url: URL

    fileprivate let browserViewController: BrowserViewController

    required init?(request: URLRequest?, response: URLResponse, canShowInWebView: Bool, forceDownload: Bool, browserViewController: BrowserViewController) {
        guard let mimeType = response.mimeType, mimeType == MIMEType.Passbook, PKAddPassesViewController.canAddPasses(),
            let responseURL = response.url, !forceDownload else { return nil }
        self.url = responseURL
        self.browserViewController = browserViewController
        super.init()
    }

    func open() {
        guard let passData = try? Data(contentsOf: url) else { return }

        do {
            let pass = try PKPass(data: passData)

            let passLibrary = PKPassLibrary()
            if passLibrary.containsPass(pass) {
                UIApplication.shared.open(pass.passURL!, options: [:])
            } else {
                if let addController = PKAddPassesViewController(pass: pass) {
                    browserViewController.present(addController, animated: true, completion: nil)
                }
            }
        } catch {
            let alertController = UIAlertController(title: Strings.UnableToAddPassErrorTitle, message: Strings.UnableToAddPassErrorMessage, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: Strings.UnableToAddPassErrorDismiss, style: .cancel) { (action) in
                    // Do nothing.
            })
            browserViewController.present(alertController, animated: true, completion: nil)
            return
        }
    }
}

class OpenQLPreviewHelper: NSObject, OpenInHelper, QLPreviewControllerDataSource {
    var url: NSURL

    fileprivate let browserViewController: BrowserViewController

    fileprivate let previewController: QLPreviewController

    required init?(request: URLRequest?, response: URLResponse, canShowInWebView: Bool, forceDownload: Bool, browserViewController: BrowserViewController) {
        guard let mimeType = response.mimeType,
                 (mimeType == MIMEType.USDZ || mimeType == MIMEType.Reality),
                 let responseURL = response.url as NSURL?,
                 !forceDownload,
                 !canShowInWebView else { return nil }
        self.url = responseURL
        self.browserViewController = browserViewController
        self.previewController = QLPreviewController()
        super.init()
    }

    func open() {
        self.previewController.dataSource = self
        ensureMainThread {
            self.browserViewController.present(self.previewController, animated: true, completion: nil)
        }
    }

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return self.url
    }
}
