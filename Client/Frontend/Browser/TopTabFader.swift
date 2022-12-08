// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class TopTabFader: UIView {
    enum ActiveSide {
        case left
        case right
        case both
        case none
    }

    private var activeSide: ActiveSide = .both

    private lazy var hMaskLayer: CAGradientLayer = {
        let hMaskLayer = CAGradientLayer()
        let innerColor = UIColor.Photon.White100.cgColor
        let outerColor = UIColor(white: 1, alpha: 0.0).cgColor

        hMaskLayer.anchorPoint = .zero
        hMaskLayer.startPoint = CGPoint(x: 0, y: 0.5)
        hMaskLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        hMaskLayer.colors = [outerColor, innerColor, innerColor, outerColor]
        return hMaskLayer
    }()

    init() {
        super.init(frame: .zero)
        layer.mask = hMaskLayer
    }

    func setFader(forSides side: ActiveSide) {
        if activeSide != side {
            self.activeSide = side
            setNeedsLayout()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let widthA = NSNumber(value: Float(CGFloat(8) / frame.width))
        let widthB = NSNumber(value: Float(1 - CGFloat(8) / frame.width))

        // decide on which side the fader should be applied
        switch activeSide {
        case .left:
            hMaskLayer.locations = [0.0, widthA, 1.0, 1.0]

        case .right:
            hMaskLayer.locations = [0.0, 0.0, widthB, 1.0]

        case .both:
            hMaskLayer.locations = [0.0, widthA, widthB, 1.0]

        case .none:
            hMaskLayer.locations = [0.0, 0.0, 1.0, 1.0]
        }

        hMaskLayer.frame = CGRect(width: frame.width, height: frame.height)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
