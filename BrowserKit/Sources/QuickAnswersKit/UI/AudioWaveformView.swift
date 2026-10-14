// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

final class AudioWaveformView: UIView, ThemeApplicable {
    private struct UX {
        static let numberOfBars = 5
        static let barWidth: CGFloat = 2.0
        static let barCornerRadius: CGFloat = 2.0
        static let minBarHeight: CGFloat = 4.0
        static let numberOfRandomHeights = 6
        static let heightAnimationKeyPath = "bounds.size.height"
        static let heightAnimationKey = "heightAnimation"
        static let heightAnimationBaseDuration: CFTimeInterval = 0.8
        static let heightAnimationDurationCoefficient: CFTimeInterval = 0.1
        static let stopAnimationDuration: CFTimeInterval = 0.3
        static let stopAnimationKey = "stopAnimation"
        static let barGradientStartPoint = CGPoint(x: 0.5, y: 0.0)
        static let barGradientEndPoint = CGPoint(x: 0.5, y: 1.0)
        static let glowGradientStartPoint = CGPoint(x: 0.5, y: 0.5)
        static let glowGradientEndPoint = CGPoint(x: 1.0, y: 1.0)
        static let glowSizeMultiplier: CGFloat = 3.5
        static let glowInnerAlpha: CGFloat = 0.2
        static let glowMiddleAlpha: CGFloat = 0.08
        static let glowOuterAlpha: CGFloat = 0.0
    }
    private var barLayers: [CAGradientLayer] = []
    private let backgroundGradient: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.type = .radial
        layer.startPoint = UX.glowGradientStartPoint
        layer.endPoint = UX.glowGradientEndPoint
        return layer
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBars()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupBars() {
        layer.addSublayer(backgroundGradient)
        for _ in 0..<UX.numberOfBars {
            let barLayer = CAGradientLayer()
            barLayer.startPoint = UX.barGradientStartPoint
            barLayer.endPoint = UX.barGradientEndPoint
            barLayer.cornerRadius = UX.barCornerRadius
            layer.addSublayer(barLayer)
            barLayers.append(barLayer)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateBarFrames()
    }

    private func updateBarFrames() {
        guard barLayers.count > 1 else {
            assertionFailure("The number of bars must be greater than 1")
            return
        }
        let size = bounds.height * UX.glowSizeMultiplier
        let center = CGPoint(x: bounds.midX - size / 2, y: bounds.midY - size / 2)
        backgroundGradient.frame = CGRect(origin: center, size: .init(width: size, height: size))
        // start laying out at the center of the bounds.
        let y = (bounds.height - UX.minBarHeight) / 2

        let spacing = bounds.width / CGFloat(barLayers.count - 1)
        for (index, barLayer) in barLayers.enumerated() {
            let x = spacing * CGFloat(index) - UX.barWidth / 2
            barLayer.frame = CGRect(x: x, y: y, width: UX.barWidth, height: UX.minBarHeight)
        }
    }

    func startAnimating() {
        for (index, barLayer) in barLayers.enumerated() {
            let animation = CAKeyframeAnimation(keyPath: UX.heightAnimationKeyPath)
            animation.values = generateRandomHeights()
            animation.duration = UX.heightAnimationBaseDuration + Double(index) * UX.heightAnimationDurationCoefficient
            animation.repeatCount = .infinity
            animation.autoreverses = true
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            barLayer.add(animation, forKey: UX.heightAnimationKey)
        }
    }

    private func generateRandomHeights() -> [CGFloat] {
        if bounds.height.isZero {
            // force layout to get an height that is not zero for the random heights array,
            // otherwise it crashes.
            layoutIfNeeded()
        }
        return (0..<UX.numberOfRandomHeights).map { _ in
            CGFloat.random(in: UX.minBarHeight...bounds.height)
        }
    }

    func stopAnimating() {
        for barLayer in barLayers {
            barLayer.removeAnimation(forKey: UX.heightAnimationKey)

            // Get current on screen bar height
            let currentHeight = barLayer.presentation()?.bounds.size.height ?? UX.minBarHeight

            let animation = CABasicAnimation(keyPath: UX.heightAnimationKeyPath)
            animation.fromValue = currentHeight
            animation.toValue = UX.minBarHeight
            animation.duration = UX.stopAnimationDuration
            animation.timingFunction = CAMediaTimingFunction(name: .easeOut)

            barLayer.add(animation, forKey: UX.stopAnimationKey)
        }
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {
        let gradient = [
            theme.colors.gradientAIStrongStop1.cgColor,
            theme.colors.gradientAIStrongStop2.cgColor,
            theme.colors.gradientAIStrongStop3.cgColor
        ]
        backgroundGradient.colors = [
            theme.colors.gradientAIStrongStop2.withAlphaComponent(UX.glowInnerAlpha).cgColor,
            theme.colors.gradientAIStrongStop1.withAlphaComponent(UX.glowMiddleAlpha).cgColor,
            theme.colors.gradientAIStrongStop1.withAlphaComponent(UX.glowOuterAlpha).cgColor
        ]
        barLayers.forEach { $0.colors = gradient }
    }
}
