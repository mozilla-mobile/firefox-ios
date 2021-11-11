// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

private struct UX {
    static let BackgroundColor = UIColor.Photon.Purple60

    // The amount of pixels the toggle button will expand over the normal size. This results in the larger -> contract animation.
    static let ExpandDelta: CGFloat = 5
    static let ShowDuration: TimeInterval = 0.4
    static let HideDuration: TimeInterval = 0.2

    static let BackgroundSize = CGSize(width: 32, height: 32)
}

class ToggleButton: UIButton {
    func setSelected(_ selected: Bool, animated: Bool = true) {
        self.isSelected = selected
        if animated {
            animateSelection(selected)
        }
    }

    fileprivate func updateMaskPathForSelectedState(_ selected: Bool) {
        let path = CGMutablePath()
        if selected {
            var rect = CGRect(size: UX.BackgroundSize)
            rect.center = maskShapeLayer.position
            path.addEllipse(in: rect)
        } else {
            path.addEllipse(in: CGRect(origin: maskShapeLayer.position, size: .zero))
        }
        self.maskShapeLayer.path = path
    }

    fileprivate func animateSelection(_ selected: Bool) {
        var endFrame = CGRect(size: UX.BackgroundSize)
        endFrame.center = maskShapeLayer.position

        if selected {
            let animation = CAKeyframeAnimation(keyPath: "path")

            let startPath = CGMutablePath()
            startPath.addEllipse(in: CGRect(origin: maskShapeLayer.position, size: .zero))

            let largerPath = CGMutablePath()
            let largerBounds = endFrame.insetBy(dx: -UX.ExpandDelta, dy: -UX.ExpandDelta)
            largerPath.addEllipse(in: largerBounds)

            let endPath = CGMutablePath()
            endPath.addEllipse(in: endFrame)

            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
            animation.values = [
                startPath,
                largerPath,
                endPath
            ]
            animation.duration = UX.ShowDuration
            self.maskShapeLayer.path = endPath
            self.maskShapeLayer.add(animation, forKey: "grow")
        } else {
            let animation = CABasicAnimation(keyPath: "path")
            animation.duration = UX.HideDuration
            animation.fillMode = CAMediaTimingFillMode.forwards

            let fromPath = CGMutablePath()
            fromPath.addEllipse(in: endFrame)
            animation.fromValue = fromPath
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)

            let toPath = CGMutablePath()
            toPath.addEllipse(in: CGRect(origin: self.maskShapeLayer.bounds.center, size: .zero))

            self.maskShapeLayer.path = toPath
            self.maskShapeLayer.add(animation, forKey: "shrink")
        }
    }

    lazy fileprivate var backgroundView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.layer.addSublayer(self.backgroundLayer)
        return view
    }()

    lazy fileprivate var maskShapeLayer: CAShapeLayer = {
        let circle = CAShapeLayer()
        return circle
    }()

    lazy fileprivate var backgroundLayer: CALayer = {
        let backgroundLayer = CALayer()
        backgroundLayer.backgroundColor = UX.BackgroundColor.cgColor
        backgroundLayer.mask = self.maskShapeLayer
        return backgroundLayer
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .redraw
        insertSubview(backgroundView, belowSubview: imageView!)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let zeroFrame = CGRect(size: frame.size)
        backgroundView.frame = zeroFrame

        // Make the gradient larger than normal to allow the mask transition to show when it blows up
        // a little larger than the resting size
        backgroundLayer.bounds = backgroundView.frame.insetBy(dx: -UX.ExpandDelta, dy: -UX.ExpandDelta)
        maskShapeLayer.bounds = backgroundView.frame
        backgroundLayer.position = CGPoint(x: zeroFrame.midX, y: zeroFrame.midY)
        maskShapeLayer.position = CGPoint(x: zeroFrame.midX, y: zeroFrame.midY)

        updateMaskPathForSelectedState(isSelected)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
