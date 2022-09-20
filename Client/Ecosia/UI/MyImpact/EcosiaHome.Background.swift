/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

private let height = CGFloat(308)

extension EcosiaHome {
    final class Background: UIView {
        private weak var layerMask: CAShapeLayer!
        
        var inset = CGFloat() {
            didSet {
                guard oldValue != inset else { return }
                update()
            }
        }
        
        var offset = CGFloat() {
            didSet {
                update()
            }
        }
        
        override var frame: CGRect {
            didSet {
                update()
            }
        }
        
        required init?(coder: NSCoder) { nil }
        
        init() {
            let layerMask = CAShapeLayer()
            self.layerMask = layerMask
            super.init(frame: .zero)
            layer.mask = layerMask
        }
        
        private func update() {
            let y = max(min(height - (inset + offset), height), 0)
            let path = CGMutablePath()
            path.move(to: .zero)
            path.addLine(to: .init(x: frame.width, y: 0))
            path.addLine(to: .init(x: frame.width, y: y))
            path.addQuadCurve(to: .init(x: frame.width * 0.66, y: y), control: .init(x: frame.width * 0.83, y: y - 20))
            path.addQuadCurve(to: .init(x: frame.width * 0.33, y: y), control: .init(x: frame.width * 0.5, y: y + 20))
            path.addQuadCurve(to: .init(x: 0, y: y), control: .init(x: frame.width * 0.17, y: y - 20))
            path.closeSubpath()
            layerMask.path = path
        }
    }
}
