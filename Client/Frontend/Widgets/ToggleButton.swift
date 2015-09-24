/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

private struct UX {
    static let TopColor = UIColor(red: 179 / 255, green: 83 / 255, blue: 253 / 255, alpha: 1)
    static let BottomColor = UIColor(red: 146 / 255, green: 16 / 255, blue: 253, alpha: 1)
    static let LargerScale =  NSValue(CATransform3D: CATransform3DMakeScale(1.2, 1.2, 1))
    static let ShowDuration: NSTimeInterval = 0.4
    static let HideDuration: NSTimeInterval = 0.2
    static let BackgroundInset: CGFloat = 4
    static let CornerRadius: CGFloat = 10
}

class ToggleButton: UIButton {
    override var selected: Bool {
        didSet {
            if selected {
                self.gradientLayer.bounds = CGRectMake(0, 0, backgroundView.frame.size.width, backgroundView.frame.size.height)
            } else {
                self.gradientLayer.bounds = CGRectZero
            }
        }
    }

    func setSelected(selected: Bool, animated: Bool = true) {
        self.selected = selected
        if animated {
            animateSelection(selected)
        }
    }

    private var zeroBackgroundFrame: CGRect {
        return CGRect(x: 0, y: 0, width: backgroundView.frame.size.width, height: backgroundView.frame.size.height)
    }

    private func animateSelection(selected: Bool) {
        if selected {
            let animation = CAKeyframeAnimation(keyPath: "bounds")
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            animation.values = [
                NSValue(CGRect: CGRectZero),
                NSValue(CGRect: CGRectApplyAffineTransform(zeroBackgroundFrame, CGAffineTransformMakeScale(1.4, 1.4))),
                NSValue(CGRect: zeroBackgroundFrame)
            ]
            animation.duration = UX.ShowDuration
            animation.fillMode = kCAFillModeForwards

            self.gradientLayer.bounds = zeroBackgroundFrame
            self.gradientLayer.addAnimation(animation, forKey: "show")
        } else {
            let animation = CABasicAnimation(keyPath: "bounds")
            animation.duration = UX.HideDuration
            animation.fillMode = kCAFillModeForwards
            animation.fromValue = NSValue(CGRect: zeroBackgroundFrame)
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)

            self.gradientLayer.bounds = CGRectZero
            self.gradientLayer.addAnimation(animation, forKey: "hide")
        }
    }

    lazy private var backgroundView: UIView = {
        let view = UIView()
        view.userInteractionEnabled = false
        view.layer.addSublayer(self.gradientLayer)
        return view
    }()

    lazy private var gradientLayer: CAGradientLayer = {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UX.TopColor.CGColor, UX.BottomColor.CGColor]
        return gradientLayer
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = UIViewContentMode.Redraw
        insertSubview(backgroundView, belowSubview: imageView!)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let zeroFrame = CGRectMake(0, 0, frame.size.width, frame.size.height)
        backgroundView.frame = CGRectInset(zeroFrame, UX.BackgroundInset, UX.BackgroundInset)
        gradientLayer.position = CGPoint(x: zeroBackgroundFrame.size.width / 2, y: zeroBackgroundFrame.size.height / 2)
        gradientLayer.cornerRadius = UX.CornerRadius
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}