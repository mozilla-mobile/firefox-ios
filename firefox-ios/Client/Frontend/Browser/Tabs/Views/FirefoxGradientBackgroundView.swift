// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

final class FirefoxGradientBackgroundView: UIView {

    private let gradientLayer = CAGradientLayer()

    private let glow1 = CALayer()
    private let glow2 = CALayer()
    private let glow3 = CALayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {

        gradientLayer.colors = [
            UIColor(red: 1.0, green: 0.44, blue: 0.22, alpha: 1).cgColor, // orange
            UIColor(red: 0.83, green: 0.25, blue: 1.0, alpha: 1).cgColor, // purple
            UIColor(red: 0.02, green: 0.1, blue: 0.3, alpha: 1).cgColor   // dark blue
        ]

        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)

        layer.addSublayer(gradientLayer)

        configureGlow(glow1,
                      color: UIColor(red: 1, green: 0.3, blue: 0.35, alpha: 0.6))

        configureGlow(glow2,
                      color: UIColor(red: 0.8, green: 0.2, blue: 1.0, alpha: 0.6))

        configureGlow(glow3,
                      color: UIColor(red: 0.35, green: 0.0, blue: 1.0, alpha: 0.6))
    }

    private func configureGlow(_ layerGlow: CALayer, color: UIColor) {

        layerGlow.backgroundColor = color.cgColor
        layerGlow.opacity = 0.8

        layerGlow.shadowColor = color.cgColor
        layerGlow.shadowRadius = 120
        layerGlow.shadowOpacity = 1
        layerGlow.shadowOffset = .zero

        layer.addSublayer(layerGlow)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        gradientLayer.frame = bounds

        let size1: CGFloat = bounds.width * 0.9
        glow1.frame = CGRect(
            x: bounds.width * 0.65,
            y: bounds.height * 0.1,
            width: size1,
            height: size1
        )
        glow1.cornerRadius = size1 / 2

        let size2: CGFloat = bounds.width * 0.8
        glow2.frame = CGRect(
            x: bounds.width * -0.2,
            y: bounds.height * 0.4,
            width: size2,
            height: size2
        )
        glow2.cornerRadius = size2 / 2

        let size3: CGFloat = bounds.width * 0.9
        glow3.frame = CGRect(
            x: bounds.width * 0.2,
            y: bounds.height * 0.75,
            width: size3,
            height: size3
        )
        glow3.cornerRadius = size3 / 2
    }
}
