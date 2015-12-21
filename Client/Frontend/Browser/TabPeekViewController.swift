/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage
import ReadingList

@available(iOS 9.0, *)
protocol TabPeekDelegate: class {
    func tabPeekDidAddBookmark(tab: Browser)
    func tabPeekDidAddToReadingList(tab: Browser) -> ReadingListClientRecord?
    func tabPeekRequestsPresentationOf(viewController viewController: UIViewController)
    func tabPeekDidCloseTab(tab: Browser)
}

@available(iOS 9.0, *)
class TabPeekViewController: UIViewController, WKNavigationDelegate {

    private static let PreviewActionAddToBookmarks = NSLocalizedString("Add to Bookmarks", tableName: "3DTouchActions", comment: "Label for preview action on Tab Tray Tab to add current tab to Bookmarks")
    private static let PreviewActionAddToReadingList = NSLocalizedString("Add to Reading List", tableName: "3DTouchActions", comment: "Label for preview action on Tab Tray Tab to add current tab to Reading List")
    private static let PreviewActionSendToDevice = NSLocalizedString("Send to Device", tableName: "3DTouchActions", comment: "Label for preview action on Tab Tray Tab to send the current tab to another device")
    private static let PreviewActionCopyURL = NSLocalizedString("Copy URL", tableName: "3DTouchActions", comment: "Label for preview action on Tab Tray Tab to copy the URL of the current tab to clipboard")
    private static let PreviewActionCloseTab = NSLocalizedString("Close Tab", tableName: "3DTouchActions", comment: "Label for preview action on Tab Tray Tab to close the current tab")

    weak var tab: Browser?

    private weak var delegate: TabPeekDelegate?
    private var clientPicker: UINavigationController?
    private var isBookmarked: Bool = false
    private var isInReadingList: Bool = false
    private var hasRemoteClients: Bool = false
    private var ignoreURL: Bool = false

    private var screenShot: UIImageView?
    private var previewAccessibilityLabel: String!

    // Preview action items.
    lazy var previewActions: [UIPreviewActionItem] = {
        var actions = [UIPreviewActionItem]()
        if(!self.ignoreURL) {
            if !self.isInReadingList {
                actions.append(UIPreviewAction(title: TabPeekViewController.PreviewActionAddToReadingList, style: .Default) { previewAction, viewController in
                    guard let tab = self.tab else { return }
                    self.delegate?.tabPeekDidAddToReadingList(tab)
                })
            }
            if !self.isBookmarked {
                actions.append(UIPreviewAction(title: TabPeekViewController.PreviewActionAddToBookmarks, style: .Default) { previewAction, viewController in
                    guard let tab = self.tab else { return }
                    self.delegate?.tabPeekDidAddBookmark(tab)
                    })
            }
            if self.hasRemoteClients {
                actions.append(UIPreviewAction(title: TabPeekViewController.PreviewActionSendToDevice, style: .Default) { previewAction, viewController in
                    guard let clientPicker = self.clientPicker else { return }
                    self.delegate?.tabPeekRequestsPresentationOf(viewController: clientPicker)
                    })
            }
            // only add the copy URL action if we don't already have 3 items in our list
            // as we are only allowed 4 in total and we always want to display close tab
            if actions.count < 3 {
                actions.append(UIPreviewAction(title: TabPeekViewController.PreviewActionCopyURL, style: .Default) { previewAction, viewController in
                    guard let url = self.tab?.url where url.absoluteString.characters.count > 0 else { return }
                    let pasteBoard = UIPasteboard.generalPasteboard()
                    pasteBoard.URL = url
                    })
            }
        }
        actions.append(UIPreviewAction(title: TabPeekViewController.PreviewActionCloseTab, style: .Destructive) { previewAction, viewController in
            guard let tab = self.tab else { return }
            self.delegate?.tabPeekDidCloseTab(tab)
            })

        return actions
    }()


    init(tab: Browser, delegate: TabPeekDelegate?) {
        self.tab = tab
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        previewAccessibilityLabel = NSLocalizedString("Preview of \(tab?.webView?.accessibilityLabel)", tableName: "3DTouchActions", comment: "Accessibility Label for preview in Tab Tray of current tab")
        // if there is no screenshot, load the URL in a web page
        // otherwise just show the screenshot
        setupWebView(tab?.webView)
        guard let screenshot = tab?.screenshot else { return }
        setupWithScreenshot(screenshot)
    }

    private func setupWithScreenshot(screenshot: UIImage) {
        let imageView = UIImageView(image: screenshot)
        self.view.addSubview(imageView)

        imageView.snp_makeConstraints { make in
            make.edges.equalTo(self.view)
        }
        
        screenShot = imageView
        screenShot?.accessibilityLabel = previewAccessibilityLabel
    }

    private func setupWebView(webView: WKWebView?) {
        guard let webView = webView, let url = webView.URL where !isIgnoredURL(url) else { return }
        let clonedWebView = WKWebView(frame: webView.frame, configuration: webView.configuration)
        clonedWebView.allowsLinkPreview = false
        webView.accessibilityLabel = previewAccessibilityLabel
        self.view.addSubview(clonedWebView)

        clonedWebView.snp_makeConstraints { make in
            make.edges.equalTo(self.view)
        }

        clonedWebView.navigationDelegate = self

        clonedWebView.loadRequest(NSURLRequest(URL: url))
    }

    func setState(withProfile browserProfile: BrowserProfile, clientPickerDelegate: ClientPickerViewControllerDelegate) {
        guard let displayURL = tab?.url?.absoluteString where displayURL.characters.count > 0 else { return }

        browserProfile.bookmarks.isBookmarked(displayURL).upon {
            self.isBookmarked = $0.successValue ?? false
        }

        browserProfile.remoteClientsAndTabs.getClientGUIDs().upon {
            if let clientGUIDs = $0.successValue {
                self.hasRemoteClients = !clientGUIDs.isEmpty
                let clientPickerController = ClientPickerViewController()
                clientPickerController.clientPickerDelegate = clientPickerDelegate
                clientPickerController.profile = browserProfile
                if let url = self.tab?.url?.absoluteString {
                    clientPickerController.shareItem = ShareItem(url: url, title: self.tab?.title, favicon: nil)
                }

                self.clientPicker = UINavigationController(rootViewController: clientPickerController)
            }
        }

        let result = browserProfile.readingList?.getRecordWithURL(displayURL).successValue!
        isInReadingList = (result?.url.characters.count > 0) ?? false

        ignoreURL = isIgnoredURL(displayURL)
    }

    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        screenShot?.removeFromSuperview()
        screenShot = nil
    }
}
