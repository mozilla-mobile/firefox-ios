/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

private struct UX {
    static let TopColor = UIColor(red: 179 / 255, green: 83 / 255, blue: 253 / 255, alpha: 1)
    static let BottomColor = UIColor(red: 146 / 255, green: 16 / 255, blue: 253, alpha: 1)

    // The amount of pixels the toggle button will expand over the normal size. This results in the larger -> contract animation.
    static let ExpandDelta: CGFloat = 5
    static let ShowDuration: NSTimeInterval = 0.4
    static let HideDuration: NSTimeInterval = 0.2

    static let BackgroundSize = CGSize(width: 32, height: 32)
}

class ToggleButton: UIButton {
    func setSelected(selected: Bool, animated: Bool = true) {
        self.selected = selected
        if animated {
            animateSelection(selected)
        }
    }

    private func updateMaskPathForSelectedState(selected: Bool) {
        let path = CGPathCreateMutable()
        if selected {
            var rect = CGRect(origin: CGPointZero, size: UX.BackgroundSize)
            rect.center = maskShapeLayer.position
            CGPathAddEllipseInRect(path, nil, rect)
        } else {
            CGPathAddEllipseInRect(path, nil, CGRect(origin: maskShapeLayer.position, size: CGSizeZero))
        }
        self.maskShapeLayer.path = path
    }

    private func animateSelection(selected: Bool) {
        var endFrame = CGRect(origin: CGPointZero, size: UX.BackgroundSize)
        endFrame.center = maskShapeLayer.position

        if selected {
            let animation = CAKeyframeAnimation(keyPath: "path")

            let startPath = CGPathCreateMutable()
            CGPathAddEllipseInRect(startPath, nil, CGRect(origin: maskShapeLayer.position, size: CGSizeZero))

            let largerPath = CGPathCreateMutable()
            let largerBounds = CGRectInset(endFrame, -UX.ExpandDelta, -UX.ExpandDelta)
            CGPathAddEllipseInRect(largerPath, nil, largerBounds)

            let endPath = CGPathCreateMutable()
            CGPathAddEllipseInRect(endPath, nil, endFrame)

            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            animation.values = [
                startPath,
                largerPath,
                endPath
            ]
            animation.duration = UX.ShowDuration
            self.maskShapeLayer.path = endPath
            self.maskShapeLayer.addAnimation(animation, forKey: "grow")
        } else {
            let animation = CABasicAnimation(keyPath: "path")
            animation.duration = UX.HideDuration
            animation.fillMode = kCAFillModeForwards

            let fromPath = CGPathCreateMutable()
            CGPathAddEllipseInRect(fromPath, nil, endFrame)
            animation.fromValue = fromPath
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)

            let toPath = CGPathCreateMutable()
            CGPathAddEllipseInRect(toPath, nil, CGRect(origin: self.maskShapeLayer.bounds.center, size: CGSizeZero))

            self.maskShapeLayer.path = toPath
            self.maskShapeLayer.addAnimation(animation, forKey: "shrink")
        }
    }

    lazy private var backgroundView: UIView = {
        let view = UIView()
        view.userInteractionEnabled = false
        view.layer.addSublayer(self.gradientLayer)
        return view
    }()

    lazy private var maskShapeLayer: CAShapeLayer = {
        let circle = CAShapeLayer()
        return circle
    }()

    lazy private var gradientLayer: CAGradientLayer = {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UX.TopColor.CGColor, UX.BottomColor.CGColor]
        gradientLayer.mask = self.maskShapeLayer
        return gradientLayer
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = UIViewContentMode.Redraw
        insertSubview(backgroundView, belowSubview: imageView!)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let zeroFrame = CGRect(origin: CGPointZero, size: frame.size)
        backgroundView.frame = zeroFrame

        // Make the gradient larger than normal to allow the mask transition to show when it blows up
        // a little larger than the resting size
        gradientLayer.bounds = CGRectInset(backgroundView.frame, -UX.ExpandDelta, -UX.ExpandDelta)
        maskShapeLayer.bounds = backgroundView.frame
        gradientLayer.position = CGPoint(x: CGRectGetMidX(zeroFrame), y: CGRectGetMidY(zeroFrame))
        maskShapeLayer.position = CGPoint(x: CGRectGetMidX(zeroFrame), y: CGRectGetMidY(zeroFrame))

        updateMaskPathForSelectedState(selected)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}