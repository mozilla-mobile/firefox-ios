// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import WebKit
import Photos
import Shared
import Storage

class WebContextMenuActionsProvider {
    enum MenuType {
        case web
        case image
    }

    private var actions = [UIAction]()
    private var taskId = UIBackgroundTaskIdentifier(rawValue: 0)
    private let menuType: MenuType

    init(menuType: MenuType) {
        self.menuType = menuType
    }

    func build() -> [UIAction] {
        return actions
    }

    func addOpenInNewTab(url: URL, currentTab: Tab, addTab: @escaping (URL, Bool, Tab) -> Void) {
        actions.append(
            UIAction(
                title: .ContextMenuOpenInNewTab,
                image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.plus),
                identifier: UIAction.Identifier(rawValue: "linkContextMenu.openInNewTab")
            ) { _ in
                addTab(url, false, currentTab)
                self.recordOptionSelectedTelemetry(option: .openInNewTab)
            })
    }

    func addOpenInNewPrivateTab(url: URL, currentTab: Tab, addTab: @escaping (URL, Bool, Tab) -> Void) {
        actions.append(
            UIAction(
                title: .ContextMenuOpenInNewPrivateTab,
                image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.privateMode),
                identifier: UIAction.Identifier("linkContextMenu.openInNewPrivateTab")
            ) { _ in
                addTab(url, true, currentTab)
                self.recordOptionSelectedTelemetry(option: .openInNewPrivateTab)
            })
    }

    func addBookmarkLink(url: URL, title: String?, addBookmark: @escaping (String, String?, Site?) -> Void) {
        actions.append(
            UIAction(
                title: .ContextMenuBookmarkLink,
                image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.bookmark),
                identifier: UIAction.Identifier("linkContextMenu.bookmarkLink")
            ) { _ in
                addBookmark(url.absoluteString, title, nil)
                self.recordOptionSelectedTelemetry(option: .bookmarkLink)
                BookmarksTelemetry().addBookmark(eventLabel: .pageActionMenu)
            }
        )
    }

    func addRemoveBookmarkLink(
        urlString: String,
        title: String?,
        removeBookmark: @escaping (
            String,
            String?,
            Site?
        ) -> Void) {
        actions.append(
            UIAction(
                title: .RemoveBookmarkContextMenuTitle,
                image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.cross),
                identifier: UIAction.Identifier("linkContextMenu.removeBookmarkLink")
            ) { _ in
                removeBookmark(urlString, title, nil)
                self.recordOptionSelectedTelemetry(option: .removeBookmark)
                BookmarksTelemetry().deleteBookmark(eventLabel: .pageActionMenu)
            }
        )
    }

    func addDownload(url: URL, currentTab: Tab, assignWebView: @escaping (WKWebView?) -> Void) {
        actions.append(UIAction(
            title: .ContextMenuDownloadLink,
            image: UIImage.templateImageNamed(
                StandardImageIdentifiers.Large.download
            ),
            identifier: UIAction.Identifier("linkContextMenu.download")
        ) { _ in
            // This checks if download is a blob, if yes, begin blob download process
            if !DownloadContentScript.requestBlobDownload(url: url, tab: currentTab) {
                // if not a blob, set pendingDownloadWebView and load the request in
                // the webview, which will trigger the WKWebView navigationResponse
                // delegate function and eventually downloadHelper.open()
                assignWebView(currentTab.webView)
                let request = URLRequest(url: url)
                currentTab.webView?.load(request)
                self.recordOptionSelectedTelemetry(option: .downloadLink)
            }
        })
    }

    func addCopyLink(url: URL) {
        actions.append(UIAction(
            title: .ContextMenuCopyLink,
            image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.link),
            identifier: UIAction.Identifier("linkContextMenu.copyLink")
        ) { _ in
            UIPasteboard.general.url = url
            self.recordOptionSelectedTelemetry(option: .copyLink)
        })
    }

    func addShare(url: URL,
                  tabManager: TabManager,
                  webView: WKWebView,
                  view: UIView,
                  navigationHandler: BrowserNavigationHandler?,
                  contentContainer: ContentContainer) {
        actions.append(UIAction(
            title: .ContextMenuShareLink,
            image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.share),
            identifier: UIAction.Identifier("linkContextMenu.share")
        ) { _ in
            guard let tab = tabManager[webView],
                  let helper = tab.getContentScript(name: ContextMenuHelper.name()) as? ContextMenuHelper
            else { return }

            // The `point` is only used on ipad for positioning the popover. On iPhone it is an bottom sheet.
            let point = webView.convert(helper.touchPoint, to: view)

            // Shares from long-pressing a link in the webview and tapping Share in the context menu
            navigationHandler?.showShareSheet(
                shareType: .site(url: url), // NOT `.tab` share; the link might be to a different domain from the current tab
                shareMessage: nil,
                sourceView: view,
                sourceRect: CGRect(origin: point, size: CGSize(width: 10.0, height: 10.0)),
                toastContainer: contentContainer,
                popoverArrowDirection: .unknown
            )
            self.recordOptionSelectedTelemetry(option: .shareLink)
        })
    }

    func addSaveImage(url: URL,
                      getImageData: @escaping (URL, @escaping (Data) -> Void) -> Void,
                      writeToPhotoAlbum: @escaping (UIImage) -> Void) {
        actions.append(UIAction(
            title: .ContextMenuSaveImage,
            identifier: UIAction.Identifier("linkContextMenu.saveImage")
        ) { _ in
            getImageData(url) { data in
                if url.pathExtension.lowercased() == "gif" {
                    PHPhotoLibrary.shared().performChanges {
                        let creationRequest = PHAssetCreationRequest.forAsset()
                        creationRequest.addResource(with: .photo, data: data, options: nil)
                    }
                } else {
                    guard let image = UIImage(data: data) else { return }
                    writeToPhotoAlbum(image)
                }
            }
            self.recordOptionSelectedTelemetry(option: .saveImage)
        })
    }

    func addCopyImage(url: URL) {
        actions.append(UIAction(
            title: .ContextMenuCopyImage,
            identifier: UIAction.Identifier("linkContextMenu.copyImage")
        ) { _ in
            // put the actual image on the clipboard
            // do this asynchronously just in case we're in a low bandwidth situation
            let pasteboard = UIPasteboard.general
            pasteboard.url = url as URL
            let changeCount = pasteboard.changeCount
            let application = UIApplication.shared
            self.taskId = application.beginBackgroundTask(expirationHandler: {
                application.endBackgroundTask(self.taskId)
            })

            makeURLSession(
                userAgent: UserAgent.fxaUserAgent,
                configuration: URLSessionConfiguration.defaultMPTCP
            ).dataTask(with: url) { (data, response, error) in
                guard validatedHTTPResponse(response, statusCode: 200..<300) != nil else {
                    application.endBackgroundTask(self.taskId)
                    return
                }

                // Only set the image onto the pasteboard if the pasteboard hasn't changed since
                // fetching the image; otherwise, in low-bandwidth situations,
                // we might be overwriting something that the user has subsequently added.
                if changeCount == pasteboard.changeCount,
                   let imageData = data,
                   error == nil {
                    pasteboard.addImageWithData(imageData, forURL: url)
                }

                application.endBackgroundTask(self.taskId)
            }.resume()
            self.recordOptionSelectedTelemetry(option: .copyImage)
        })
    }

    func addCopyImageLink(url: URL) {
        actions.append(UIAction(
            title: .ContextMenuCopyImageLink,
            identifier: UIAction.Identifier("linkContextMenu.copyImageLink")
        ) { _ in
            UIPasteboard.general.url = url as URL
            self.recordOptionSelectedTelemetry(option: .copyImageLink)
        })
    }

    private func recordOptionSelectedTelemetry(option: ContextMenuTelemetry.OptionExtra) {
        let originExtra = menuType == .image ? ContextMenuTelemetry.OriginExtra.imageLink
                                             : ContextMenuTelemetry.OriginExtra.webLink
        ContextMenuTelemetry().optionSelected(option: option, origin: originExtra)
    }
}
