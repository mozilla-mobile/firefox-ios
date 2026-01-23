// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

final class GradientCircleView: UIView, ThemeApplicable {
    private struct UX {
        static let gradientStartPoint = CGPoint(x: 1.0, y: 0.5)
        static let gradientEndPoint = CGPoint(x: 0.0, y: 0.5)
        static let colorsInitialLocation: [NSNumber] = [0.0, 0.5, 1.0]
        static let colorsAnimationLocation: [NSNumber] = [-0.5, 0.0, 0.5]
        static let locationAnimationDuration: CFTimeInterval = 2.5
        static let locationAnimationKey = "locationsAnimation"
        static let locationAnimationKeyPath = "locations"
        static let opacityAnimationKey = "opacityAnimation"
        static let opacityAnimationKeyPath = "opacity"
        static let initialAnimationOpacity = 0.6
        static let finalAnimationOpacity: CGFloat = 1.0
        static let opacityAnimationDuration: CFTimeInterval = 3.0
    }
    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupGradient() {
        gradientLayer.type = .axial
        gradientLayer.startPoint = UX.gradientStartPoint
        gradientLayer.endPoint = UX.gradientEndPoint
        gradientLayer.locations = UX.colorsInitialLocation
        layer.addSublayer(gradientLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // apply same width for height to render the gradient as a circle
        gradientLayer.frame = CGRect(
            origin: .zero,
            size: CGSize(
                width: bounds.width,
                height: bounds.width
            )
        )
        gradientLayer.cornerRadius = bounds.width / 2
    }
    
    func startAnimating() {
        let locationAnimation = CABasicAnimation(keyPath: UX.locationAnimationKeyPath)
        locationAnimation.fromValue = UX.colorsInitialLocation
        locationAnimation.toValue = UX.colorsAnimationLocation
        locationAnimation.duration = UX.locationAnimationDuration
        locationAnimation.autoreverses = true
        locationAnimation.repeatCount = .infinity
        locationAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        let opacityAnimation = CABasicAnimation(keyPath: UX.opacityAnimationKeyPath)
        opacityAnimation.fromValue = UX.initialAnimationOpacity
        opacityAnimation.toValue = UX.finalAnimationOpacity
        opacityAnimation.duration = UX.opacityAnimationDuration
        opacityAnimation.autoreverses = true
        opacityAnimation.repeatCount = .infinity
        opacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        gradientLayer.add(locationAnimation, forKey: UX.locationAnimationKey)
        gradientLayer.add(opacityAnimation, forKey: UX.opacityAnimationKey)
    }
    
    func stopAnimating() {
        gradientLayer.removeAnimation(forKey: UX.locationAnimationKey)
        gradientLayer.removeAnimation(forKey: UX.opacityAnimationKey)
    }
    
    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {
        gradientLayer.colors = [
            theme.colors.gradientOnboardingStop2.cgColor,
            theme.colors.gradientOnboardingStop3.cgColor,
            theme.colors.gradientOnboardingStop4.cgColor
        ]
    }
}
