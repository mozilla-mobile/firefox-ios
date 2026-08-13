// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

final class ArcActivityIndicatorView: UIView {
    private struct UX {
        static let lineWidth: CGFloat = 2
        static let rotationDuration: CFTimeInterval = 0.8
        static let arcFraction: CGFloat = 0.25
    }

    private let trackLayer = CAShapeLayer()
    private let arcLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear

        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineWidth = UX.lineWidth

        arcLayer.fillColor = UIColor.clear.cgColor
        arcLayer.lineWidth = UX.lineWidth
        arcLayer.lineCap = .round

        layer.addSublayer(trackLayer)
        layer.addSublayer(arcLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let radius = min(bounds.width, bounds.height) / 2 - UX.lineWidth / 2
        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        trackLayer.path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: 0,
            endAngle: 2 * .pi,
            clockwise: true
        ).cgPath
        trackLayer.frame = bounds

        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + (2 * .pi * UX.arcFraction)
        arcLayer.path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        ).cgPath
        arcLayer.frame = bounds
    }

    func setColors(track: UIColor, arc: UIColor) {
        trackLayer.strokeColor = track.cgColor
        arcLayer.strokeColor = arc.cgColor
    }

    func startAnimating() {
        isHidden = false
        guard layer.animation(forKey: "rotation") == nil else { return }
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = 0
        animation.toValue = CGFloat.pi * 2
        animation.duration = UX.rotationDuration
        animation.repeatCount = .infinity
        layer.add(animation, forKey: "rotation")
    }

    func stopAnimating() {
        isHidden = true
        layer.removeAnimation(forKey: "rotation")
    }
}
