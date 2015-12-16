/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage

@available(iOS 9.0, *)
class TabPeekViewController: UIViewController, WKNavigationDelegate {

    let PreviewActionAddToBookmarks = NSLocalizedString("Add to Bookmarks", comment: "")
    let PreviewActionAddToReadingList = NSLocalizedString("Add to Reading List", comment: "")
    let PreviewActionSendToDevice = NSLocalizedString("Send to Device", comment: "")
    let PreviewActionCopyURL = NSLocalizedString("Copy URL", comment: "")
    let PreviewActionCloseTab = NSLocalizedString("Close Tab", comment: "")

    let tab: Browser

    private let delegate: TabTrayDelegate?
    private let tabManager: TabManager
    private var clientPicker: UINavigationController?
    private var isBookmarked: Bool = false
    private var isInReadingList: Bool = false
    private var hasRemoteClients: Bool = false
    private var ignoreURL: Bool = false

    private var screenShot: UIImageView?

    // Preview action items.
    lazy var previewActions: [UIPreviewActionItem] = {
        var actions = [UIPreviewActionItem]()
        if(!self.ignoreURL) {
            if !self.isInReadingList {
                actions.append(UIPreviewAction(title: self.PreviewActionAddToReadingList, style: .Default) { previewAction, viewController in
                    self.delegate?.addToReadingList(self.tab)
                })
            }
            if !self.isBookmarked {
                actions.append(UIPreviewAction(title: self.PreviewActionAddToBookmarks, style: .Default) { previewAction, viewController in
                    self.delegate?.addBookmark(self.tab)
                    })
            }
            if self.hasRemoteClients {
                actions.append(UIPreviewAction(title: self.PreviewActionSendToDevice, style: .Default) { previewAction, viewController in
                    guard let clientPicker = self.clientPicker else { return }
                    self.delegate?.present(viewController: clientPicker)
                    })
            }
            actions.append(UIPreviewAction(title: self.PreviewActionCopyURL, style: .Default) { previewAction, viewController in
                guard let url = self.tab.url where url.absoluteString.characters.count > 0 else { return }
                let pasteBoard = UIPasteboard.generalPasteboard()
                pasteBoard.URL = url
                })
        }
        actions.append(UIPreviewAction(title: self.PreviewActionCloseTab, style: .Destructive) { previewAction, viewController in
            guard let tabViewController = viewController as? TabPeekViewController else { return }
            self.tabManager.removeTab(self.tab)
            })

        return actions
    }()


    init(tab: Browser, delegate: TabTrayDelegate?, tabManager: TabManager) {
        self.tab = tab
        self.delegate = delegate
        self.tabManager = tabManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // if there is no screenshot, load the URL in a web page
        // otherwise just show the screenshot
        setupWebView(tab.webView)
        guard let screenshot = tab.screenshot else { return }
        setupWithScreenshot(screenshot)
    }

    private func setupWithScreenshot(screenshot: UIImage) {
        let imageView = UIImageView(image: screenshot)
        self.view.addSubview(imageView)

        imageView.snp_makeConstraints { make in
            make.edges.equalTo(self.view)
        }
        
        screenShot = imageView
    }

    private func setupWebView(webView: WKWebView?) {
        guard let webView = webView else { return }
        let clonedWebView = WKWebView(frame: webView.frame, configuration: webView.configuration)
        clonedWebView.allowsLinkPreview = false
        webView.accessibilityLabel = NSLocalizedString("Preview of \(webView.accessibilityLabel)", comment: "")
        self.view.addSubview(clonedWebView)

        clonedWebView.snp_makeConstraints { make in
            make.edges.equalTo(self.view)
        }

        clonedWebView.navigationDelegate = self

        if let url = webView.URL {
            clonedWebView.loadRequest(NSURLRequest(URL: url))
        }
    }

    func setState(withProfile browserProfile: BrowserProfile, clientPickerDelegate: ClientPickerViewControllerDelegate) {
        guard let displayURL = tab.url?.absoluteString where displayURL.characters.count > 0 else { return }

        browserProfile.bookmarks.isBookmarked(displayURL).upon {
            self.isBookmarked = $0.successValue ?? false
        }

        browserProfile.remoteClientsAndTabs.getClientGUIDs().upon {
            if let clientGUIDs = $0.successValue {
                self.hasRemoteClients = !clientGUIDs.isEmpty
                let clientPickerController = ClientPickerViewController()
                clientPickerController.clientPickerDelegate = clientPickerDelegate
                clientPickerController.profile = browserProfile
                if let url = self.tab.url?.absoluteString {
                    clientPickerController.shareItem = ShareItem(url: url, title: self.tab.title, favicon: nil)
                }

                self.clientPicker = UINavigationController(rootViewController: clientPickerController)
            }
        }

        isInReadingList = browserProfile.readingList?.getRecordWithURL(displayURL).successValue != nil
        ignoreURL = isIgnoredURL(displayURL)
    }

    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        screenShot?.removeFromSuperview()
        screenShot = nil
    }
}
