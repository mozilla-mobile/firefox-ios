/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


import UIKit

class MenuItemImageView: UIImageView {

    var overlayColor: UIColor = UIColor.clearColor() {
        didSet {
            setNeedsDisplay()
        }
    }

    init() {
        super.init(frame: CGRect.zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        CGContextSaveGState(context)

        CGContextDrawImage(context, rect, image?.CGImage)

        CGContextSetBlendMode(context, .Multiply)
        CGContextSetFillColor(context, CGColorGetComponents(overlayColor.CGColor))
        CGContextFillRect(context, self.bounds)
        CGContextRestoreGState(context)
    }

}
