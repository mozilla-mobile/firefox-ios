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
        return UIEdgeInsetsMake(0, TopTabsUX.TopTabsBackgroundShadowWidth, 0, TopTabsUX.TopTabsBackgroundShadowWidth)
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
    var decorationAttributeArr: [Int : UICollectionViewLayoutAttributes?] = [:]
    
    override var collectionViewContentSize : CGSize {
        return CGSize(width: CGFloat(collectionView!.numberOfItems(inSection: 0)) * (TopTabsUX.TabWidth+1)+TopTabsUX.TopTabsBackgroundShadowWidth*2,
                      height: collectionView!.bounds.height)
    }
    
    override func prepare() {
        super.prepare()
        self.minimumLineSpacing = 2
        scrollDirection = UICollectionViewScrollDirection.horizontal
        register(TopTabsBackgroundDecorationView.self, forDecorationViewOfKind: TopTabsBackgroundDecorationView.Identifier)
        register(TopTabsSeparator.self, forDecorationViewOfKind: TopTabsSeparatorUX.Identifier)
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }

    // MARK: layoutAttributesForElementsInRect
    override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if let attr = self.decorationAttributeArr[indexPath.row] {
            return attr
        } else {
            // Sometimes decoration views will be requested for rows that might not exist. Just show an empty separator.
            let separatorAttr = UICollectionViewLayoutAttributes(forDecorationViewOfKind: TopTabsSeparatorUX.Identifier, with: indexPath)
            separatorAttr.frame = CGRect.zero
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
        decorationAttributes.zIndex = -1
        decorationAttributes.themeColor = self.themeColor

        // Create attributes for the Tab Separator.
        var separatorArr: [Int: UICollectionViewLayoutAttributes] = [:]
        for i in attributes {
            if i.indexPath.item > 0 {
                let sep = UICollectionViewLayoutAttributes(forDecorationViewOfKind: TopTabsSeparatorUX.Identifier, with: i.indexPath)
                sep.frame = CGRect(x: i.frame.origin.x - 2, y: i.frame.size.height / 4, width: TopTabsSeparatorUX.Width, height: i.frame.size.height / 2)
                sep.zIndex = -1
                separatorArr[i.indexPath.row] = sep
                attributes.append(sep)
            }
        }

        self.decorationAttributeArr = separatorArr
        attributes.append(decorationAttributes)
        return attributes
    }
}
