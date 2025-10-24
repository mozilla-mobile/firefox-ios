// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

struct StoriesFeedDimensionCalculator {
    // Calculates the number of cells that fit given a container's width, including spacing between items and minimum
    // horizontal insets
    static func numberOfCellsThatFit(in containerWidth: CGFloat) -> Int {
        // # of cells that would fit in container
        let cellsPerRow = containerWidth / StoriesFeedSectionLayoutProvider.UX.cellSize.width
        // Amount of space used by inter-item spacing and horizontal insets
        let spacingAdjustment = (cellsPerRow > 1 ?
                                 (cellsPerRow - 1) * StoriesFeedSectionLayoutProvider.UX.interItemSpacing : 0)
                                 + (StoriesFeedSectionLayoutProvider.UX.minimumSectionHorizontalInset * 2)
        // Available container width for cells
        let adjustedContainerWidth = containerWidth - spacingAdjustment
        // Number of cells that will fit in a row, considering inter-item spacing and horizontal insets
        let adjustedCellsPerRow = Int(adjustedContainerWidth / StoriesFeedSectionLayoutProvider.UX.cellSize.width)
        return max(StoriesFeedSectionLayoutProvider.UX.minimumCellsPerRow, adjustedCellsPerRow)
    }

    // Calculates the horizontal inset given the size of the container and number of cells we need to show including
    // inter-item spacing
    static func horizontalInset(for containerWidth: CGFloat, cellCount: Int) -> CGFloat {
        let totalCellWidth = StoriesFeedSectionLayoutProvider.UX.cellSize.width * CGFloat(cellCount)
        let totalCellSpacing = (CGFloat(cellCount) * StoriesFeedSectionLayoutProvider.UX.interItemSpacing)
                                - StoriesFeedSectionLayoutProvider.UX.interItemSpacing
        let contentWidth = totalCellWidth + totalCellSpacing
        let totalHorizontalInset = (containerWidth - contentWidth)
        return max(StoriesFeedSectionLayoutProvider.UX.minimumSectionHorizontalInset, totalHorizontalInset / 2)
    }
}
