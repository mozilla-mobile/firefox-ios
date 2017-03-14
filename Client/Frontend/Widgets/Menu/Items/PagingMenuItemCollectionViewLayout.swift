/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class PagingMenuItemCollectionViewLayout: UICollectionViewLayout {

    var maxNumberOfItemsPerPageRow: Int = 0
    var menuRowHeight: CGFloat = 0
    var lineSpacing: CGFloat = 0
    var interitemSpacing: CGFloat = 0

    var contentSize = CGSize.zero
    var layoutCellAttributes = [IndexPath: UICollectionViewLayoutAttributes]()

    override var collectionViewContentSize: CGSize {
        return contentSize
    }

    fileprivate func cellSizeForCollectionView(_ collectionView: UICollectionView) -> CGSize {
        // calculate cell size
        var cellWidth = (collectionView.bounds.size.width - self.interitemSpacing) / CGFloat(self.maxNumberOfItemsPerPageRow)
        cellWidth -= self.interitemSpacing
        let cellHeight = CGFloat(menuRowHeight)
        return CGSize(width: cellWidth, height: cellHeight)
    }

    override func prepare() {
        super.prepare()
        guard let collectionView = self.collectionView,
            let collectionViewDataSource = collectionView.dataSource else {
                return
        }
        
        layoutCellAttributes.removeAll()

        let cellSize = cellSizeForCollectionView(collectionView)

        var x: CGFloat = 0
        var y: CGFloat
        let pageWidth = interitemSpacing + ((cellSize.width + interitemSpacing) * CGFloat(maxNumberOfItemsPerPageRow))
        var cellIndex: Int
        let numberOfPages = collectionViewDataSource.numberOfSections?(in: collectionView) ?? 0
        let maxNumberOfItemsForPage = collectionViewDataSource.collectionView(collectionView, numberOfItemsInSection: 0)
        for pageIndex in 0..<numberOfPages {
            x = (pageWidth * CGFloat(pageIndex)) + self.interitemSpacing
            y = self.lineSpacing
            cellIndex = 0
            for itemIndex in 0..<(collectionViewDataSource.collectionView(collectionView, numberOfItemsInSection: pageIndex)) {
                let index = IndexPath(item: itemIndex, section: pageIndex)

                let cellAttributes = UICollectionViewLayoutAttributes(forCellWith: index)
                cellAttributes.frame = CGRect(x: x, y: y, width: cellSize.width, height: cellSize.height)
                cellAttributes.zIndex = 1
                layoutCellAttributes[index] = cellAttributes

                cellIndex += 1
                if cellIndex < maxNumberOfItemsPerPageRow {
                    x += cellSize.width + self.interitemSpacing
                } else {
                    cellIndex = 0
                    x = (pageWidth * CGFloat(pageIndex)) + self.interitemSpacing
                    y += cellSize.height + self.lineSpacing
                }
            }
        }
        let width =  CGFloat(numberOfPages) * pageWidth
        let numberOfRows = ceil(CGFloat(maxNumberOfItemsForPage) / CGFloat(maxNumberOfItemsPerPageRow))
        let menuHeight = lineSpacing + (numberOfRows * (CGFloat(menuRowHeight) + lineSpacing))
        contentSize = CGSize(width: width, height: menuHeight)
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var newAttributes = [UICollectionViewLayoutAttributes]()
        for attribute in layoutCellAttributes.values {
            if rect.intersects(attribute.frame) {
                newAttributes.append(attribute)
            }
        }

        return newAttributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return layoutCellAttributes[indexPath]
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return super.shouldInvalidateLayout(forBoundsChange: newBounds)
    }
}
