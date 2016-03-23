/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class TopAlignedCollectionViewFlowLayout: UICollectionViewFlowLayout {

    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElementsInRect(rect) else { return nil }

        var newAttributes = [UICollectionViewLayoutAttributes]()
        let topMargin = self.sectionInset.top

        for attribs in attributes {
            if attribs.frame.origin.y != topMargin {
                let newAttribs = attribs.copy() as! UICollectionViewLayoutAttributes
                var newTopAlignedFrame = newAttribs.frame
                newTopAlignedFrame.origin.y = topMargin
                newAttribs.frame = newTopAlignedFrame
                newAttributes.append(newAttribs)
            } else {
                newAttributes.append(attribs)
            }
        }

        return newAttributes
    }

}
