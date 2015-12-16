//
//  TabViewController.swift
//  Client
//
//  Created by Emily Toop on 12/2/15.
//  Copyright © 2015 Mozilla. All rights reserved.
//

import UIKit
import Storage

@available(iOS 9.0, *)
class TabPeekViewController: UIViewController {

    let PreviewActionAddToBookmarks = NSLocalizedString("Add to Bookmarks", comment: "")
    let PreviewActionAddToReadingList = NSLocalizedString("Add to Reading List", comment: "")
    let PreviewActionSendToDevice = NSLocalizedString("Send to Device", comment: "")
    let PreviewActionCopyURL = NSLocalizedString("Copy URL", comment: "")
    let PreviewActionCloseTab = NSLocalizedString("Close Tab", comment: "")

    let tab: Browser
    let bvc: BrowserViewController?
    let tabManager: TabManager
    var clientPicker: UINavigationController?
    var isBookmarked: Bool = false
    var isInReadingList: Bool = false
    var hasRemoteClients: Bool = false
    var ignoreURL: Bool = false

    // Preview action items.
    lazy var previewActions: [UIPreviewActionItem] = {
        var actions = [UIPreviewActionItem]()
        if(!self.ignoreURL) {
            if !self.isInReadingList {
                actions.append(UIPreviewAction(title: self.PreviewActionAddToReadingList, style: .Default) { previewAction, viewController in
                    guard let displayURL = self.tab.url?.absoluteString where displayURL.characters.count > 0 else { return }
                    self.bvc?.addToReadingList(displayURL, title: self.tab.lastTitle ?? displayURL)
                })
            }
            if !self.isBookmarked {
                actions.append(UIPreviewAction(title: self.PreviewActionAddToBookmarks, style: .Default) { previewAction, viewController in
                    guard let displayURL = self.tab.url?.absoluteString where displayURL.characters.count > 0 else { return }

                    self.bvc?.addBookmark(displayURL, title: self.tab.lastTitle ?? displayURL)
                    })
            }
            if self.hasRemoteClients {
                actions.append(UIPreviewAction(title: self.PreviewActionSendToDevice, style: .Default) { previewAction, viewController in
                    guard let clientPicker = self.clientPicker else { return }
                    self.bvc?.presentViewController(clientPicker, animated: false, completion: nil)
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


    init(tab: Browser, controller: BrowserViewController?, tabManager: TabManager) {
        self.tab = tab
        self.bvc = controller
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
        guard let screenshot = tab.screenshot else {
            setupWebView(tab.url)
            return
        }
        setupWithScreenshot(screenshot)
    }

    private func setupWithScreenshot(screenshot: UIImage) {
        let imageView = UIImageView(image: screenshot)
        self.view.addSubview(imageView)

        imageView.snp_makeConstraints { make in
            make.edges.equalTo(self.view)
        }
    }

    private func setupWebView(url: NSURL?) {
        let webView = WKWebView()
        self.view.addSubview(webView)

        webView.snp_makeConstraints { make in
            make.edges.equalTo(self.view)
        }

        if let url = url {
            webView.loadRequest(NSURLRequest(URL: url))
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
}
