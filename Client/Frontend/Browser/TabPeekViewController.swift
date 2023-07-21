// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared
import Storage
import WebKit

protocol TabPeekDelegate: AnyObject {
    @discardableResult
    func tabPeekDidAddToReadingList(_ tab: Tab) -> ReadingListItem?
    func tabPeekDidAddBookmark(_ tab: Tab)
    func tabPeekRequestsPresentationOf(_ viewController: UIViewController)
    func tabPeekDidCloseTab(_ tab: Tab)
    func tabPeekDidCopyUrl()
}

class TabPeekViewController: UIViewController, WKNavigationDelegate {
    weak var tab: Tab?

    fileprivate weak var delegate: TabPeekDelegate?
    fileprivate var fxaDevicePicker: UINavigationController?
    fileprivate var isBookmarked = false
    fileprivate var isInReadingList = false
    fileprivate var hasRemoteClients = false
    fileprivate var ignoreURL = false

    fileprivate var screenShot: UIImageView?
    fileprivate var previewAccessibilityLabel: String!
    fileprivate var webView: WKWebView?

    // Preview action items.
    override var previewActionItems: [UIPreviewActionItem] { return previewActions }

    lazy var previewActions: [UIPreviewActionItem] = {
        var actions = [UIPreviewActionItem]()

        let urlIsTooLongToSave = self.tab?.urlIsTooLong ?? false
        let isHomeTab = self.tab?.isFxHomeTab ?? false
        if !self.ignoreURL && !urlIsTooLongToSave {
            if !self.isBookmarked && !isHomeTab {
                actions.append(UIPreviewAction(title: .TabPeekAddToBookmarks, style: .default) { [weak self] previewAction, viewController in
                    guard let wself = self, let tab = wself.tab else { return }
                    wself.delegate?.tabPeekDidAddBookmark(tab)
                })
            }
            if self.hasRemoteClients {
                actions.append(UIPreviewAction(title: .AppMenu.TouchActions.SendToDeviceTitle, style: .default) { [weak self] previewAction, viewController in
                    guard let wself = self, let clientPicker = wself.fxaDevicePicker else { return }
                    wself.delegate?.tabPeekRequestsPresentationOf(clientPicker)
                })
            }
            // only add the copy URL action if we don't already have 3 items in our list
            // as we are only allowed 4 in total and we always want to display close tab
            if actions.count < 3 {
                actions.append(UIPreviewAction(title: .TabPeekCopyUrl, style: .default) { [weak self] previewAction, viewController in
                    guard let wself = self, let url = wself.tab?.canonicalURL else { return }

                    UIPasteboard.general.url = url
                    wself.delegate?.tabPeekDidCopyUrl()
                })
            }
        }
        actions.append(UIPreviewAction(title: .TabPeekCloseTab, style: .destructive) { [weak self] previewAction, viewController in
            guard let wself = self, let tab = wself.tab else { return }
            wself.delegate?.tabPeekDidCloseTab(tab)
        })

        return actions
    }()

