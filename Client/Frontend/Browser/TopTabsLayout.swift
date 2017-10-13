/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
import Foundation

class TopTabsLayoutDelegate: NSObject, UICollectionViewDelegateFlowLayout {
    weak var tabSelectionDelegate: TabSelectionDelegate?
    let HeaderFooterWidth = TopTabsUX.SeparatorWidth + TopTabsUX.FaderPading
    
    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return TopTabsUX.SeparatorWidth
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: TopTabsUX.TabWidth, height: collectionView.frame.height)
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return TopTabsUX.SeparatorWidth
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        tabSelectionDelegate?.didSelectTabAtIndex(indexPath.row)
    }

    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: HeaderFooterWidth, height: 0)
    }

    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: HeaderFooterWidth, height: 0)
    }

}

class TopTabsViewLayout: UICollectionViewFlowLayout {
    var decorationAttributeArr: [Int: UICollectionViewLayoutAttributes?] = [:]
    let separatorYOffset = TopTabsUX.SeparatorYOffset
    let separatorSize = TopTabsUX.SeparatorHeight
    let SeparatorZIndex = -2 ///Prevent the header/footer from appearing above the Tabs
    
    override var collectionViewContentSize: CGSize {
        let tabsWidth = ((CGFloat(collectionView!.numberOfItems(inSection: 0))) * (TopTabsUX.TabWidth + TopTabsUX.SeparatorWidth)) - TopTabsUX.SeparatorWidth
        return CGSize(width: tabsWidth + (TopTabsUX.TopTabsBackgroundShadowWidth * 2), height: collectionView!.bounds.height)
    }
    
    override func prepare() {
        super.prepare()
        self.minimumLineSpacing = TopTabsUX.SeparatorWidth
        scrollDirection = UICollectionViewScrollDirection.horizontal
        register(TopTabsSeparator.self, forDecorationViewOfKind: TopTabsSeparatorUX.Identifier)
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        decorationAttributeArr = [:]
        return true
    }

    // MARK: layoutAttributesForElementsInRect
    override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard indexPath.row < self.collectionView!.numberOfItems(inSection: 0) else {
            let separatorAttr = UICollectionViewLayoutAttributes(forDecorationViewOfKind: TopTabsSeparatorUX.Identifier, with: indexPath)
            separatorAttr.frame = CGRect.zero
            separatorAttr.zIndex = SeparatorZIndex
            return separatorAttr
        }

        if let attr = self.decorationAttributeArr[indexPath.item] {
            return attr
        } else {
            // Compute the separator if it does not exist in the cache
            let separatorAttr = UICollectionViewLayoutAttributes(forDecorationViewOfKind: TopTabsSeparatorUX.Identifier, with: indexPath)
            let x = TopTabsUX.TopTabsBackgroundShadowWidth + ((CGFloat(indexPath.row) * (TopTabsUX.TabWidth + TopTabsUX.SeparatorWidth)) - TopTabsUX.SeparatorWidth)
            separatorAttr.frame = CGRect(x: x, y: separatorYOffset, width: TopTabsUX.SeparatorWidth, height: separatorSize)
            separatorAttr.zIndex = SeparatorZIndex
            return separatorAttr
        }
    }

    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)
        attributes?.zIndex = SeparatorZIndex
        return attributes
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributes = super.layoutAttributesForElements(in: rect)!

        // Create attributes for the Tab Separator.
        for i in attributes {
            guard i.representedElementKind != UICollectionElementKindSectionHeader && i.representedElementKind != UICollectionElementKindSectionFooter else {
                i.zIndex = SeparatorZIndex
                continue
            }
            let sep = UICollectionViewLayoutAttributes(forDecorationViewOfKind: TopTabsSeparatorUX.Identifier, with: i.indexPath)
            sep.frame = CGRect(x: i.frame.origin.x - TopTabsUX.SeparatorWidth, y: separatorYOffset, width: TopTabsUX.SeparatorWidth, height: separatorSize)
            sep.zIndex = SeparatorZIndex
            i.zIndex = 10

            // Only add the seperator if it will be shown.
            if i.indexPath.row != 0 && i.indexPath.row < self.collectionView!.numberOfItems(inSection: 0) {
                attributes.append(sep)
                decorationAttributeArr[i.indexPath.item] = sep
            }
        }

        return attributes
    }
}
