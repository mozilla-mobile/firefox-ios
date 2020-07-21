/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebKit

/**
 * Handles screenshots for a given tab, including pages with non-webview content.
 */
class ScreenshotHelper {
    var viewIsVisible = false

    fileprivate weak var controller: BrowserViewController?

    init(controller: BrowserViewController) {
        self.controller = controller
    }
    
    /// Takes a screenshot of the WebView to be displayed on the tab view page
    /**
     If taking a screenshot of the home page, uses our custom screenshot `UIView` extension function
     If taking a screenshot of a website, uses apple's `takeSnapshot` function
     */
    func takeScreenshot(_ tab: Tab) {
        guard let webView = tab.webView, let url = tab.url else {
            Sentry.shared.send(message: "Tab Snapshot Error", tag: .tabManager, severity: .debug, description: "Tab webView or url is nil")
            return
        }
        //Handle home page snapshots, can not use Apple API snapshot function for this
        if InternalURL(url)?.isAboutHomeURL ?? false {
            if let homePanel = controller?.firefoxHomeViewController {
                let screenshot = homePanel.view.screenshot(quality: UIConstants.ActiveScreenshotQuality)
                tab.setScreenshot(screenshot)
            }
        //Handle webview screenshots
        } else {
            let configuration = WKSnapshotConfiguration()
            //This is for a bug in certain iOS 13 versions, snapshots cannot be taken correctly without this boolean being set
            if #available(iOS 13.0, *) {
                configuration.afterScreenUpdates = false
            }
            webView.takeSnapshot(with: configuration) { image, error in
                if let image = image {
                    tab.setScreenshot(image)
                } else if let error = error {
                    Sentry.shared.send(message: "Tab snapshot error", tag: .tabManager, severity: .debug, description: error.localizedDescription)
                } else {
                    Sentry.shared.send(message: "Tab snapshot error", tag: .tabManager, severity: .debug, description: "No error description")
                }
            }
        }
    }

    /// Takes a screenshot after a small delay.
    /// Trying to take a screenshot immediately after didFinishNavigation results in a screenshot
    /// of the previous page, presumably due to an iOS bug. Adding a brief delay fixes this.
    func takeDelayedScreenshot(_ tab: Tab) {
        let time = DispatchTime.now() + Double(Int64(100 * NSEC_PER_MSEC)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time) {
            // If the view controller isn't visible, the screenshot will be blank.
            // Wait until the view controller is visible again to take the screenshot.
            guard self.viewIsVisible else {
                tab.pendingScreenshot = true
                return
            }

            self.takeScreenshot(tab)
        }
    }

    func takePendingScreenshots(_ tabs: [Tab]) {
        for tab in tabs where tab.pendingScreenshot {
            tab.pendingScreenshot = false
            takeDelayedScreenshot(tab)
        }
    }
}
