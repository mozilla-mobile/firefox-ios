// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

struct GradientColors {
    static let red = UIColor(colorString: "FF0048")
    static let clearRed = UIColor(colorString: "FF0048").withAlphaComponent(0.8)
    static let clearOrange = UIColor(colorString: "FF4C00").withAlphaComponent(0.8)
    static let orange = UIColor(colorString: "FF4C00")
    static let blue = UIColor(colorString: "72D3FF").withAlphaComponent(0.8)
}

class AnimatedGradientOutlineView: UIView,
                                   CAAnimationDelegate {
    struct UX {
        static let positionChangeAnimationDuration: CFTimeInterval = 1.25
        static let startPointFinalAnimationValue = CGPoint(x: 1.0, y: 0.3)
        static let endPointFinalAnimationValue = CGPoint(x: 0.0, y: 0.8)
        static let colorsLocation = [NSNumber(0.0), NSNumber(0.8), NSNumber(1.0)]
        static let colorsKeyPath = "colors"
        static let startPointKeyPath = "startPoint"
        static let endPointKeyPath = "endPoint"
    }

    private let gradientLayer = CAGradientLayer()
    private let shapeLayer = CAShapeLayer()
    let fadeLayer = RectangularFadeMaskLayer()
    private let compositeMaskLayer = CALayer()
    private var screenCornerRadius: CGFloat {
        return UIScreen.main.value(forKey: "_displayCornerRadius") as? CGFloat ?? 0.0
    }
    private var onAnimationEnd: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayers() {
        backgroundColor = .clear

        gradientLayer.colors = [
            GradientColors.clearOrange.cgColor,
            GradientColors.blue.cgColor,
            GradientColors.clearRed.cgColor
        ]
        gradientLayer.startPoint = CGPoint.topCenter
        gradientLayer.endPoint = CGPoint.bottomCenter
        gradientLayer.locations = UX.colorsLocation
        layer.addSublayer(gradientLayer)

        gradientLayer.mask = fadeLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        gradientLayer.frame = bounds
        fadeLayer.frame = bounds
        compositeMaskLayer.frame = bounds

        let path = UIBezierPath(roundedRect: bounds, cornerRadius: screenCornerRadius)
        shapeLayer.path = path.cgPath
        shapeLayer.frame = bounds
    }

    func startAnimating(_ completion: (() -> Void)? = nil) {
        onAnimationEnd = completion
        let animation = CABasicAnimation(keyPath: UX.colorsKeyPath)
        animation.fromValue = gradientLayer.colors
        animation.toValue = [
            GradientColors.clearOrange.cgColor,
            GradientColors.clearRed.cgColor,
            GradientColors.blue.cgColor
        ]
        animation.duration = 1.0
        animation.repeatCount = 0
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        animation.fillMode = .forwards
        animation.delegate = self
        animation.isRemovedOnCompletion = false
        gradientLayer.add(animation, forKey: "animateGradient")
    }

    // MARK: - Animation Delegate

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        guard flag,
              let animation = anim as? CABasicAnimation,
              animation.keyPath == UX.colorsKeyPath else { return }
        onAnimationEnd?()
    }

    func animatePositionChange(animationCurve: CAMediaTimingFunction) {
        fadeLayer.animateFadeDown()
        let startPointAnimation = CABasicAnimation(keyPath: UX.startPointKeyPath)
        startPointAnimation.fromValue = CGPoint.topCenter
        startPointAnimation.toValue = UX.startPointFinalAnimationValue
        startPointAnimation.duration = UX.positionChangeAnimationDuration
        startPointAnimation.isRemovedOnCompletion = false
        startPointAnimation.fillMode = .forwards
        startPointAnimation.beginTime = CACurrentMediaTime() + 0.5
        gradientLayer.add(startPointAnimation, forKey: "startPointAnimation")

        let endPointAnimation = CABasicAnimation(keyPath: UX.endPointKeyPath)
        endPointAnimation.fromValue = CGPoint.bottomCenter
        endPointAnimation.toValue = UX.endPointFinalAnimationValue
        endPointAnimation.duration = UX.positionChangeAnimationDuration
        endPointAnimation.isRemovedOnCompletion = false
        endPointAnimation.fillMode = .forwards
        endPointAnimation.timingFunction = animationCurve
        gradientLayer.add(endPointAnimation, forKey: "endPointAnimation")
    }
}
