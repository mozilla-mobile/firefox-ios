// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// Data for identifying and constructing a LibraryPanel.
class LibraryPanelDescriptor {
    var viewController: UIViewController?
    var navigationController: UINavigationController?

    private let profile: Profile
    private let tabManager: TabManager

    let accessibilityLabel: String
    let accessibilityIdentifier: String
    let panelType: LibraryPanelType

    // Returns latest libraryPanel viewController filtering out "details view controllers" from navigationController
    // Handles Bookmarks case where BookmarksPanel is used for main folder and subfolder state
    var shownPanel: UIViewController? {
        let libraryPanel = navigationController?.viewControllers.filter { $0 is LibraryPanel }
        return libraryPanel?.last
    }

    init(viewController: LibraryPanel?,
         profile: Profile,
         tabManager: TabManager,
         accessibilityLabel: String,
         accessibilityIdentifier: String,
         panelType: LibraryPanelType) {
        self.viewController = viewController
        self.profile = profile
        self.tabManager = tabManager
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityIdentifier = accessibilityIdentifier
        self.panelType = panelType
    }
}
