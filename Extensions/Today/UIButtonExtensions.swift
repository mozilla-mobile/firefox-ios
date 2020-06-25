/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

extension UIButton {
func performGradient(colorOne: UIColor, colorTwo: UIColor, colorThree: UIColor) {
    let gradientLayer = CAGradientLayer()
    gradientLayer.frame = self.frame
    gradientLayer.colors = [colorOne.cgColor, colorTwo.cgColor, colorThree.cgColor]
    gradientLayer.startPoint = CGPoint(x: 1.0, y: 0.0)
    gradientLayer.endPoint = CGPoint(x: 0.0, y: 1.0)
    gradientLayer.locations = [0.0, 0.5, 1.0]
    gradientLayer.cornerRadius = self.frame.size.width/2
    layer.masksToBounds = true
    layer.insertSublayer(gradientLayer, below: self.imageView?.layer)
    }
}

extension UIButton {
    func setBackgroundColor(_ color: UIColor, forState state: UIControl.State) {
        let colorView = UIView(frame: CGRect(width: 1, height: 1))
        colorView.backgroundColor = color

        UIGraphicsBeginImageContext(colorView.bounds.size)
        if let context = UIGraphicsGetCurrentContext() {
            colorView.layer.render(in: context)
        }
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        self.setBackgroundImage(colorImage, for: state)
    }
}
