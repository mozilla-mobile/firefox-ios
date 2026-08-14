// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

final class ArcActivityIndicatorView: UIView, ThemeApplicable {
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
        setupLayers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayers() {
            for shape in [trackLayer, arcLayer] {
                shape.fillColor = UIColor.clear.cgColor
                shape.lineWidth = UX.lineWidth
                layer.addSublayer(shape)
            }
            arcLayer.lineCap = .round
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

    func startAnimating() {
        let isNewSpinner = layer.animation(forKey: "rotation") == nil
        isHidden = false
        guard isNewSpinner else { return }
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = 0
        animation.toValue = CGFloat.pi * 2
        animation.duration = UX.rotationDuration
        animation.repeatCount = .infinity
        layer.add(animation, forKey: "rotation")
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .layoutChanged, argument: self)
        }
    }

    func stopAnimating() {
        let hadSpinner = layer.animation(forKey: "rotation") != nil
        isHidden = true
        layer.removeAnimation(forKey: "rotation")
        if hadSpinner && UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .layoutChanged, argument: self)
        }
    }

    func applyTheme(theme: any Theme) {
            trackLayer.strokeColor = theme.colors.borderSecondary.cgColor
            arcLayer.strokeColor = theme.colors.actionPrimary.cgColor
        }
}
