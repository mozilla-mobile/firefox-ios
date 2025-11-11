// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

struct StoriesFeedDimensionCalculator {
    // Calculates the number of cells that fit given a container's width, including spacing between items
    static func numberOfCellsThatFit(in containerWidth: CGFloat) -> Int {
        // Portion of the container not occupied by insets
        let availableContainerWidth = containerWidth * StoriesFeedSectionLayoutProvider.UX.groupWidthRatio
        // # of cells that would fit in container
        let cellsPerRow = floor(availableContainerWidth / StoriesFeedSectionLayoutProvider.UX.minimumCellWidth)
        // Amount of space used by inter-item spacing
        let spacingAdjustment = (cellsPerRow > 1 ?
                                 (cellsPerRow - 1) * StoriesFeedSectionLayoutProvider.UX.interItemSpacing : 0)
        // Available container width for cells
        let adjustedContainerWidth = availableContainerWidth - spacingAdjustment
        // Number of cells that will fit in a row, considering inter-item spacing
        let adjustedCellsPerRow = Int(adjustedContainerWidth / StoriesFeedSectionLayoutProvider.UX.minimumCellWidth)
        return max(StoriesFeedSectionLayoutProvider.UX.minimumCellsPerRow, adjustedCellsPerRow)
    }
}
