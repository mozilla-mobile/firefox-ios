// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct JumpBackInDisplayGroupCount {
    var tabsCount: Int
    var syncedTabCount: Int
}

enum JumpBackInSectionLayout: Equatable {
    case compactJumpBackIn // just JumpBackIn is displayed
    case compactSyncedTab // just synced tab is displayed
    case compactJumpBackInAndSyncedTab // jumpBackIn is displayed first and then synced tab
    case regular // only jumpBackIn
    case regularWithSyncedTab // synced tab is displayed first and then jumpBackIn

    // iPad in portrait or iPad with 2/3 split screen or iPhone in landscape
    case medium // only jumpBackIn
    case mediumWithSyncedTab // synced tab is displayed first and then jumpBackIn

    // The width dimension of a cell / group; takes into account how many groups will be displayed
    var widthDimension: NSCollectionLayoutDimension {
        switch self {
        case .compactJumpBackIn, .compactSyncedTab, .compactJumpBackInAndSyncedTab:
            // When the trailing inset will be handled by the section layout, this can be set to .fractionalWidth(1)
            return .fractionalWidth(0.95)
        case .regular, .regularWithSyncedTab:
            // Cards need to be less than 1/3 (8/24) wide to account for spacing.
            return .fractionalWidth(7.66/24)
        case .medium, .mediumWithSyncedTab:
            // Cards need to be less than 1/2 (8/16) wide to account for spacing.
            // On iPhone they need to be slightly wider to match the spacing of the rest of the UI.
            return UIDevice.current.userInterfaceIdiom == .pad ?
                .fractionalWidth(7.66/16) : .fractionalWidth(7.8/16) // iPad or iPhone in landscape
        }
    }

    func indexOfJumpBackInItem(for indexPath: IndexPath) -> Int? {
        switch self {
        case .compactJumpBackIn:
            return indexPath.row
        case .compactSyncedTab:
            return nil
        case .compactJumpBackInAndSyncedTab:
            return indexPath.row == 1 ? nil : indexPath.row
        case .medium, .regular:
            return indexPath.row
        case .mediumWithSyncedTab, .regularWithSyncedTab:
            return indexPath.row == 0 ? nil : indexPath.row - 1
        }
    }

    // The maximum number of items to display in the whole section
    func maxItemsToDisplay(hasAccount: Bool,
                           device: UIUserInterfaceIdiom
    ) -> JumpBackInDisplayGroupCount {
        return JumpBackInDisplayGroupCount(
            tabsCount: maxJumpBackInItemsToDisplay(device: device),
            syncedTabCount: hasAccount ? JumpBackInViewModel.UX.maxDisplayedSyncedTabs : 0
        )
    }

    // The maximum number of Jump Back In items to display in the whole section
    private func maxJumpBackInItemsToDisplay(device: UIUserInterfaceIdiom) -> Int {
        switch self {
        case .compactJumpBackIn:
            return 2
        case .compactSyncedTab:
            return 0
        case .compactJumpBackInAndSyncedTab:
            return 1
        case .medium:
            return 4
        case .mediumWithSyncedTab:
            return 2
        case .regular:
            return 6
        case .regularWithSyncedTab:
            return 4
        }
    }
}
