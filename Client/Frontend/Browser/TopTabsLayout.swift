/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class TopTabsLayoutDelegate: NSObject, UICollectionViewDelegateFlowLayout {
    weak var tabSelectionDelegate: TabSelectionDelegate?
    
    @objc func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
    
    @objc func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(TopTabsUX.TabWidth, collectionView.frame.height)
    }
    
    @objc func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(0, TopTabsUX.TopTabsBackgroundShadowWidth, 0, TopTabsUX.TopTabsBackgroundShadowWidth)
    }
    
    @objc func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
    
    @objc func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        tabSelectionDelegate?.didSelectTabAtIndex(indexPath.row)
    }
}

class TopTabsViewLayout: UICollectionViewFlowLayout {
    var themeColor: UIColor = TopTabsUX.TopTabsBackgroundNormalColorInactive
    var decorationAttributeArr: [Int : UICollectionViewLayoutAttributes?] = [:]
    
    override func collectionViewContentSize() -> CGSize {
        return CGSize(width: CGFloat(collectionView!.numberOfItemsInSection(0)) * (TopTabsUX.TabWidth+1)+TopTabsUX.TopTabsBackgroundShadowWidth*2,
                      height: CGRectGetHeight(collectionView!.bounds))
    }
    
    override func prepareLayout() {
        super.prepareLayout()
        self.minimumLineSpacing = 2
        scrollDirection = UICollectionViewScrollDirection.Horizontal
        registerClass(TopTabsBackgroundDecorationView.self, forDecorationViewOfKind: TopTabsBackgroundDecorationView.Identifier)
        registerClass(Seperator.self, forDecorationViewOfKind: "Seperator")
    }
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }

    // MARK: layoutAttributesForElementsInRect
    override func layoutAttributesForDecorationViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        if let attr = self.decorationAttributeArr[indexPath.row] {
            return attr
        } else {
            // Sometimes decoration views will be requested for rows that might not exist. Just show an empty seperator.
            let seperatorAttr = UICollectionViewLayoutAttributes(forDecorationViewOfKind: "Seperator", withIndexPath: indexPath)
            seperatorAttr.frame = CGRect.zero
            seperatorAttr.zIndex = -1
            return seperatorAttr
        }
    }

    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributes = super.layoutAttributesForElementsInRect(rect)!
        
        // Create decoration attributes
        let decorationAttributes = TopTabsViewLayoutAttributes(forDecorationViewOfKind: TopTabsBackgroundDecorationView.Identifier, withIndexPath: NSIndexPath(forRow: 0, inSection: 0))
        let size = collectionViewContentSize()
        let offset = TopTabsUX.TopTabsBackgroundPadding-TopTabsUX.TopTabsBackgroundShadowWidth * 2
        decorationAttributes.frame = CGRectMake(-(offset)/2, 0, size.width + offset, size.height)
        decorationAttributes.zIndex = -1
        decorationAttributes.themeColor = self.themeColor

        // Create attributes for the Tab Seperator.
        var seperatorArr: [Int: UICollectionViewLayoutAttributes] = [:]
        for i in attributes {
            if i.indexPath.item > 0 {
                let sep = UICollectionViewLayoutAttributes(forDecorationViewOfKind: "Seperator", withIndexPath: i.indexPath)
                sep.frame = CGRect(x: i.frame.origin.x - 2, y: i.frame.size.height / 4 , width: 1, height: i.frame.size.height / 2)
                sep.zIndex = -1
                seperatorArr[i.indexPath.row] = sep
                attributes.append(sep)
            }
        }

        self.decorationAttributeArr = seperatorArr
        attributes.append(decorationAttributes)
        return attributes
    }
}
