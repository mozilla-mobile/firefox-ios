// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

class TopSitesDimensionImplementation {
    private let windowUUID: WindowUUID
    init(windowUUID: WindowUUID) {
        self.windowUUID = windowUUID
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

        return tilesPerRowCount
    }
}
