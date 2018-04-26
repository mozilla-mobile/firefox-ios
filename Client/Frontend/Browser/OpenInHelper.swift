/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import PassKit
import WebKit
import SnapKit

import Shared

import XCGLogger

private let log = Logger.browserLogger

struct OpenInViewUX {
    static let ViewHeight: CGFloat = 40.0
    static let TextFont = UIFont.systemFont(ofSize: 16)
    static let TextColor = UIColor.Photon.Blue60
    static let TextOffset = -15
    static let OpenInString = NSLocalizedString("Open in…", comment: "String indicating that the file can be opened in another application on the device")
}

struct MIMEType {
    static let OctetStream = "application/octet-stream"
    static let Passbook = "application/vnd.apple.pkpass"
    static let PDF = "application/pdf"
}

protocol OpenInHelper {
    init?(request: URLRequest?, response: URLResponse, canShowInWebView: Bool, browserViewController: BrowserViewController)
    var openInView: UIView? { get set }
    func open()
}

struct OpenIn {
    static let helpers: [OpenInHelper.Type] = [OpenPdfInHelper.self, OpenPassBookHelper.self, DownloadHelper.self]
    
    static func helperForRequest(_ request: URLRequest?, response: URLResponse, canShowInWebView: Bool, browserViewController: BrowserViewController) -> OpenInHelper? {
        return helpers.compactMap { $0.init(request: request, response: response, canShowInWebView: canShowInWebView, browserViewController: browserViewController) }.first
    }
}

class DownloadHelper: NSObject, OpenInHelper {
    var openInView: UIView?

    fileprivate let request: URLRequest
    fileprivate let preflightResponse: URLResponse
    fileprivate let browserViewController: BrowserViewController

    required init?(request: URLRequest?, response: URLResponse, canShowInWebView: Bool, browserViewController: BrowserViewController) {
        guard let request = request else {
            return nil
        }

        let contentDisposition = (response as? HTTPURLResponse)?.allHeaderFields["Content-Disposition"] as? String
        let mimeType = response.mimeType ?? MIMEType.OctetStream
        let isAttachment = contentDisposition?.starts(with: "attachment") ?? (mimeType == MIMEType.OctetStream)

        guard isAttachment || !canShowInWebView else {
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

        let download = Download(preflightResponse: preflightResponse, request: request)

        let expectedSize = download.totalBytesExpected != nil ? ByteCountFormatter.string(fromByteCount: download.totalBytesExpected!, countStyle: .file) : nil

        let filenameItem: PhotonActionSheetItem
        if let expectedSize = expectedSize {
            let expectedSizeAndHost = "\(expectedSize) — \(host)"
            filenameItem = PhotonActionSheetItem(title: download.filename, text: expectedSizeAndHost, iconString: "file", iconAlignment: .right, bold: true)
        } else {
            filenameItem = PhotonActionSheetItem(title: download.filename, text: host, iconString: "file", iconAlignment: .right, bold: true)
        }

        let downloadFileItem = PhotonActionSheetItem(title: Strings.OpenInDownloadHelperAlertDownloadNow, iconString: "download") { _ in
            self.browserViewController.downloadQueue.enqueueDownload(download)
        }

        let actions = [[filenameItem], [downloadFileItem]]

        browserViewController.presentSheetWith(actions: actions, on: browserViewController, from: browserViewController.urlBar, closeButtonTitle: Strings.CancelString, suppressPopover: true)
    }
}

class OpenPassBookHelper: NSObject, OpenInHelper {
    var openInView: UIView?

    fileprivate var url: URL

    fileprivate let browserViewController: BrowserViewController

    required init?(request: URLRequest?, response: URLResponse, canShowInWebView: Bool, browserViewController: BrowserViewController) {
        guard let mimeType = response.mimeType, mimeType == MIMEType.Passbook, PKAddPassesViewController.canAddPasses(),
            let responseURL = response.url else { return nil }
        self.url = responseURL
        self.browserViewController = browserViewController
        super.init()
    }

