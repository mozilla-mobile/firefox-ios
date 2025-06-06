// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
import Common

/**
 * Handles screenshots for a given tab, including pages with non-webview content.
 */
class ScreenshotHelper {
    fileprivate weak var controller: BrowserViewController?
    private let logger: Logger

    private var isIpad: Bool {
        // An additional check for horizontalSizeClass is needed since for iPad in multi windows state
        // the smallest window possible has horizontalSizeClass equal to compact, thus behave like an iPhone.
        return controller?.traitCollection.userInterfaceIdiom == .pad &&
               controller?.traitCollection.horizontalSizeClass == .regular
    }

    init(controller: BrowserViewController,
         logger: Logger = DefaultLogger.shared) {
        self.controller = controller
        self.logger = logger
    }

    /// Takes a screenshot of the WebView to be displayed on the tab view page
    /// If taking a screenshot of the home page, uses our custom screenshot `UIView` extension function
    /// If taking a screenshot of a website, uses apple's `takeSnapshot` function
    func takeScreenshot(_ tab: Tab,
                        windowUUID: WindowUUID,
                        screenshotBounds: CGRect,
                        completion: (() -> Void)? = nil) {
        guard let webView = tab.webView else {
            logger.log("Tab Snapshot Error",
                       level: .debug,
                       category: .tabs,
                       description: "Tab webView or url is nil")
            return
        }
        // Handle home page snapshots, can not use Apple API snapshot function for this
        guard controller != nil else { return }

        // Added check for native error pages.
        let isNativeErrorPage = controller?.contentContainer.hasNativeErrorPage ?? false

        // If the tab is the homepage, take a screenshot of the homepage view.
        // This is done by accessing the content view from the content container.
        // The screenshot is then set for the tab, and a TabEvent is posted to indicate
        // that a screenshot has been set for the homepage.
        if tab.isFxHomeTab {
            // For complex views like homepage the Screenshot tool could be the controller directly
            // so check the contentController first otherwise fallback to the contentView.
            let screenshotTool = controller?.contentContainer.contentController as? Screenshotable
                                 ?? controller?.contentContainer.contentView as? Screenshotable
            if let screenshotTool {
                // apply bounds only for iphone in portrait, as otherwise it results in
                // bad screenshot view port.
                let screenshot: UIImage? = if UIWindow.isPortrait && !isIpad {
                    screenshotTool.screenshot(bounds: screenshotBounds)
                } else {
                    screenshotTool.screenshot(quality: 1.0)
                }
                tab.hasHomeScreenshot = true
                tab.setScreenshot(screenshot)
                store.dispatch(
                    ScreenshotAction(
                        windowUUID: windowUUID,
                        tab: tab,
                        actionType:
                            ScreenshotActionType.screenshotTaken
                    )
                )
                completion?()
            }
            // Handle error page screenshots
        } else if isNativeErrorPage {
            if let view = controller?.contentContainer.contentView {
                let screenshot = view.screenshot(quality: UIConstants.ActiveScreenshotQuality)
                tab.hasHomeScreenshot = false
                tab.setScreenshot(screenshot)
                store.dispatch(
                    ScreenshotAction(
                        windowUUID: windowUUID,
                        tab: tab,
                        actionType:
                            ScreenshotActionType.screenshotTaken
                    )
                )
                completion?()
            }
            // Handle webview screenshots
        } else {
            let configuration = WKSnapshotConfiguration()
            configuration.afterScreenUpdates = true

            // apply bounds only for iphone in portrait, as otherwise it results in
            // bad screenshot view port.
            if UIWindow.isPortrait && !isIpad {
                configuration.rect = screenshotBounds
            }

            webView.takeSnapshot(with: configuration) { image, error in
                if let image {
                    tab.hasHomeScreenshot = false
                    tab.setScreenshot(image)
                    store.dispatch(
                        ScreenshotAction(
                            windowUUID: windowUUID,
                            tab: tab,
                            actionType:
                                ScreenshotActionType.screenshotTaken
                        )
                    )
                    completion?()
                } else if let error = error {
                    self.logger.log("Tab Snapshot Error",
                                    level: .debug,
                                    category: .tabs,
                                    description: error.localizedDescription)
                } else {
                    self.logger.log("Tab Snapshot Error",
                                    level: .debug,
                                    category: .tabs,
                                    description: "No error description")
                }
            }
        }
    }
}
