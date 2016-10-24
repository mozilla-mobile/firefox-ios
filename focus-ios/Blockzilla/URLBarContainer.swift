/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class URLBarContainer: UIView {
    let backgroundDark = GradientBackgroundView()
    let backgroundBright = GradientBackgroundView(alpha: 0.8)

    init() {
        super.init(frame: CGRect.zero)

        addSubview(backgroundDark)

        backgroundBright.isHidden = true
        backgroundBright.alpha = 0
        addSubview(backgroundBright)

        backgroundDark.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        backgroundBright.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }

    var isBright: Bool = false {
        didSet {
            backgroundDark.animateHidden(isBright, duration: 0.3)
            backgroundBright.animateHidden(!isBright, duration: 0.3)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
