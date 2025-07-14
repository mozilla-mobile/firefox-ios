// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

let summarizeRed = UIColor(colorString: "FF0048")

class AnimatedGradientOutlineView: UIView,
                                   CAAnimationDelegate {
    struct UX {
        static let blue = UIColor(colorString: "72D3FF").withAlphaComponent(0.8).cgColor
        static let clearRed = UIColor(colorString: "FF0048").withAlphaComponent(0.8).cgColor
        static let red = summarizeRed.cgColor
        static let clearOrange = UIColor(colorString: "FF4C00").withAlphaComponent(0.8).cgColor
        static let orange = UIColor(colorString: "FF4C00").cgColor
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
            UX.clearOrange,
            UX.blue,
            UX.clearRed
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.locations = [0.0, 0.8, 1.0]
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
        let animation = CABasicAnimation(keyPath: "colors")
        animation.fromValue = gradientLayer.colors
        animation.toValue = [
            UX.clearOrange,
            UX.clearRed,
            UX.blue
        ]
        animation.duration = 1.0
        animation.repeatCount = 0
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        animation.fillMode = .forwards
        animation.delegate = self
        animation.isRemovedOnCompletion = false
        gradientLayer.add(animation, forKey: "animateGradient")
    }

    private func endAnimation() {
        let endAnimation = CABasicAnimation(keyPath: "colors")
        endAnimation.fromValue = [
            UX.clearOrange,
            UX.clearRed,
            UX.blue
        ]
        endAnimation.toValue = [UX.red, UX.clearOrange, UX.blue]
        endAnimation.repeatCount = 0
        endAnimation.duration = 0.8
        endAnimation.fillMode = .forwards
        endAnimation.isRemovedOnCompletion = false
        gradientLayer.add(endAnimation, forKey: "finalAnimation")
    }

    // MARK: - Animation Delegate

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        guard flag, let animation = anim as? CABasicAnimation, animation.keyPath == "colors" else { return }
        onAnimationEnd?()
    }

    func animatePositionChange(animationCurve: CAMediaTimingFunction) {
        fadeLayer.changeOffset(topEdge: 140.0)
        let startPointAnimation = CABasicAnimation(keyPath: "startPoint")
        startPointAnimation.fromValue = CGPoint(x: 0.5, y: 0.0)
        startPointAnimation.toValue = CGPoint(x: 1.0, y: 0.3)
        startPointAnimation.duration = 1.25
        startPointAnimation.isRemovedOnCompletion = false
        startPointAnimation.fillMode = .forwards
        startPointAnimation.beginTime = CACurrentMediaTime() + 0.5
        gradientLayer.add(startPointAnimation, forKey: "startPointAnimation")

        let directionAnimation = CABasicAnimation(keyPath: "endPoint")
        directionAnimation.fromValue = CGPoint(x: 0.5, y: 1.0)
        directionAnimation.toValue = CGPoint(x: 0.0, y: 0.8)
        directionAnimation.duration = 1.25
        directionAnimation.isRemovedOnCompletion = false
        directionAnimation.fillMode = .forwards
        directionAnimation.timingFunction = animationCurve
        gradientLayer.add(directionAnimation, forKey: "directionAnimation")
    }
}
