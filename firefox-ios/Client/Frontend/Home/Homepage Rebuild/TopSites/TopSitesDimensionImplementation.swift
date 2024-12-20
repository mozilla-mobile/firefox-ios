// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

class TopSitesDimensionImplementation {
    var currentCount: Int? {
        willSet {
            guard newValue != currentCount else { return }
            DispatchQueue.main.async {
                store.dispatch(
                    TopSitesAction(
                        numberOfTilesPerRow: newValue,
                        windowUUID: self.windowUUID,
                        actionType: TopSitesActionType.updatedNumberOfTilesPerRow
                    )
                )
            }
        }
    }
    private let windowUUID: WindowUUID
    init(windowUUID: WindowUUID) {
        self.windowUUID = windowUUID
    }

    /// Updates the number of tiles (top sites) per row the user will see. This depends on the UI interface the user has.
    /// - Parameter availableWidth: available width size depending on device
    /// - Parameter leadingInset: padding for top site section
    /// - Parameter cellWidth: width of individual top site tiles
    func updateNumberOfTilesPerRow(availableWidth: CGFloat, leadingInset: CGFloat, cellWidth: CGFloat) {
        var availableWidth = availableWidth - leadingInset * 2
        var numberOfTiles = 0

        while availableWidth > cellWidth {
            numberOfTiles += 1
            availableWidth = availableWidth - cellWidth - HomepageSectionLayoutProvider.UX.standardSpacing
        }
        let minCardsConstant = HomepageSectionLayoutProvider.UX.TopSitesConstants.minCards
        let numberOfTilesPerRow = numberOfTiles < minCardsConstant ? minCardsConstant : numberOfTiles

        self.currentCount = numberOfTilesPerRow
    }
}
