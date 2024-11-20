// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import WebKit
import Common

/**
 * Handles screenshots for a given tab, including pages with non-webview content.
 */
class ScreenshotHelper {
    fileprivate weak var controller: BrowserViewController?
    private let logger: Logger

    init(controller: BrowserViewController,
         logger: Logger = DefaultLogger.shared) {
        self.controller = controller
        self.logger = logger
    }

    /// Takes a screenshot of the WebView to be displayed on the tab view page
    /// If taking a screenshot of the home page, uses our custom screenshot `UIView` extension function
    /// If taking a screenshot of a website, uses apple's `takeSnapshot` function
    func takeScreenshot(_ tab: Tab) {
        guard let webView = tab.webView else {
            logger.log("Tab Snapshot Error",
                       level: .debug,
                       category: .tabs,
                       description: "Tab webView or url is nil")
            return
        }
        /// Handle home page snapshots, can not use Apple API snapshot function for this
        guard controller != nil else { return }

        /// Added check for native error pages.
        let isNativeErrorPage = controller?.contentContainer.hasNativeErrorPage ?? false
        /// If the tab is the homepage, take a screenshot of the homepage view.
        /// This is done by accessing the content view from the content container.
        /// The screenshot is then set for the tab, and a TabEvent is posted to indicate
        /// that a screenshot has been set for the homepage.
        if tab.isFxHomeTab || isNativeErrorPage {
            if let homeview = controller?.contentContainer.contentView {
                let screenshot = homeview.screenshot(quality: UIConstants.ActiveScreenshotQuality)
                tab.hasHomeScreenshot = true
                tab.setScreenshot(screenshot)
                TabEvent.post(.didSetScreenshot(isHome: true), for: tab)
            }
        // Handle webview screenshots
        } else {
            let configuration = WKSnapshotConfiguration()
            // This is for a bug in certain iOS 13 versions, snapshots cannot be taken
            // correctly without this boolean being set
            configuration.afterScreenUpdates = false
            configuration.snapshotWidth = 320

            webView.takeSnapshot(with: configuration) { image, error in
                if let image = image {
                    tab.hasHomeScreenshot = false
                    tab.setScreenshot(image)
                    TabEvent.post(.didSetScreenshot(isHome: false), for: tab)
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
