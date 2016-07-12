/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

/// A transparent view with a rectangular border with rounded corners, stroked
/// with a semi-transparent white border.
class InnerStrokedView: UIView {
    var color = UIColor.white().withAlphaComponent(0.2) {
        didSet {
            setNeedsDisplay()
        }
    }

    var strokeWidth: CGFloat = 1.0 {
        didSet {
            setNeedsDisplay()
        }
    }

    var cornerRadius: CGFloat = 4 {
        didSet {
            setNeedsDisplay()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        let halfWidth = strokeWidth / 2 as CGFloat

        let path = UIBezierPath(roundedRect: CGRect(x: halfWidth,
            y: halfWidth,
            width: rect.width - strokeWidth,
            height: rect.height - strokeWidth),
            cornerRadius: cornerRadius)
        color.setStroke()
        path.lineWidth = strokeWidth
        path.stroke()
    }
}
