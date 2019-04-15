/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

/**
 * Data for identifying and constructing a LibraryPanel.
 */
struct LibraryPanelDescriptor {
    let makeViewController: (_ profile: Profile) -> UIViewController
    let imageName: String
    let accessibilityLabel: String
    let accessibilityIdentifier: String
}

class LibraryPanels {
    let enabledPanels = [
        LibraryPanelDescriptor(
            makeViewController: { profile in
                let controller = BookmarksPanel(profile: profile)
                return controller
            },
            imageName: "Bookmarks",
            accessibilityLabel: NSLocalizedString("Bookmarks", comment: "Panel accessibility label"),
            accessibilityIdentifier: "LibraryPanels.Bookmarks"),

        LibraryPanelDescriptor(
            makeViewController: { profile in
                let controller = HistoryPanel(profile: profile)
                return controller
            },
            imageName: "History",
            accessibilityLabel: NSLocalizedString("History", comment: "Panel accessibility label"),
            accessibilityIdentifier: "LibraryPanels.History"),

        LibraryPanelDescriptor(
            makeViewController: { profile in
                let controller = ReadingListPanel(profile: profile)
                return controller
            },
            imageName: "ReadingList",
            accessibilityLabel: NSLocalizedString("Reading list", comment: "Panel accessibility label"),
            accessibilityIdentifier: "LibraryPanels.ReadingList"),

        LibraryPanelDescriptor(
            makeViewController: { profile in
                let controller = DownloadsPanel(profile: profile)
                return controller
            },
            imageName: "Downloads",
            accessibilityLabel: NSLocalizedString("Downloads", comment: "Panel accessibility label"),
            accessibilityIdentifier: "LibraryPanels.Downloads"),
        ]
}
