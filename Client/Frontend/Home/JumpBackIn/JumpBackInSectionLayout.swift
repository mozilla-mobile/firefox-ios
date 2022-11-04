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

    // The width dimension of a cell / group; takes into account how many groups will be displayed
    var widthDimension: NSCollectionLayoutDimension {
        switch self {
        case .compactJumpBackIn, .compactSyncedTab, .compactJumpBackInAndSyncedTab:
            // When the trailing inset will be handled by the section layout, this can be set to .fractionalWidth(1)
            return .fractionalWidth(0.95)
        case .regular, .regularWithSyncedTab:
            return UIDevice.current.userInterfaceIdiom == .pad ?
                .fractionalWidth(7.66/24) : .fractionalWidth(7.8/16) // iPad or iPhone in landscape
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
        case .regular:
            return indexPath.row
        case .regularWithSyncedTab:
            return indexPath.row == 0 ? nil : indexPath.row - 1
        }
    }

    // The maximum number of items to display in the whole section
    func maxItemsToDisplay(hasAccount: Bool,
                           device: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom
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
        case .regular:
            return device == .pad ? 6 : 4 // iPad or iPhone in landscape
        case .regularWithSyncedTab:
            return device == .pad ? 4 : 2 // iPad or iPhone in landscape
        }
    }
}
