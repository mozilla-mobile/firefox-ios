/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

/**
 * Data for identifying and constructing a HomePanel.
 */
struct HomePanelDescriptor {
    let makeViewController: (_ profile: Profile) -> UIViewController
    let imageName: String
    let accessibilityLabel: String
    let accessibilityIdentifier: String
}

class HomePanels {
    let enabledPanels = [
        HomePanelDescriptor(
            makeViewController: { profile in
                let bookmarks = BookmarksPanel(profile: profile)
                let controller = UINavigationController(rootViewController: bookmarks)
                controller.setNavigationBarHidden(true, animated: false)
                // this re-enables the native swipe to pop gesture on UINavigationController for embedded, navigation bar-less UINavigationControllers
                // don't ask me why it works though, I've tried to find an answer but can't.
                // found here, along with many other places:
                // http://luugiathuy.com/2013/11/ios7-interactivepopgesturerecognizer-for-uinavigationcontroller-with-hidden-navigation-bar/
                controller.interactivePopGestureRecognizer?.delegate = nil
                return controller
            },
            imageName: "Bookmarks",
            accessibilityLabel: NSLocalizedString("Bookmarks", comment: "Panel accessibility label"),
            accessibilityIdentifier: "HomePanels.Bookmarks"),

        HomePanelDescriptor(
            makeViewController: { profile in
                let history = HistoryPanel(profile: profile)
                let controller = UINavigationController(rootViewController: history)
                controller.setNavigationBarHidden(true, animated: false)
                controller.interactivePopGestureRecognizer?.delegate = nil
                return controller
            },
            imageName: "History",
            accessibilityLabel: NSLocalizedString("History", comment: "Panel accessibility label"),
            accessibilityIdentifier: "HomePanels.History"),

        HomePanelDescriptor(
            makeViewController: { profile in
                let controller = ReadingListPanel(profile: profile)
                return controller
            },
            imageName: "ReadingList",
            accessibilityLabel: NSLocalizedString("Reading list", comment: "Panel accessibility label"),
            accessibilityIdentifier: "HomePanels.ReadingList"),

        HomePanelDescriptor(
            makeViewController: { profile in
                let controller = DownloadsPanel(profile: profile)
                return controller
            },
            imageName: "Downloads",
            accessibilityLabel: NSLocalizedString("Downloads", comment: "Panel accessibility label"),
            accessibilityIdentifier: "HomePanels.Downloads"),
        ]
}
