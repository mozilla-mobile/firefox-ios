// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct TopSitesSectionDimension {
    var numberOfRows: Int
    var numberOfTilesPerRow: Int
}

struct TopSitesUIInterface {
    var isLandscape: Bool = UIWindow.isLandscape
    var interfaceIdiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom
    var trait: UITraitCollection
    var availableWidth: CGFloat
}

/// Top sites dimension are subject to change depending on the user's number of rows,
/// on which device it's showing, if it's landscape or portrait. The dimension should also
/// excludes empty rows from showing. TopSitesDimension support those calculation.
protocol TopSitesDimension {
    /// Get the top sites section dimension to show in the homepage
    /// - Parameters:
    ///   - sites: The top sites that we need to show
    ///   - numberOfRows: The number of rows the user has its preference set to
    ///   - interface: The interface where the top sites are being shown
    ///                (ex in landscape, iPhone and its horizontal size class)
    /// - Returns: The top site dimension including its numberOfRows and numberOfTilesPerRow
    func getSectionDimension(for sites: [TopSite],
                             numberOfRows: Int,
                             interface: TopSitesUIInterface
    ) -> TopSitesSectionDimension
}

class LegacyTopSitesDimensionImplementation: TopSitesDimension {
    func getSectionDimension(for sites: [TopSite],
                             numberOfRows: Int,
                             interface: TopSitesUIInterface
    ) -> TopSitesSectionDimension {
        let numberOfTilesPerRow = getNumberOfTilesPerRow(for: interface)
        let numberOfRows = getNumberOfRows(for: sites,
                                           numberOfRows: numberOfRows,
                                           numberOfTilesPerRow: numberOfTilesPerRow)
        return TopSitesSectionDimension(numberOfRows: numberOfRows,
                                        numberOfTilesPerRow: numberOfTilesPerRow)
    }

    // Adjust number of rows depending on the what the users want, and how many sites we actually have.
    // We hide rows that are only composed of empty cells
    /// - Parameter numberOfTilesPerRow: The number of tiles per row the user will see
    /// - Returns: The number of rows the user will see on screen
    private func getNumberOfRows(for sites: [TopSite],
                                 numberOfRows: Int,
                                 numberOfTilesPerRow: Int) -> Int {
        let totalCellCount = numberOfTilesPerRow * numberOfRows
        let emptyCellCount = totalCellCount - sites.count

        // If there's no empty cell, no clean up is necessary
        guard emptyCellCount > 0 else { return numberOfRows }

        let numberOfEmptyCellRows = Double(emptyCellCount / numberOfTilesPerRow)
        return numberOfRows - Int(numberOfEmptyCellRows.rounded(.down))
    }

    /// Get the number of tiles per row the user will see. This depends on the UI interface the user has.
    /// - Parameter interface: Tile number is based on layout, this param contains the parameters
    ///                        needed to computer the tile number
    /// - Returns: The number of tiles per row the user will see
    private func getNumberOfTilesPerRow(for interface: TopSitesUIInterface) -> Int {
        let cellWidth = TopSitesViewModel.UX.cellEstimatedSize.width
        let leadingInset = HomepageViewModel.UX.leadingInset(traitCollection: interface.trait,
                                                             interfaceIdiom: interface.interfaceIdiom)
        var availableWidth = interface.availableWidth - leadingInset * 2
        var numberOfTiles = 0

        while availableWidth > cellWidth {
            numberOfTiles += 1
            availableWidth = availableWidth - cellWidth - TopSitesViewModel.UX.cardSpacing
        }
        return numberOfTiles < TopSitesViewModel.UX.minCards ? TopSitesViewModel.UX.minCards : numberOfTiles
    }
}