    func open() {
        guard let passData = try? Data(contentsOf: url) else { return }
        var error: NSError? = nil
        let pass = PKPass(data: passData, error: &error)
        if let _ = error {
            // display an error
            let alertController = UIAlertController(
                title: Strings.UnableToAddPassErrorTitle,
                message: Strings.UnableToAddPassErrorMessage,
                preferredStyle: .alert)
            alertController.addAction(
                UIAlertAction(title: Strings.UnableToAddPassErrorDismiss, style: .cancel) { (action) in
                    // Do nothing.
                })
            browserViewController.present(alertController, animated: true, completion: nil)
            return
        }
        let passLibrary = PKPassLibrary()
        if passLibrary.containsPass(pass) {
            UIApplication.shared.open(pass.passURL!, options: [:])
        } else {
            let addController = PKAddPassesViewController(pass: pass)
            browserViewController.present(addController, animated: true, completion: nil)
        }

    }
}

class OpenPdfInHelper: NSObject, OpenInHelper, UIDocumentInteractionControllerDelegate {
    fileprivate var url: URL
    fileprivate var docController: UIDocumentInteractionController?
    fileprivate var openInURL: URL?

    lazy var openInView: UIView? = getOpenInView()

    lazy var documentDirectory: URL = {
        return URL(string: NSTemporaryDirectory())!.appendingPathComponent("pdfs")
    }()

    fileprivate var filepath: URL?

    required init?(request: URLRequest?, response: URLResponse, canShowInWebView: Bool, browserViewController: BrowserViewController) {
        guard let mimeType = response.mimeType, mimeType == MIMEType.PDF, UIApplication.shared.canOpenURL(URL(string: "itms-books:")!),
            let responseURL = response.url else { return nil }
        url = responseURL
        super.init()
        setFilePath(response.suggestedFilename ?? url.lastPathComponent )
    }

    fileprivate func setFilePath(_ suggestedFilename: String) {
        var filename = suggestedFilename
        let pathExtension = filename.asURL?.pathExtension
        if pathExtension == nil {
            filename.append(".pdf")
        }
        filepath = documentDirectory.appendingPathComponent(filename)
    }

    deinit {
        guard let url = openInURL else { return }
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(at: url)
        } catch {
            log.error("failed to delete file at \(url): \(error)")
        }
    }

    func getOpenInView() -> OpenInView {
        let overlayView = OpenInView()

        overlayView.openInButton.addTarget(self, action: #selector(open), for: .touchUpInside)
        return overlayView
    }

    func createDocumentControllerForURL(url: URL) {
        docController = UIDocumentInteractionController(url: url)
        docController?.delegate = self
        self.openInURL = url
    }

    func createLocalCopyOfPDF() {
        guard let filePath = filepath else {
            log.error("failed to create proper URL")
            return
        }
        if docController == nil {
            // if we already have a URL but no document controller, just create the document controller
            if let url = openInURL {
                createDocumentControllerForURL(url: url)
                return
            }
            let contentsOfFile = try? Data(contentsOf: url)
            let fileManager = FileManager.default
            do {
                try fileManager.createDirectory(atPath: documentDirectory.absoluteString, withIntermediateDirectories: true, attributes: nil)
                if fileManager.createFile(atPath: filePath.absoluteString, contents: contentsOfFile, attributes: nil) {
                    let openInURL = URL(fileURLWithPath: filePath.absoluteString)
                    createDocumentControllerForURL(url: openInURL)
                } else {
                    log.error("Unable to create local version of PDF file at \(filePath)")
                }
            } catch {
                log.error("Error on creating directory at \(self.documentDirectory)")
            }
        }
    }

    @objc func open() {
        createLocalCopyOfPDF()
        guard let _parentView = self.openInView!.superview, let docController = self.docController else { log.error("view doesn't have a superview so can't open anything"); return }
        // iBooks should be installed by default on all devices we care about, so regardless of whether or not there are other pdf-capable
        // apps on this device, if we can open in iBooks we can open this PDF
        // simulators do not have iBooks so the open in view will not work on the simulator
        if UIApplication.shared.canOpenURL(URL(string: "itms-books:")!) {
            log.info("iBooks installed: attempting to open pdf")
            docController.presentOpenInMenu(from: .zero, in: _parentView, animated: true)
        } else {
            log.info("iBooks is not installed")
        }
    }
}

class OpenInView: UIView {
    let openInButton = UIButton()

    init() {
        super.init(frame: .zero)
        openInButton.setTitleColor(OpenInViewUX.TextColor, for: .normal)
        openInButton.setTitle(OpenInViewUX.OpenInString, for: .normal)
        openInButton.titleLabel?.font = OpenInViewUX.TextFont
        openInButton.sizeToFit()
        self.addSubview(openInButton)
        openInButton.snp.makeConstraints { make in
            make.centerY.equalTo(self)
            make.height.equalTo(self)
            make.trailing.equalTo(self).offset(OpenInViewUX.TextOffset)
        }
        self.backgroundColor = UIColor.white
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
