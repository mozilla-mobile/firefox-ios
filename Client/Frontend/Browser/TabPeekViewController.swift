/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import Storage
import ReadingList
import WebKit

protocol TabPeekDelegate: class {
    func tabPeekDidAddBookmark(_ tab: Tab)
    @discardableResult func tabPeekDidAddToReadingList(_ tab: Tab) -> ReadingListClientRecord?
    func tabPeekRequestsPresentationOf(_ viewController: UIViewController)
    func tabPeekDidCloseTab(_ tab: Tab)
}

class TabPeekViewController: UIViewController, WKNavigationDelegate {

    fileprivate static let PreviewActionAddToBookmarks = NSLocalizedString("Add to Bookmarks", tableName: "3DTouchActions", comment: "Label for preview action on Tab Tray Tab to add current tab to Bookmarks")
    fileprivate static let PreviewActionAddToReadingList = NSLocalizedString("Add to Reading List", tableName: "3DTouchActions", comment: "Label for preview action on Tab Tray Tab to add current tab to Reading List")
    fileprivate static let PreviewActionSendToDevice = NSLocalizedString("Send to Device", tableName: "3DTouchActions", comment: "Label for preview action on Tab Tray Tab to send the current tab to another device")
    fileprivate static let PreviewActionCopyURL = NSLocalizedString("Copy URL", tableName: "3DTouchActions", comment: "Label for preview action on Tab Tray Tab to copy the URL of the current tab to clipboard")
    fileprivate static let PreviewActionCloseTab = NSLocalizedString("Close Tab", tableName: "3DTouchActions", comment: "Label for preview action on Tab Tray Tab to close the current tab")

    weak var tab: Tab?

    fileprivate weak var delegate: TabPeekDelegate?
    fileprivate var clientPicker: UINavigationController?
    fileprivate var isBookmarked: Bool = false
    fileprivate var isInReadingList: Bool = false
    fileprivate var hasRemoteClients: Bool = false
    fileprivate var ignoreURL: Bool = false

    fileprivate var screenShot: UIImageView?
    fileprivate var previewAccessibilityLabel: String!

    // Preview action items.
    lazy var previewActions: [UIPreviewActionItem] = {
        var actions = [UIPreviewActionItem]()
        if !self.ignoreURL {
            if !self.isInReadingList {
                actions.append(UIPreviewAction(title: TabPeekViewController.PreviewActionAddToReadingList, style: .default) { previewAction, viewController in
                    guard let tab = self.tab else { return }
                    let _ = self.delegate?.tabPeekDidAddToReadingList(tab)
                })
            }
            if !self.isBookmarked {
                actions.append(UIPreviewAction(title: TabPeekViewController.PreviewActionAddToBookmarks, style: .default) { previewAction, viewController in
                    guard let tab = self.tab else { return }
                    self.delegate?.tabPeekDidAddBookmark(tab)
                    })
            }
            if self.hasRemoteClients {
                actions.append(UIPreviewAction(title: TabPeekViewController.PreviewActionSendToDevice, style: .default) { previewAction, viewController in
                    guard let clientPicker = self.clientPicker else { return }
                    self.delegate?.tabPeekRequestsPresentationOf(clientPicker)
                    })
            }
            // only add the copy URL action if we don't already have 3 items in our list
            // as we are only allowed 4 in total and we always want to display close tab
            if actions.count < 3 {
                actions.append(UIPreviewAction(title: TabPeekViewController.PreviewActionCopyURL, style: .default) { previewAction, viewController in
                    guard let url = self.tab?.url, url.absoluteString.characters.count > 0 else { return }
                    let pasteBoard = UIPasteboard.general
                    pasteBoard.url = url as URL
                })
            }
        }
        actions.append(UIPreviewAction(title: TabPeekViewController.PreviewActionCloseTab, style: .destructive) { previewAction, viewController in
            guard let tab = self.tab else { return }
            self.delegate?.tabPeekDidCloseTab(tab)
            })

        return actions
    }()

    init(tab: Tab, delegate: TabPeekDelegate?) {
        self.tab = tab
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let webViewAccessibilityLabel = tab?.webView?.accessibilityLabel {
            previewAccessibilityLabel = String(format: NSLocalizedString("Preview of %@", tableName: "3DTouchActions", comment: "Accessibility label, associated to the 3D Touch action on the current tab in the tab tray, used to display a larger preview of the tab."), webViewAccessibilityLabel)
        }
        // if there is no screenshot, load the URL in a web page
        // otherwise just show the screenshot
        setupWebView(tab?.webView)
        guard let screenshot = tab?.screenshot else { return }
        setupWithScreenshot(screenshot)
    }

    fileprivate func setupWithScreenshot(_ screenshot: UIImage) {
        let imageView = UIImageView(image: screenshot)
        self.view.addSubview(imageView)

        imageView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }

        screenShot = imageView
        screenShot?.accessibilityLabel = previewAccessibilityLabel
    }

    fileprivate func setupWebView(_ webView: WKWebView?) {
        guard let webView = webView, let url = webView.url, !isIgnoredURL(url) else { return }
        let clonedWebView = WKWebView(frame: webView.frame, configuration: webView.configuration)
        clonedWebView.allowsLinkPreview = false
        webView.accessibilityLabel = previewAccessibilityLabel
        self.view.addSubview(clonedWebView)

        clonedWebView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }

        clonedWebView.navigationDelegate = self

        clonedWebView.load(URLRequest(url: url))
    }

    func setState(withProfile browserProfile: BrowserProfile, clientPickerDelegate: ClientPickerViewControllerDelegate) {
        assert(Thread.current.isMainThread)

        guard let tab = self.tab else {
            return
        }

        guard let displayURL = tab.url?.absoluteString, displayURL.characters.count > 0 else {
            return
        }

        let mainQueue = DispatchQueue.main
        browserProfile.bookmarks.modelFactory >>== {
            $0.isBookmarked(displayURL).uponQueue(mainQueue) {
                self.isBookmarked = $0.successValue ?? false
            }
        }

        browserProfile.remoteClientsAndTabs.getClientGUIDs().uponQueue(mainQueue) {
            guard let clientGUIDs = $0.successValue else {
                return
            }

            self.hasRemoteClients = !clientGUIDs.isEmpty
            let clientPickerController = ClientPickerViewController()
            clientPickerController.clientPickerDelegate = clientPickerDelegate
            clientPickerController.profile = browserProfile
            if let url = tab.url?.absoluteString {
                clientPickerController.shareItem = ShareItem(url: url, title: tab.title, favicon: nil)
            }

            self.clientPicker = UINavigationController(rootViewController: clientPickerController)
        }

        let result = browserProfile.readingList?.getRecordWithURL(displayURL).successValue!

        self.isInReadingList = (result?.url.characters.count ?? 0) > 0
        self.ignoreURL = isIgnoredURL(displayURL)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        screenShot?.removeFromSuperview()
        screenShot = nil
    }
}
