// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A custom layout used to show a horizontal scrolling list with paging. Similar to iOS springboard.
/// A modified version of http://stackoverflow.com/a/34167915
class TopSiteFlowLayout: UICollectionViewLayout {

    struct UX {
        static let MinimumInsets: CGFloat = 4
        static let VerticalInsets: CGFloat = 16
        static let TopSiteEmptyCellIdentifier = "TopSiteItemEmptyCell"
    }

    fileprivate var cellCount: Int {
        if let collectionView = collectionView, let dataSource = collectionView.dataSource {
            return dataSource.collectionView(collectionView, numberOfItemsInSection: 0)
        }
        return 0
    }
    var boundsSize = CGSize.zero
    private var insets = UIEdgeInsets(equalInset: UX.MinimumInsets)
    private var sectionInsets: CGFloat = 0
    var itemSize = CGSize.zero
    var cachedAttributes: [UICollectionViewLayoutAttributes]?

    override func prepare() {
        super.prepare()
        if boundsSize != self.collectionView?.frame.size {
            self.collectionView?.setContentOffset(.zero, animated: false)
        }
        boundsSize = self.collectionView?.frame.size ?? .zero
        cachedAttributes = nil
        register(EmptyTopSiteCell.self, forDecorationViewOfKind: UX.TopSiteEmptyCellIdentifier)
    }

    func numberOfPages(with bounds: CGSize) -> Int {
        return 1
    }

    func calculateLayout(for size: CGSize) -> (size: CGSize, cellSize: CGSize, cellInsets: UIEdgeInsets) {
        let width = size.width
        guard width != 0 else {
            return (size: .zero, cellSize: self.itemSize, cellInsets: self.insets)
        }

        let horizontalItemsCount = maxHorizontalItemsCount(width: width) // 8
        let estimatedItemSize = itemSize

        // Calculate our estimates.
        let rows = CGFloat(ceil(Double(Float(cellCount)/Float(horizontalItemsCount))))
        let estimatedHeight = (rows * estimatedItemSize.height) + (8 * rows)
        let estimatedSize = CGSize(width: width, height: estimatedHeight)

        // Take the number of cells and subtract its space in the view from the width. The left over space is the white space.
        // The left over space is then divided evenly into (n - 1) parts to figure out how much space should be in between a cell
        let calculatedSpacing = floor((width - (CGFloat(horizontalItemsCount) * estimatedItemSize.width)) / CGFloat(horizontalItemsCount - 1))
        let insets = max(UX.MinimumInsets, calculatedSpacing)
        let estimatedInsets = UIEdgeInsets(top: UX.VerticalInsets, left: insets, bottom: UX.VerticalInsets, right: insets)

        return (size: estimatedSize, cellSize: estimatedItemSize, cellInsets: estimatedInsets)
    }

    override var collectionViewContentSize: CGSize {
        let estimatedLayout = calculateLayout(for: boundsSize)
        insets = estimatedLayout.cellInsets
        itemSize = estimatedLayout.cellSize
        boundsSize.height = estimatedLayout.size.height
        return estimatedLayout.size
    }

    func maxHorizontalItemsCount(width: CGFloat) -> Int {
        let horizontalItemsCount = Int(floor(width / (TopSiteCollectionCell.UX.ItemSize.width + insets.left)))
        // TODO: Laurie
//        if let delegate = self.collectionView?.delegate as? ASHorizontalScrollCellManager {
//            return delegate.numberOfHorizontalItems()
//        } else {
            return horizontalItemsCount
//        }
    }

    override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let decorationAttr = UICollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind, with: indexPath)
        let cellAttr = self.computeLayoutAttributesForCellAtIndexPath(indexPath)
        decorationAttr.frame = cellAttr.frame

        decorationAttr.frame.size.height -= TopSiteItemCell.UX.titleHeight
        decorationAttr.zIndex = -1
        return decorationAttr
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        if cachedAttributes != nil {
            return cachedAttributes
        }
        var allAttributes = [UICollectionViewLayoutAttributes]()
        for i in 0 ..< cellCount {
            let indexPath = IndexPath(row: i, section: 0)
            let attr = self.computeLayoutAttributesForCellAtIndexPath(indexPath)
            allAttributes.append(attr)
        }

        // Create decoration attributes
        let horizontalItemsCount = maxHorizontalItemsCount(width: boundsSize.width)
        var numberOfCells = cellCount
        while numberOfCells % horizontalItemsCount != 0 {
            // Empty cell handling
            let attr = self.layoutAttributesForDecorationView(ofKind: UX.TopSiteEmptyCellIdentifier, at: IndexPath(item: numberOfCells, section: 0))
            allAttributes.append(attr!)
            numberOfCells += 1
        }
        cachedAttributes = allAttributes
        return allAttributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return self.computeLayoutAttributesForCellAtIndexPath(indexPath)
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        cachedAttributes = nil
        // Sometimes when the topsiteCell isnt on the screen the newbounds that it tries to layout in is 0
        // Resulting in incorrect layouts. Only layout when a valid width is given
        return newBounds.width > 0 && newBounds.size != self.collectionView?.frame.size
    }

    func computeLayoutAttributesForCellAtIndexPath(_ indexPath: IndexPath) -> UICollectionViewLayoutAttributes {
        let row = indexPath.row
        let bounds = self.collectionView!.bounds

        let horizontalItemsCount = maxHorizontalItemsCount(width: bounds.size.width)
        let columnPosition = row % horizontalItemsCount
        let rowPosition = Int(row/horizontalItemsCount)

        let attr = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        var frame = CGRect.zero
        frame.origin.x = CGFloat(columnPosition) * (itemSize.width + insets.left)
        frame.origin.y = CGFloat(rowPosition) * (itemSize.height + insets.top)

        frame.size = itemSize
        attr.frame = frame
        return attr
    }
}
