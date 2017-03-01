/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
import Foundation

class TopTabsLayoutDelegate: NSObject, UICollectionViewDelegateFlowLayout {
    weak var tabSelectionDelegate: TabSelectionDelegate?
    
    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return TopTabsUX.SeparatorWidth
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: TopTabsUX.TabWidth, height: collectionView.frame.height)
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: TopTabsUX.TopTabsBackgroundShadowWidth, bottom: 0, right: TopTabsUX.TopTabsBackgroundShadowWidth)
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return TopTabsUX.SeparatorWidth
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        tabSelectionDelegate?.didSelectTabAtIndex(indexPath.row)
    }
}

class TopTabsViewLayout: UICollectionViewFlowLayout {
    var themeColor: UIColor = TopTabsUX.TopTabsBackgroundNormalColorInactive
    var decorationAttributeArr: [Int : UICollectionViewLayoutAttributes?] = [:]
    
    override var collectionViewContentSize: CGSize {
        let tabsWidth = ((CGFloat(collectionView!.numberOfItems(inSection: 0))) * (TopTabsUX.TabWidth + TopTabsUX.SeparatorWidth)) - TopTabsUX.SeparatorWidth
        return CGSize(width: tabsWidth + (TopTabsUX.TopTabsBackgroundShadowWidth*2), height: collectionView!.bounds.height)
    }
    
    override func prepare() {
        super.prepare()
        self.minimumLineSpacing = TopTabsUX.SeparatorWidth
        scrollDirection = UICollectionViewScrollDirection.horizontal
        register(TopTabsBackgroundDecorationView.self, forDecorationViewOfKind: TopTabsBackgroundDecorationView.Identifier)
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
            separatorAttr.zIndex = -1
            return separatorAttr
        }

        if let attr = self.decorationAttributeArr[indexPath.item] {
            return attr
        } else {
            // Compute the separator if it does not exist in the cache
            let separatorAttr = UICollectionViewLayoutAttributes(forDecorationViewOfKind: TopTabsSeparatorUX.Identifier, with: indexPath)
            let x = TopTabsUX.TopTabsBackgroundShadowWidth + ((CGFloat(indexPath.row) * (TopTabsUX.TabWidth + TopTabsUX.SeparatorWidth)) - TopTabsUX.SeparatorWidth)
            separatorAttr.frame = CGRect(x: x, y: collectionView!.frame.height / 4, width: TopTabsUX.SeparatorWidth, height: collectionView!.frame.height / 2)
            separatorAttr.zIndex = -1
            return separatorAttr
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributes = super.layoutAttributesForElements(in: rect)!
        
        // Create decoration attributes
        let decorationAttributes = TopTabsViewLayoutAttributes(forDecorationViewOfKind: TopTabsBackgroundDecorationView.Identifier, with: IndexPath(row: 0, section: 0))
        let size = collectionViewContentSize
        let offset = TopTabsUX.TopTabsBackgroundPadding-TopTabsUX.TopTabsBackgroundShadowWidth * 2
        decorationAttributes.frame = CGRect(x: -(offset)/2, y: 0, width: size.width + offset, height: size.height)
        decorationAttributes.zIndex = -2
        decorationAttributes.themeColor = self.themeColor

        // Create attributes for the Tab Separator.
        for i in attributes {
            let sep = UICollectionViewLayoutAttributes(forDecorationViewOfKind: TopTabsSeparatorUX.Identifier, with: i.indexPath)
            sep.frame = CGRect(x: i.frame.origin.x - TopTabsUX.SeparatorWidth, y: i.frame.size.height / 4, width: TopTabsUX.SeparatorWidth, height: i.frame.size.height / 2)
            sep.zIndex = -1
            // Only add the seperator if it will be shown.
            if i.indexPath.row != 0 &&  i.indexPath.row < self.collectionView!.numberOfItems(inSection: 0) {
                attributes.append(sep)
                decorationAttributeArr[i.indexPath.item] = sep
            }
        }

        attributes.append(decorationAttributes)
        return attributes
    }
}
