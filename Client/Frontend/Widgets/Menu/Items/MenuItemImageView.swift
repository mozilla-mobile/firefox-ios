/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


import UIKit

class MenuItemImageView: UIImageView {

    var overlayColor: UIColor = UIColor.clear() {
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

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        context.saveGState()

        context.draw(in: rect, image: (image?.cgImage)!)

        context.setBlendMode(.multiply)
        context.setFillColor(overlayColor.cgColor.components!)
        context.fill(self.bounds)
        context.restoreGState()
    }

}
