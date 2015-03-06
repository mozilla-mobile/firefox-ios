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
                let controller = TopSitesPanel()
                controller.profile = profile
                return controller
            },
            imageName: "tabs",
            accessibilityLabel: NSLocalizedString("Top sites", comment: "Panel accessibility label")),

        HomePanelDescriptor(
            makeViewController: { profile in
                let controller = BookmarksPanel()
                controller.profile = profile
                return controller
            },
            imageName: "bookmarks",
            accessibilityLabel: NSLocalizedString("Bookmarks", comment: "Panel accessibility label")),

        HomePanelDescriptor(
            makeViewController: { profile in
                let controller = HistoryPanel()
                controller.profile = profile
                return controller
            },
            imageName: "history",
            accessibilityLabel: NSLocalizedString("History", comment: "Panel accessibility label")),

        HomePanelDescriptor(
            makeViewController: { profile in
                let controller = ReaderPanel()
                controller.profile = profile
                return controller
            },
            imageName: "reader",
            accessibilityLabel: NSLocalizedString("Reading list", comment: "Panel accessibility label")),
    ]
}
