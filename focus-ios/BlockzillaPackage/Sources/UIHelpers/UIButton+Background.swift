/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

public extension UIButton {
    func addBackgroundView(color: UIColor = .white, cornerRadius: CGFloat = 0, padding: CGFloat = 0) {
        backgroundColor = .clear
        let backgroundView = UIView()
        backgroundView.isUserInteractionEnabled = false
        backgroundView.backgroundColor = color
        if cornerRadius > 0 {
            backgroundView.layer.cornerRadius = cornerRadius
            backgroundView.layer.masksToBounds = true
        }
        self.insertSubview(backgroundView, at: 0)

        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(-padding)
        }

        if let imageView = self.imageView {
            imageView.backgroundColor = .clear
            self.bringSubviewToFront(imageView)
        }
    }
}
