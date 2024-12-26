// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

class TopSitesDimensionImplementation {
    /// The update count of number of tiles per row based on device layout
    /// After updating the value, the top sites state should be updated respectively
    private var numberOfTilesPerRow: Int? {
        willSet {
            guard newValue != numberOfTilesPerRow else { return }
            store.dispatch(
                TopSitesAction(
                    numberOfTilesPerRow: newValue,
                    windowUUID: self.windowUUID,
                    actionType: TopSitesActionType.updatedNumberOfTilesPerRow
                )
            )
        }
    }

    private let windowUUID: WindowUUID
    private let queue: DispatchQueueInterface
    init(windowUUID: WindowUUID, queue: DispatchQueueInterface = DispatchQueue.main) {
        self.windowUUID = windowUUID
        self.queue = queue
    }

    /// Updates the number of tiles (top sites) per row the user will see. This depends on the UI interface the user has.
    /// - Parameter availableWidth: available width size depending on device
    /// - Parameter leadingInset: padding for top site section
    /// - Parameter cellWidth: width of individual top site tiles
    func getNumberOfTilesPerRow(availableWidth: CGFloat, leadingInset: CGFloat, cellWidth: CGFloat) -> Int {
        var availableWidth = availableWidth - leadingInset * 2
        var numberOfTiles = 0

        while availableWidth > cellWidth {
            numberOfTiles += 1
            availableWidth = availableWidth - cellWidth - HomepageSectionLayoutProvider.UX.standardSpacing
        }
        let minCardsConstant = HomepageSectionLayoutProvider.UX.TopSitesConstants.minCards
        let tilesPerRowCount = numberOfTiles < minCardsConstant ? minCardsConstant : numberOfTiles

        // TODO: FXIOS-10972 - Investigate a better way to solve the crash issue that is resolved by adding this
        queue.async {
            self.numberOfTilesPerRow = tilesPerRowCount
        }

        return tilesPerRowCount
    }
}
