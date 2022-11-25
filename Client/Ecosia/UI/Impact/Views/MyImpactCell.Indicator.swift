/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

extension MyImpactCell {
    final class Indicator: UIView {
        var value = Double() {
            didSet {
                let guide = CGMutablePath()
                guide.addArc(center: .init(x: bounds.size.width/2, y: bounds.size.width/2),
                             radius: bounds.size.width/2 - 8,
                             startAngle: .pi - 0.2,
                             endAngle: 0.2 - ((.pi + 0.3) - ((.pi + 0.3) * value)),
                             clockwise: false)
                
                (layer as! CAShapeLayer).path = { path in
                    path
                        .addArc(center: guide.currentPoint,
                                radius: 9,
                                startAngle: 0,
                                endAngle: .pi * 2,
                                clockwise: false)
                    return path
                } (CGMutablePath())
            }
        }
        
        override class var layerClass: AnyClass {
            CAShapeLayer.self
        }
        
        required init?(coder: NSCoder) { nil }
        
        init(size: CGSize) {
            super.init(frame: .init(size: size))
            isUserInteractionEnabled = false
            translatesAutoresizingMaskIntoConstraints = false
            widthAnchor.constraint(equalToConstant: size.width).isActive = true
            heightAnchor.constraint(equalToConstant: size.height).isActive = true
            (layer as! CAShapeLayer).lineWidth = 2
        }
        
        func update(fill: UIColor, border: UIColor) {
            (layer as! CAShapeLayer).fillColor = fill.cgColor
            (layer as! CAShapeLayer).strokeColor = border.cgColor
        }
    }
}
