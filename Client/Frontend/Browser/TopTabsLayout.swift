/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class TopTabsLayoutDelegate: NSObject, UICollectionViewDelegateFlowLayout {
    weak var tabSelectionDelegate: TabSelectionDelegate?
    
    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: TopTabsUX.TabWidth, height: collectionView.frame.height)
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(1, TopTabsUX.TopTabsBackgroundShadowWidth, 1, TopTabsUX.TopTabsBackgroundShadowWidth)
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        tabSelectionDelegate?.didSelectTabAtIndex(indexPath.row)
    }
}

class TopTabsViewLayout: UICollectionViewFlowLayout {
    var themeColor: UIColor = TopTabsUX.TopTabsBackgroundNormalColorInactive
    
    override var collectionViewContentSize : CGSize {
        return CGSize(width: CGFloat(collectionView!.numberOfItems(inSection: 0)) * (TopTabsUX.TabWidth+1)+TopTabsUX.TopTabsBackgroundShadowWidth*2,
                      height: collectionView!.bounds.height)
    }
    
    override func prepare() {
        super.prepare()
        scrollDirection = UICollectionViewScrollDirection.horizontal
        register(TopTabsBackgroundDecorationView.self, forDecorationViewOfKind: TopTabsBackgroundDecorationView.Identifier)
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    // MARK: layoutAttributesForElementsInRect
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributes = super.layoutAttributesForElements(in: rect)!
        
        // Create decoration attributes
        let decorationAttributes = TopTabsViewLayoutAttributes(forDecorationViewOfKind: TopTabsBackgroundDecorationView.Identifier, with: IndexPath(row: 0, section: 0))
        
        // Make the decoration view span the entire row
        let size = collectionViewContentSize
        decorationAttributes.frame = CGRect(x: -(TopTabsUX.TopTabsBackgroundPadding-TopTabsUX.TopTabsBackgroundShadowWidth*2)/2, y: 0, width: size.width+(TopTabsUX.TopTabsBackgroundPadding-TopTabsUX.TopTabsBackgroundShadowWidth*2), height: size.height)
        
        // Set the zIndex to be behind the item
        decorationAttributes.zIndex = -1
        
        // Set the style (light or dark)
        decorationAttributes.themeColor = self.themeColor
        
        // Add the attribute to the list
        attributes.append(decorationAttributes)
        
        return attributes
    }
}
