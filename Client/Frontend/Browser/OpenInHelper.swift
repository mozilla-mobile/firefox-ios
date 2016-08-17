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
    static let TextFont = UIFont.systemFontOfSize(16)
    static let TextColor = UIColor(red: 74.0/255.0, green: 144.0/255.0, blue: 226.0/255.0, alpha: 1.0)
    static let TextOffset = -15
    static let OpenInString = NSLocalizedString("Open in…", comment: "String indicating that the file can be opened in another application on the device")
}

enum MimeType: String {
    case PDF = "application/pdf"
    case PASS = "application/vnd.apple.pkpass"
}

protocol OpenInHelper {
    init?(response: NSURLResponse)
    var openInView: UIView? { get set }
    func open()
}

struct OpenIn {
    static let helpers: [OpenInHelper.Type] = [OpenPdfInHelper.self, OpenPassBookHelper.self, ShareFileHelper.self]
    
    static func helperForResponse(response: NSURLResponse) -> OpenInHelper? {
        return helpers.flatMap { $0.init(response: response) }.first
    }
}

class ShareFileHelper: NSObject, OpenInHelper {
    var openInView: UIView? = nil

    private var url: NSURL
    var pathExtension: String?

    required init?(response: NSURLResponse) {
        guard let MIMEType = response.MIMEType where !(MIMEType == MimeType.PASS.rawValue || MIMEType == MimeType.PDF.rawValue),
            let responseURL = response.URL else { return nil }
        url = responseURL
        super.init()
    }

    func open() {
        let alertController = UIAlertController(
            title: Strings.OpenInDownloadHelperAlertTitle,
            message: Strings.OpenInDownloadHelperAlertMessage,
            preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction( UIAlertAction(title: Strings.OpenInDownloadHelperAlertCancel, style: .Cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: Strings.OpenInDownloadHelperAlertConfirm, style: .Default) { (action) in
            let objectsToShare = [self.url]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            if let sourceView = self.openInView, popoverController = activityVC.popoverPresentationController {
                popoverController.sourceView = sourceView
                popoverController.sourceRect = CGRect(origin: CGPoint(x: CGRectGetMidX(sourceView.bounds), y: CGRectGetMaxY(sourceView.bounds)), size: CGSizeZero)
                popoverController.permittedArrowDirections = .Up
            }
            UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(activityVC, animated: true, completion: nil)
        })
        UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
    }
}

class OpenPassBookHelper: NSObject, OpenInHelper {
    var openInView: UIView? = nil

    private var url: NSURL

    required init?(response: NSURLResponse) {
        guard let MIMEType = response.MIMEType where MIMEType == MimeType.PASS.rawValue && PKAddPassesViewController.canAddPasses(),
            let responseURL = response.URL else { return nil }
        url = responseURL
        super.init()
    }

    func open() {
        guard let passData = NSData(contentsOfURL: url) else { return }
        var error: NSError? = nil
        let pass = PKPass(data: passData, error: &error)
        if let _ = error {
            // display an error
            let alertController = UIAlertController(
                title: Strings.UnableToAddPassErrorTitle,
                message: Strings.UnableToAddPassErrorMessage,
                preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(
                UIAlertAction(title: Strings.UnableToAddPassErrorDismiss, style: .Cancel) { (action) in
                    // Do nothing.
                })
            UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
            return
        }
        let passLibrary = PKPassLibrary()
        if passLibrary.containsPass(pass) {
            UIApplication.sharedApplication().openURL(pass.passURL)
        } else {
            let addController = PKAddPassesViewController(pass: pass)
            UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(addController, animated: true, completion: nil)
        }

    }
}

class OpenPdfInHelper: NSObject, OpenInHelper, UIDocumentInteractionControllerDelegate {
    private var url: NSURL
    private var docController: UIDocumentInteractionController? = nil
    private var openInURL: NSURL?

    lazy var openInView: UIView? = getOpenInView(self)()

    lazy var documentDirectory: NSURL = {
        return NSURL(string: NSTemporaryDirectory())!.URLByAppendingPathComponent("pdfs")
    }()

    private var filepath: NSURL?

    required init?(response: NSURLResponse) {
        guard let MIMEType = response.MIMEType where MIMEType == MimeType.PDF.rawValue && UIApplication.sharedApplication().canOpenURL(NSURL(string: "itms-books:")!),
            let responseURL = response.URL else { return nil }
        url = responseURL
        super.init()
        setFilePath(response.suggestedFilename ?? url.lastPathComponent ?? "file.pdf")
    }

    private func setFilePath(suggestedFilename: String) {
        var filename = suggestedFilename
        let pathExtension = filename.asURL?.pathExtension
        if pathExtension == nil {
            filename.appendContentsOf(".pdf")
        }
        filepath = documentDirectory.URLByAppendingPathComponent(filename)
    }

    deinit {
        guard let url = openInURL else { return }
        let fileManager = NSFileManager.defaultManager()
        do {
            try fileManager.removeItemAtURL(url)
        } catch {
            log.error("failed to delete file at \(url): \(error)")
        }
    }

    func getOpenInView() -> OpenInView {
        let overlayView = OpenInView()

        overlayView.openInButton.addTarget(self, action: #selector(OpenPdfInHelper.open), forControlEvents: .TouchUpInside)
        return overlayView
    }

    func createDocumentControllerForURL(url: NSURL) {
        docController = UIDocumentInteractionController(URL: url)
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
                createDocumentControllerForURL(url)
                return
            }
            let contentsOfFile = NSData(contentsOfURL: url)
            let fileManager = NSFileManager.defaultManager()
            do {
                try fileManager.createDirectoryAtPath(documentDirectory.absoluteString, withIntermediateDirectories: true, attributes: nil)
                if fileManager.createFileAtPath(filePath.absoluteString, contents: contentsOfFile, attributes: nil) {
                    let openInURL = NSURL(fileURLWithPath: filePath.absoluteString)
                    createDocumentControllerForURL(openInURL)
                } else {
                    log.error("Unable to create local version of PDF file at \(filePath)")
                }
            } catch {
                log.error("Error on creating directory at \(documentDirectory)")
            }
        }
    }

    func open() {
        createLocalCopyOfPDF()
        guard let _parentView = self.openInView!.superview, docController = self.docController else { log.error("view doesn't have a superview so can't open anything"); return }
        // iBooks should be installed by default on all devices we care about, so regardless of whether or not there are other pdf-capable
        // apps on this device, if we can open in iBooks we can open this PDF
        // simulators do not have iBooks so the open in view will not work on the simulator
        if UIApplication.sharedApplication().canOpenURL(NSURL(string: "itms-books:")!) {
            log.info("iBooks installed: attempting to open pdf")
            docController.presentOpenInMenuFromRect(CGRectZero, inView: _parentView, animated: true)
        } else {
            log.info("iBooks is not installed")
        }
    }
}

class OpenInView: UIView {
    let openInButton = UIButton()

    init() {
        super.init(frame: CGRectZero)
        openInButton.setTitleColor(OpenInViewUX.TextColor, forState: UIControlState.Normal)
        openInButton.setTitle(OpenInViewUX.OpenInString, forState: UIControlState.Normal)
        openInButton.titleLabel?.font = OpenInViewUX.TextFont
        openInButton.sizeToFit()
        self.addSubview(openInButton)
        openInButton.snp_makeConstraints { make in
            make.centerY.equalTo(self)
            make.height.equalTo(self)
            make.trailing.equalTo(self).offset(OpenInViewUX.TextOffset)
        }
        self.backgroundColor = UIColor.whiteColor()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
