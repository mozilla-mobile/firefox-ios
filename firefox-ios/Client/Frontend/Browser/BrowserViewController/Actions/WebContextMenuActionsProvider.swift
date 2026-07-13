// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import WebKit
import Photos
import Shared
import Storage

@MainActor
class WebContextMenuActionsProvider {
    enum MenuType {
        case web
        case image
    }

    private var actions = [UIAction]()
    private let menuType: MenuType

    private var telemetryOrigin: ContextMenuTelemetry.OriginExtra {
        menuType == .image ? .imageLink : .webLink
    }

    init(menuType: MenuType) {
        self.menuType = menuType
    }

    func build() -> [UIAction] {
        return actions
    }

    @MainActor
    func addOpenInNewTab(url: URL, currentTab: Tab, addTab: @escaping @MainActor (URL, Bool, Tab) -> Void) {
        let origin = telemetryOrigin
        actions.append(
            UIAction(
                title: .ContextMenuOpenInNewTab,
                image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.plus),
                identifier: UIAction.Identifier(rawValue: "linkContextMenu.openInNewTab")
            ) { [weak currentTab] _ in
                guard let currentTab else { return }
                addTab(url, false, currentTab)
                Self.recordOptionSelectedTelemetry(option: .openInNewTab, originExtra: origin)
            })
    }

    @MainActor
    func addOpenInNewPrivateTab(url: URL, currentTab: Tab, addTab: @escaping @MainActor (URL, Bool, Tab) -> Void) {
        let origin = telemetryOrigin
        actions.append(
            UIAction(
                title: .ContextMenuOpenInNewPrivateTab,
                image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.privateMode),
                identifier: UIAction.Identifier("linkContextMenu.openInNewPrivateTab")
            ) { [weak currentTab] _ in
                guard let currentTab else { return }
                addTab(url, true, currentTab)
                Self.recordOptionSelectedTelemetry(option: .openInNewPrivateTab, originExtra: origin)
            })
    }

    @MainActor
    func addBookmarkLink(url: URL, title: String?, addBookmark: @escaping (String, String?, Site?) -> Void) {
        let origin = telemetryOrigin
        actions.append(
            UIAction(
                title: .ContextMenuBookmarkLink,
                image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.bookmark),
                identifier: UIAction.Identifier("linkContextMenu.bookmarkLink")
            ) { _ in
                addBookmark(url.absoluteString, title, nil)
                Self.recordOptionSelectedTelemetry(option: .bookmarkLink, originExtra: origin)
                BookmarksTelemetry().addBookmark(eventLabel: .pageActionMenu)
            }
        )
    }

    @MainActor
    func addRemoveBookmarkLink(
        urlString: String,
        title: String?,
        removeBookmark: @escaping (
            String,
            String?,
            Site?
        ) -> Void) {
        let origin = telemetryOrigin
        actions.append(
            UIAction(
                title: .RemoveBookmarkContextMenuTitle,
                image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.cross),
                identifier: UIAction.Identifier("linkContextMenu.removeBookmarkLink")
            ) { _ in
                removeBookmark(urlString, title, nil)
                Self.recordOptionSelectedTelemetry(option: .removeBookmark, originExtra: origin)
                BookmarksTelemetry().deleteBookmark(eventLabel: .pageActionMenu)
            }
        )
    }

    @MainActor
    func addDownload(url: URL, currentTab: Tab, assignWebView: @escaping (WKWebView?) -> Void) {
        let origin = telemetryOrigin
        actions.append(UIAction(
            title: .ContextMenuDownloadLink,
            image: UIImage.templateImageNamed(
                StandardImageIdentifiers.Large.download
            ),
            identifier: UIAction.Identifier("linkContextMenu.download")
        ) { [weak currentTab] _ in
            ensureMainThread {
                guard let currentTab else { return }
                // This checks if download is a blob, if yes, begin blob download process
                if !DownloadContentScript.requestBlobDownload(url: url, tab: currentTab) {
                    // if not a blob, set pendingDownloadWebView and load the request in
                    // the webview, which will trigger the WKWebView navigationResponse
                    // delegate function and eventually downloadHelper.open()
                    assignWebView(currentTab.webView)
                    let request = URLRequest(url: url)
                    currentTab.webView?.load(request)
                    Self.recordOptionSelectedTelemetry(option: .downloadLink, originExtra: origin)
                }
            }
        })
    }

    @MainActor
    func addCopyLink(url: URL) {
        let origin = telemetryOrigin
        actions.append(UIAction(
            title: .ContextMenuCopyLink,
            image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.link),
            identifier: UIAction.Identifier("linkContextMenu.copyLink")
        ) { _ in
            UIPasteboard.general.url = url
            Self.recordOptionSelectedTelemetry(option: .copyLink, originExtra: origin)
        })
    }

    @MainActor
    func addShare(url: URL,
                  tabManager: TabManager,
                  webView: WKWebView,
                  view: UIView,
                  navigationHandler: BrowserNavigationHandler?,
                  contentContainer: ContentContainer) {
        let origin = telemetryOrigin
        actions.append(UIAction(
            title: .ContextMenuShareLink,
            image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.shareApple),
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
            Self.recordOptionSelectedTelemetry(option: .shareLink, originExtra: origin)
        })
    }

    @MainActor
    func addSaveImage(url: URL,
                      getImageData: @escaping (URL, @escaping @MainActor @Sendable (Data) -> Void) -> Void,
                      writeToPhotoAlbum: @escaping @MainActor (UIImage) -> Void) {
        let origin = telemetryOrigin
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
                    ensureMainThread {
                        guard let image = UIImage(data: data) else { return }
                        writeToPhotoAlbum(image)
                    }
                }
            }
            Self.recordOptionSelectedTelemetry(option: .saveImage, originExtra: origin)
        })
    }

    @MainActor
    func addSearchWithGoogleLens(url: URL, searchGoogleLens: @escaping @MainActor (URL) -> Void) {
        let origin = telemetryOrigin
        actions.append(UIAction(
            title: .ContextMenuGoogleLens,
            image: UIImage.templateImageNamed(StandardImageIdentifiers.Medium.logoGoogleLens),
            identifier: UIAction.Identifier("linkContextMenu.googleLens")
        ) { _ in
            searchGoogleLens(url)
            Self.recordOptionSelectedTelemetry(option: .googleLens, originExtra: origin)
        })
    }

    @MainActor
    func addCopyImage(url: URL) {
        let origin = telemetryOrigin
        // The handler captures values only, never `self`. The provider is deallocated as soon as the menu is built,
        // so capturing `self` would drop the telemetry and abort the copy once the handler runs
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

            // Held in a reference so the same identifier is shared between the expiration
            // handler and the network completion without capturing the (short-lived) provider.
            let backgroundTask = BackgroundTaskHolder()
            backgroundTask.id = application.beginBackgroundTask(expirationHandler: {
                application.endBackgroundTask(backgroundTask.id)
                backgroundTask.id = .invalid
            })

            makeURLSession(
                userAgent: UserAgent.fxaUserAgent,
                configuration: URLSessionConfiguration.defaultMPTCP
            ).dataTask(with: url) { (data, response, error) in
                ensureMainThread {
                    guard validatedHTTPResponse(response, statusCode: 200..<300) != nil else {
                        application.endBackgroundTask(backgroundTask.id)
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

                    application.endBackgroundTask(backgroundTask.id)
                }
            }.resume()
            Self.recordOptionSelectedTelemetry(option: .copyImage, originExtra: origin)
        })
    }

    @MainActor
    func addCopyImageLink(url: URL) {
        let origin = telemetryOrigin
        actions.append(UIAction(
            title: .ContextMenuCopyImageLink,
            identifier: UIAction.Identifier("linkContextMenu.copyImageLink")
        ) { _ in
            UIPasteboard.general.url = url as URL
            Self.recordOptionSelectedTelemetry(option: .copyImageLink, originExtra: origin)
        })
    }

    private static func recordOptionSelectedTelemetry(option: ContextMenuTelemetry.OptionExtra,
                                                      originExtra: ContextMenuTelemetry.OriginExtra) {
        ContextMenuTelemetry().optionSelected(option: option, origin: originExtra)
    }
}

/// Holds a background task identifier by reference so it can be shared between the
/// `beginBackgroundTask` expiration handler and the network completion handler.
private final class BackgroundTaskHolder: @unchecked Sendable {
    var id: UIBackgroundTaskIdentifier = .invalid
}
