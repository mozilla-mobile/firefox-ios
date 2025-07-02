// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import UIKit

extension UIView {
    func startShimmering() {
        let light = UIColor.white.withAlphaComponent(0.1).cgColor
        let dark = UIColor.black.cgColor

        let gradient = CAGradientLayer()
        gradient.colors = [dark, light, dark]
        gradient.frame = CGRect(
            x: -bounds.size.width,
            y: 0,
            width: 3 * bounds.size.width,
            height: bounds.size.height
        )
        gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradient.locations = [0.4, 0.5, 0.6]
        layer.mask = gradient

        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [0.0, 0.1, 0.2]
        animation.toValue = [0.8, 0.9, 1.0]

        animation.duration = 1.5
        animation.repeatCount = HUGE
        gradient.add(animation, forKey: "shimmer")
    }

    func stopShimmering() {
        layer.mask = nil
    }
}


class RectangularFadeMaskLayer: CALayer {
    private struct UX {
        static let defaultEdgeFade: CGFloat = 110.0
    }

    let horizontal = CAGradientLayer()
    let vertical = CAGradientLayer()

    override func layoutSublayers() {
        super.layoutSublayers()

        // Clean up old layers
        sublayers?.forEach { $0.removeFromSuperlayer() }

        // Horizontal fade (left → center ← right)
        horizontal.frame = bounds
        horizontal.colors = [
            UIColor.white.cgColor,
            UIColor.clear.cgColor,
            UIColor.clear.cgColor,
            UIColor.white.cgColor,
        ]
        horizontal.locations = [
            0.0,
            NSNumber(value: Float(UX.defaultEdgeFade / bounds.width)),
            NSNumber(value: Float(1 - UX.defaultEdgeFade / bounds.width)),
            1.0
        ]
        horizontal.startPoint = CGPoint(x: 0.0, y: 0.5)
        horizontal.endPoint = CGPoint(x: 1.0, y: 0.5)

        // Vertical fade (top → center ← bottom)

        vertical.frame = bounds
        vertical.colors = horizontal.colors
        vertical.locations = [
            0.0,
            NSNumber(value: Float(UX.defaultEdgeFade / bounds.height)),
            NSNumber(value: Float(1 - UX.defaultEdgeFade / bounds.height)),
            1.0
        ]
        vertical.startPoint = CGPoint(x: 0.5, y: 0.0)
        vertical.endPoint = CGPoint(x: 0.5, y: 1.0)

        // Multiply the two layers using compositing filter
        let mask = CALayer()
        mask.frame = bounds
        mask.compositingFilter = "multiplyBlendMode"
        mask.addSublayer(horizontal)
        mask.addSublayer(vertical)

        addSublayer(mask)
    }

    func changeOffset(topEdge: CGFloat) {
        let animation = CABasicAnimation(keyPath: "colors")
        animation.fromValue = vertical.colors
        animation.toValue = [
            UIColor.white.cgColor,
            UIColor.white.cgColor,
            UIColor.clear.cgColor,
            UIColor.white.cgColor,
        ]
        animation.duration = 0.8
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        vertical.add(animation, forKey: "lowerAnimation")
    }
}

class AnimatedGradientOutlineView: UIView,
                                   CAAnimationDelegate {
    private struct UX {
        static let blue = UIColor(colorString: "72D3FF").withAlphaComponent(0.8).cgColor
        static let clearRed = UIColor(colorString: "FF0048").withAlphaComponent(0.8).cgColor
        static let red = UIColor(colorString: "FF0048").cgColor
        static let clearOrange = UIColor(colorString: "FF4C00").withAlphaComponent(0.8).cgColor
        static let orange = UIColor(colorString: "FF4C00").cgColor
    }

    private let gradientLayer = CAGradientLayer()
    private let shapeLayer = CAShapeLayer()
    let fadeLayer = RectangularFadeMaskLayer()
    private let compositeMaskLayer = CALayer()
    private var screenRadius: CGFloat {
        return 70.0
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

        // 1. 🌈 Vertical Gradient (top → bottom)
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

        let path = UIBezierPath(roundedRect: bounds, cornerRadius: screenRadius)
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
        fadeLayer.changeOffset(topEdge: 0.0)
        gradientLayer.colors = [
            UX.clearOrange,
            UX.clearRed,
            UX.blue
        ]
        onAnimationEnd?()
        endAnimation()
    }
}

public class SummarizeController: UIViewController {
    private let label = UILabel()
    private let debugButton = UIButton()
    lazy var gradient = AnimatedGradientOutlineView(frame: view.bounds)
    public var onDismiss: (() -> Void)?
    public var onShouldTransformContainer: (() -> Void)?

    override public func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(gradient)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Summaraizing..."
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50.0),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
        label.isHidden = true
        gradient.startAnimating {
            self.onShouldTransformContainer?()
            self.label.isHidden = false
            self.label.startShimmering()
        }

        debugButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        debugButton.addAction(
            UIAction(handler: { [weak self] _ in
                self?.onDismiss?()
            }),
            for: .touchUpInside
        )
        debugButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(debugButton)
        NSLayoutConstraint.activate([
            debugButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20.0),
            debugButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20.0)
        ])
    }

    public override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        onDismiss?()
    }
}
