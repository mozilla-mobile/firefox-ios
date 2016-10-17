/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class GradientBackgroundView: UIView {
    private let gradient = CAGradientLayer()

    init() {
        super.init(frame: CGRect.zero)

        backgroundColor = UIConstants.colors.gradientBackground
        gradient.startPoint = CGPoint.zero
        gradient.endPoint = CGPoint(x: 1, y: 0)
        gradient.colors = [UIConstants.colors.gradientLeft.cgColor, UIConstants.colors.gradientRight.cgColor]
        layer.insertSublayer(gradient, at: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
    }
}
