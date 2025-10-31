// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol TopTabsScrollDelegate: AnyObject {
    @MainActor
    func collectionViewDidScroll(_ scrollView: UIScrollView)
}

class TopTabsLayoutDelegate: NSObject, UICollectionViewDelegateFlowLayout {
    struct UX {
        static let separatorWidth: CGFloat = 1
        @MainActor
        static let minTabWidth: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 130 : 76
        static let maxTabWidth: CGFloat = 220
        static let faderPading: CGFloat = 8
        static let separatorYOffset: CGFloat = 7
        static let separatorHeight: CGFloat = 32
    }

    weak var tabSelectionDelegate: TabSelectionDelegate?
    weak var scrollViewDelegate: TopTabsScrollDelegate?
    let headerFooterWidth = UX.separatorWidth + UX.faderPading

    @objc
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        return UX.separatorWidth
    }

    @objc
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let items = collectionView.numberOfItems(inSection: 0)
        var width = collectionView.frame.width / CGFloat(items)
        width = max(UX.minTabWidth, min(width, UX.maxTabWidth))
        return CGSize(width: width, height: collectionView.frame.height)
    }

    @objc
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        return .zero
    }

    @objc
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return UX.separatorWidth
    }

    @objc
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        tabSelectionDelegate?.didSelectTabAtIndex(indexPath.row)
    }

    @objc
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        return CGSize(width: 0, height: 0)
    }

    @objc
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForFooterInSection section: Int
    ) -> CGSize {
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
    let separatorYOffset = TopTabsLayoutDelegate.UX.separatorYOffset
    let separatorSize = TopTabsLayoutDelegate.UX.separatorHeight
    let SeparatorZIndex = -2 /// Prevent the header/footer from appearing above the Tabs

    override func prepare() {
        super.prepare()
        self.minimumLineSpacing = TopTabsLayoutDelegate.UX.separatorWidth
        scrollDirection = .horizontal
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        decorationAttributeArr = [:]
        return true
    }

    override func layoutAttributesForSupplementaryView(
        ofKind elementKind: String,
        at indexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        let attributes = super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)
        attributes?.zIndex = SeparatorZIndex
        return attributes
    }

    override var flipsHorizontallyInOppositeLayoutDirection: Bool {
        return true
    }
}
