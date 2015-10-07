/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

/**
 * Data for identifying and constructing a HomePanel.
 */
struct HomePanelDescriptor {
    let makeViewController: (profile: Profile) -> UIViewController
    let imageName: String
    let accessibilityLabel: String
}

class HomePanels {
    let enabledPanels = [
        HomePanelDescriptor(
            makeViewController: { profile in
                TopSitesPanel(profile: profile)
            },
            imageName: "TopSites",
            accessibilityLabel: NSLocalizedString("Top sites", comment: "Panel accessibility label")),

        HomePanelDescriptor(
            makeViewController: { profile in
                let bookmarks = BookmarksPanel()
                bookmarks.profile = profile
                let controller = UINavigationController(rootViewController: bookmarks)
                controller.setNavigationBarHidden(true, animated: false)
                return controller
            },
            imageName: "Bookmarks",
            accessibilityLabel: NSLocalizedString("Bookmarks", comment: "Panel accessibility label")),

        HomePanelDescriptor(
            makeViewController: { profile in
                let controller = HistoryPanel()
                controller.profile = profile
                return controller
            },
            imageName: "History",
            accessibilityLabel: NSLocalizedString("History", comment: "Panel accessibility label")),

        HomePanelDescriptor(
            makeViewController: { profile in
                let controller = RemoteTabsPanel()
                controller.profile = profile
                return controller
            },
            imageName: "SyncedTabs",
            accessibilityLabel: NSLocalizedString("Synced tabs", comment: "Panel accessibility label")),

        HomePanelDescriptor(
            makeViewController: { profile in
                let controller = ReadingListPanel()
                controller.profile = profile
                return controller
            },
            imageName: "ReadingList",
            accessibilityLabel: NSLocalizedString("Reading list", comment: "Panel accessibility label")),
    ]
}
