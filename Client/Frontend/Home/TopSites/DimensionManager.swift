// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct TopSitesSectionDimension {
    var numberOfRows: Int
    var numberOfTilesPerRow: Int
}

// Laurie - documentation
protocol DimensionManager {
    func getSectionDimension(for sites: [TopSite],
                             numberOfRows: Int,
                             trait: UITraitCollection,
                             isLandscape: Bool,
                             isIphone: Bool
    ) -> TopSitesSectionDimension

    func widthDimension(for numberOfHorizontalItems: Int) -> NSCollectionLayoutDimension

    var defaultDimension: TopSitesSectionDimension { get }
}

extension DimensionManager {
    func getSectionDimension(for sites: [TopSite],
                             numberOfRows: Int,
                             trait: UITraitCollection,
                             isLandscape: Bool = UIWindow.isLandscape,
                             isIphone: Bool = UIDevice.current.userInterfaceIdiom == .phone
    ) -> TopSitesSectionDimension {
        return self.getSectionDimension(for: sites,
                                        numberOfRows: numberOfRows,
                                        trait: trait,
                                        isLandscape: isLandscape,
                                        isIphone: isIphone)
    }

    var defaultDimension: TopSitesSectionDimension {
        return TopSitesSectionDimension(numberOfRows: 2, numberOfTilesPerRow: 6)
    }
}

class DimensionManagerImplementation: DimensionManager {

    struct UX {
        static let numberOfItemsPerRowForSizeClassIpad = UXSizeClasses(compact: 3, regular: 4, other: 2)
    }

    var sectionDimension: TopSitesSectionDimension!

    init() {
        sectionDimension = defaultDimension
    }

    func getSectionDimension(for sites: [TopSite],
                             numberOfRows: Int,
                             trait: UITraitCollection,
                             isLandscape: Bool,
                             isIphone: Bool
    ) -> TopSitesSectionDimension {
        let topSitesInterface = UITopSitesInterface(isLandscape: isLandscape,
                                                    isIphone: isIphone,
                                                    horizontalSizeClass: trait.horizontalSizeClass)

        let numberOfTilesPerRow = getNumberOfTilesPerRow(for: topSitesInterface)
        let numberOfRows = getNumberOfRows(for: sites,
                                           numberOfRows: numberOfRows,
                                           numberOfTilesPerRow: numberOfTilesPerRow)
        return TopSitesSectionDimension(numberOfRows: numberOfRows,
                                        numberOfTilesPerRow: numberOfTilesPerRow)
    }

    // The width dimension of a cell
    func widthDimension(for numberOfHorizontalItems: Int) -> NSCollectionLayoutDimension {
        return .fractionalWidth(CGFloat(1 / numberOfHorizontalItems))
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
    /// - Parameter interface: Tile number is based on layout, this param contains the parameters needed to computer the tile number
    /// - Returns: The number of tiles per row the user will see
    private func getNumberOfTilesPerRow(for interface: UITopSitesInterface) -> Int {
        if interface.isIphone {
            return interface.isLandscape ? 8 : 4

        } else {
            // The number of items in a row is equal to the number of top sites in a row * 2
            var numItems = Int(UX.numberOfItemsPerRowForSizeClassIpad[interface.horizontalSizeClass])
            if !interface.isLandscape || (interface.horizontalSizeClass == .compact && interface.isLandscape) {
                numItems = numItems - 1
            }
            return numItems * 2
        }
    }
}
