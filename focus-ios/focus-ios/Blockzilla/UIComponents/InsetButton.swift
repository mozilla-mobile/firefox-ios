/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

/**
 * Button whose insets are included in its intrinsic size.
 */
class InsetButton: UIButton {
    init() {
        super.init(frame: CGRect.zero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + titleEdgeInsets.left + titleEdgeInsets.right,
                      height: size.height + titleEdgeInsets.top + titleEdgeInsets.bottom)
    }

    var highlightedBackgroundColor: UIColor?
    var savedBackgroundColor: UIColor?

    @objc override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                if savedBackgroundColor == nil && backgroundColor != nil {
                    if let color = highlightedBackgroundColor {
                        savedBackgroundColor = backgroundColor
                        backgroundColor = color
                    }
                }
            } else {
                if let color = savedBackgroundColor {
                    backgroundColor = color
                    savedBackgroundColor = nil
                }
            }
        }
    }
}
