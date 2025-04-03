// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

final class CenterSnappingFlowLayout: UICollectionViewFlowLayout {
    override func targetContentOffset(
        forProposedContentOffset proposedContentOffset: CGPoint,
        withScrollingVelocity velocity: CGPoint
    ) -> CGPoint {
        guard let collectionView = collectionView else { return proposedContentOffset }

        let targetRect = CGRect(
            x: proposedContentOffset.x,
            y: 0,
            width: collectionView.bounds.width,
            height: collectionView.bounds.height
        )

        guard let layoutAttributes = super.layoutAttributesForElements(in: targetRect) else {
            return proposedContentOffset
        }

        let centerX = proposedContentOffset.x + collectionView.bounds.width / 2
        let closest = layoutAttributes.min(by: {
            abs($0.center.x - centerX) < abs($1.center.x - centerX)
        })

        guard let closestAttr = closest else { return proposedContentOffset }

        let newOffsetX = closestAttr.center.x - collectionView.bounds.width / 2
        return CGPoint(x: newOffsetX, y: proposedContentOffset.y)
    }
}
