// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

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

    // To support dynamic height with multilines on a UI Button
    func makeDynamicHeightSupport() {
        guard let titleLabel = titleLabel else {
            return
        }

        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        addConstraints([
            .init(item: titleLabel,
                  attribute: .top,
                  relatedBy: .greaterThanOrEqual,
                  toItem: self,
                  attribute: .top,
                  multiplier: 1.0,
                  constant: contentEdgeInsets.top),
            .init(item: titleLabel,
                  attribute: .bottom,
                  relatedBy: .greaterThanOrEqual,
                  toItem: self,
                  attribute: .bottom,
                  multiplier: 1.0,
                  constant: contentEdgeInsets.bottom),
            .init(item: titleLabel,
                  attribute: .left,
                  relatedBy: .greaterThanOrEqual,
                  toItem: self,
                  attribute: .left,
                  multiplier: 1.0,
                  constant: contentEdgeInsets.left),
            .init(item: titleLabel,
                  attribute: .right,
                  relatedBy: .greaterThanOrEqual,
                  toItem: self,
                  attribute: .right,
                  multiplier: 1.0,
                  constant: contentEdgeInsets.right)
        ])
    }
}
