/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class TopTabsLayoutDelegate: NSObject, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {

    weak var tabSelectionDelegate: TabSelectionDelegate?
    weak var tabScrollDelegate: UIScrollViewDelegate?
    
    @objc func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
    
    @objc func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(TopTabsUX.TabWidth, collectionView.frame.height)
    }
    
    @objc func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(1, TopTabsUX.TopTabsBackgroundShadowWidth, 1, TopTabsUX.TopTabsBackgroundShadowWidth)
    }
    
    @objc func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
    
    @objc func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        tabSelectionDelegate?.didSelectTabAtIndex(indexPath.row)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        tabScrollDelegate?.scrollViewDidScroll?(scrollView)
    }
}

class TopTabsViewLayout: UICollectionViewFlowLayout {
    override func collectionViewContentSize() -> CGSize {
        return CGSize(width: CGFloat(collectionView!.numberOfItemsInSection(0)) * (TopTabsUX.TabWidth+1)+TopTabsUX.TopTabsBackgroundShadowWidth*2,
                      height: CGRectGetHeight(collectionView!.bounds))
    }
    
    override func prepareLayout() {
        super.prepareLayout()
        scrollDirection = UICollectionViewScrollDirection.Horizontal
        registerClass(TopTabsBackgroundDecorationView.self, forDecorationViewOfKind: TopTabsBackgroundDecorationView.Identifier)
    }
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
    
    // MARK: layoutAttributesForElementsInRect
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributes = super.layoutAttributesForElementsInRect(rect)!
        
        // Create decoration attributes
        let decorationAttributes = UICollectionViewLayoutAttributes(forDecorationViewOfKind: TopTabsBackgroundDecorationView.Identifier, withIndexPath: NSIndexPath(forRow: 0, inSection: 0))
        
        // Make the decoration view span the entire row
        let size = collectionViewContentSize()
        decorationAttributes.frame = CGRectMake(-(TopTabsUX.TopTabsBackgroundPadding-TopTabsUX.TopTabsBackgroundShadowWidth*2)/2, 0, size.width+(TopTabsUX.TopTabsBackgroundPadding-TopTabsUX.TopTabsBackgroundShadowWidth*2), size.height)
        
        // Set the zIndex to be behind the item
        decorationAttributes.zIndex = -1
        
        // Add the attribute to the list
        attributes.append(decorationAttributes)
        
        return attributes
    }
}