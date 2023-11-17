// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class ProgressView: UIView {
    var value = Double(1) {
        didSet {
            (layer as! CAShapeLayer).strokeEnd = value
        }
    }
    var color: UIColor = .clear {
        didSet {
            (layer as! CAShapeLayer).strokeColor = color.cgColor
        }
    }
    
    override class var layerClass: AnyClass {
        CAShapeLayer.self
    }
    
    required init?(coder: NSCoder) { nil }
    
    init(size: CGSize, lineWidth: CGFloat) {
        super.init(frame: .init(size: size))
        isUserInteractionEnabled = false
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: size.width).isActive = true
        heightAnchor.constraint(equalToConstant: size.height).isActive = true
        (layer as! CAShapeLayer).fillColor = UIColor.clear.cgColor
        (layer as! CAShapeLayer).lineWidth = lineWidth
        (layer as! CAShapeLayer).lineCap = .round
        layer.masksToBounds = true
        
        (layer as! CAShapeLayer).path = { path in
            path
                .addArc(center: .init(x: size.width/2, y: size.width/2),
                        radius: size.width/2 - lineWidth,
                        startAngle: .pi - 0.2,
                        endAngle: 0.2,
                        clockwise: false)
            return path
        } (CGMutablePath())
    }
}
