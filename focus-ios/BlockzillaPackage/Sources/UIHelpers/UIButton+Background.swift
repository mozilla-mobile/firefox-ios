/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

public extension UIButton {
    func addBackgroundView(color: UIColor = .white, cornerRadius: CGFloat = 0, padding: CGFloat = 0) {
        backgroundColor = .clear
        let backgroundView = UIView()
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.isUserInteractionEnabled = false
        backgroundView.backgroundColor = color
        if cornerRadius > 0 {
            backgroundView.layer.cornerRadius = cornerRadius
            backgroundView.layer.masksToBounds = true
        }
        self.insertSubview(backgroundView, at: 0)

        NSLayoutConstraint.activate([
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -padding),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: padding),
            backgroundView.topAnchor.constraint(equalTo: topAnchor, constant: -padding),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: padding)
        ])

        if let imageView = self.imageView {
            imageView.backgroundColor = .clear
            self.bringSubviewToFront(imageView)
        }
    }
}
