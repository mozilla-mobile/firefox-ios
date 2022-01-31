// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0
import Foundation

protocol TopTabsScrollDelegate: AnyObject {
    func collectionViewDidScroll(_ scrollView: UIScrollView)
}

class TopTabsLayoutDelegate: NSObject, UICollectionViewDelegateFlowLayout {
    weak var tabSelectionDelegate: TabSelectionDelegate?
    weak var scrollViewDelegate: TopTabsScrollDelegate?
    let HeaderFooterWidth = TopTabsUX.SeparatorWidth + TopTabsUX.FaderPading

    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return TopTabsUX.SeparatorWidth
    }

    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let items = collectionView.numberOfItems(inSection: 0)
        var width = collectionView.frame.width / CGFloat(items)
        width = max(TopTabsUX.MinTabWidth, min(width, TopTabsUX.MaxTabWidth))
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
        return CGSize(width: 0, height: 0)
    }

    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: 0, height: 0)
    }
}

extension TopTabsLayoutDelegate: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollViewDelegate?.collectionViewDidScroll(scrollView)
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
}
