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
        let items = collectionView.numberOfItems(inSection: 0)
        var width = collectionView.frame.width / CGFloat(items)
        width = max(72, min(width, 220))
        return CGSize(width: width, height: collectionView.frame.height)
    }

    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
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

    override func prepare() {
        super.prepare()
        self.minimumLineSpacing = TopTabsUX.SeparatorWidth
        scrollDirection = .horizontal
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        decorationAttributeArr = [:]
        return true
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
            guard i.representedElementKind != UICollectionView.elementKindSectionHeader && i.representedElementKind != UICollectionView.elementKindSectionFooter else {
                i.zIndex = SeparatorZIndex
                continue
            }
            i.zIndex = 10

            // Only add the seperator if it will be shown.
            if i.indexPath.row != 0 && i.indexPath.row < self.collectionView!.numberOfItems(inSection: 0) {
            }
        }

        return attributes
    }
}
