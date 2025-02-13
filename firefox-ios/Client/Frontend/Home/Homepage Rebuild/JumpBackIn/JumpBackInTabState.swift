// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

struct JumpBackInTabConfiguration: Equatable, Hashable {
    let tabUUID: String
    let titleText: String
    let descriptionText: String
    let siteURL: String
    var accessibilityLabel: String {
        return "\(titleText), \(descriptionText)"
    }
}

struct JumpBackInSyncedTabConfiguration: Equatable, Hashable {
    let titleText: String
    let descriptionText: String
    let url: URL
    var syncedDeviceImage: UIImage? {
        return UIImage(named: StandardImageIdentifiers.Large.syncTabs)
    }
    var accessibilityLabel: String {
        return "\(cardTitleText): \(titleText), \(descriptionText)"
    }
    var cardTitleText: String {
        return .FirefoxHomepage.JumpBackIn.SyncedTabTitle
    }
    var syncedTabsButtonText: String {
        return .FirefoxHomepage.JumpBackIn.SyncedTabShowAllButtonTitle
    }
    var syncedTabOpenActionTitle: String {
        return .FirefoxHomepage.JumpBackIn.SyncedTabOpenTabA11y
    }
}

/// Configuration for the "Jump Back In" section layout.
/// Determines the maximum number of local tabs to display based on whether a synced (remote) tab is present.
struct JumpBackInSectionLayoutConfiguration: Equatable, Hashable {
    /// Maximum number of local tabs to display when a synced (remote) tab is present.
    let maxLocalTabsWhenSyncedTabExists: Int

    /// Maximum number of local tabs to display when no synced (remote) tab is present.
    let maxLocalTabsWhenNoSyncedTab: Int

    let layoutType: LayoutType

    var hasSyncedTab: Bool?

    enum LayoutType: Equatable, Hashable {
        case compact
        case medium
        case regular
    }

    /// Computes the maximum number of local tabs to display based on the presence of a synced tab.
    var getMaxNumberOfLocalTabsLayout: Int {
        return hasSyncedTab ?? false ? maxLocalTabsWhenSyncedTabExists : maxLocalTabsWhenNoSyncedTab
    }
}