    func contextActions(defaultActions: [UIMenuElement]) -> UIMenu {
        var actions = [UIAction]()

        let urlIsTooLongToSave = self.tab?.urlIsTooLong ?? false
        let isHomeTab = self.tab?.isFxHomeTab ?? false
        if !self.ignoreURL && !urlIsTooLongToSave {
            if !self.isBookmarked && !isHomeTab {
                actions.append(UIAction(title: .TabPeekAddToBookmarks,
                                        image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.bookmark),
                                        identifier: nil) { [weak self] _ in
                    guard let wself = self, let tab = wself.tab else { return }
                    wself.delegate?.tabPeekDidAddBookmark(tab)
                })
            }
            if self.hasRemoteClients {
                actions.append(UIAction(title: .AppMenu.TouchActions.SendToDeviceTitle, image: UIImage.templateImageNamed("menu-Send"), identifier: nil) { [weak self] _ in
                    guard let wself = self, let clientPicker = wself.fxaDevicePicker else { return }
                    wself.delegate?.tabPeekRequestsPresentationOf(clientPicker)
                })
            }
            actions.append(UIAction(title: .TabPeekCopyUrl,
                                    image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.link),
                                    identifier: nil) { [weak self] _ in
                guard let wself = self, let url = wself.tab?.canonicalURL else { return }

                UIPasteboard.general.url = url
                wself.delegate?.tabPeekDidCopyUrl()
            })
        }
        actions.append(UIAction(title: .TabPeekCloseTab,
                                image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.cross),
                                identifier: nil) { [weak self] _ in
            guard let wself = self, let tab = wself.tab else { return }
            wself.delegate?.tabPeekDidCloseTab(tab)
        })

        return UIMenu(title: "", children: actions)
    }

    init(tab: Tab, delegate: TabPeekDelegate?) {
        self.tab = tab
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        webView?.navigationDelegate = nil
        self.webView = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let webViewAccessibilityLabel = tab?.webView?.accessibilityLabel {
            previewAccessibilityLabel = String(format: .TabPeekPreviewAccessibilityLabel, webViewAccessibilityLabel)
        }
        // if there is no screenshot, load the URL in a web page
        // otherwise just show the screenshot
        if let screenshot = tab?.screenshot {
            setupWithScreenshot(screenshot)
        } else {
            setupWebView(tab?.webView)
        }
    }

    private func setupWithScreenshot(_ screenshot: UIImage) {
        let imageView = UIImageView(image: screenshot)
        self.view.addSubview(imageView)

        imageView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }

        screenShot = imageView
        screenShot?.accessibilityLabel = previewAccessibilityLabel
    }

    private func setupWebView(_ webView: WKWebView?) {
        guard let webView = webView,
              let url = webView.url,
              !isIgnoredURL(url)
        else { return }

        let clonedWebView = WKWebView(frame: webView.frame, configuration: webView.configuration)
        clonedWebView.allowsLinkPreview = false
        clonedWebView.accessibilityLabel = previewAccessibilityLabel
        self.view.addSubview(clonedWebView)

        clonedWebView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }

        clonedWebView.navigationDelegate = self
        self.webView = clonedWebView
        clonedWebView.load(URLRequest(url: url))
    }

    func setState(withProfile browserProfile: BrowserProfile,
                  clientPickerDelegate: DevicePickerViewControllerDelegate) {
        guard let tab = self.tab,
              let displayURL = tab.url?.absoluteString,
              !displayURL.isEmpty
        else { return }

        ensureMainThread { [weak self] in
            guard let self = self else { return }

            browserProfile.places.isBookmarked(url: displayURL) >>== { isBookmarked in
                self.isBookmarked = isBookmarked
            }
            browserProfile.tabs.getClientGUIDs { (result, error) in
                guard let clientGUIDs = result else { return }

                self.hasRemoteClients = !clientGUIDs.isEmpty

                DispatchQueue.main.async {
                    self.createDevicePicker(withProfile: browserProfile,
                                            clientPickerDelegate: clientPickerDelegate)
                }
            }

            let result = browserProfile.readingList.getRecordWithURL(displayURL).value.successValue

            self.isInReadingList = !(result?.url.isEmpty ?? true)
            self.ignoreURL = isIgnoredURL(displayURL)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        screenShot?.removeFromSuperview()
        screenShot = nil
    }

    private func createDevicePicker(withProfile browserProfile: BrowserProfile,
                                    clientPickerDelegate: DevicePickerViewControllerDelegate) {
            let clientPickerController = DevicePickerViewController(profile: browserProfile)
            clientPickerController.pickerDelegate = clientPickerDelegate
            clientPickerController.profile = browserProfile
            if let url = tab?.url?.absoluteString {
                clientPickerController.shareItem = ShareItem(url: url, title: tab?.title ?? "")
            }
            self.fxaDevicePicker = UINavigationController(rootViewController: clientPickerController)
    }
}
