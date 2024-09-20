// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import WebKit
import Photos
import Shared

class ActionProviderBuilder {
    private var actions = [UIAction]()
    private var taskId = UIBackgroundTaskIdentifier(rawValue: 0)

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
            })
    }

    func addBookmarkLink(url: URL, title: String?, addBookmark: @escaping (String, String?) -> Void) {
        actions.append(
            UIAction(
                title: .ContextMenuBookmarkLink,
                image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.bookmark),
                identifier: UIAction.Identifier("linkContextMenu.bookmarkLink")
            ) { _ in
                addBookmark(url.absoluteString, title)
                TelemetryWrapper.recordEvent(category: .action,
                                             method: .add,
                                             object: .bookmark,
                                             value: .contextMenu)
            }
        )
    }

    func addRemoveBookmarkLink(url: URL, title: String?, removeBookmark: @escaping (URL, String?) -> Void) {
        actions.append(
            UIAction(
                title: .RemoveBookmarkContextMenuTitle,
                image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.cross),
                identifier: UIAction.Identifier("linkContextMenu.removeBookmarkLink")
            ) { _ in
                removeBookmark(url, title)
                TelemetryWrapper.recordEvent(category: .action,
                                             method: .delete,
                                             object: .bookmark,
                                             value: .contextMenu)
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

            // This is only used on ipad for positioning the popover. On iPhone it is an action sheet.
            let point = webView.convert(helper.touchPoint, to: view)
            navigationHandler?.showShareExtension(
                url: url,
                sourceView: view,
                sourceRect: CGRect(origin: point, size: CGSize(width: 10.0, height: 10.0)),
                toastContainer: contentContainer,
                popoverArrowDirection: .unknown
            )
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
                configuration: URLSessionConfiguration.default
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
        })
    }

    func addCopyImageLink(url: URL) {
        actions.append(UIAction(
            title: .ContextMenuCopyImageLink,
            identifier: UIAction.Identifier("linkContextMenu.copyImageLink")
        ) { _ in
            UIPasteboard.general.url = url as URL
        })
    }
}
