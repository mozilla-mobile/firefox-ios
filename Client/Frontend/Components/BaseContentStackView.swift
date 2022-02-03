// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol AlphaDimmable {
    func updateAlphaForSubviews(_ alpha: CGFloat)
}

class BaseAlphaStackView: UIStackView, AlphaDimmable {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStyle()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateAlphaForSubviews(_ alpha: CGFloat) {
        for subview in arrangedSubviews {
            guard let alphaView = subview as? AlphaDimmable else { continue }
            print("Laurie - Update alpha for view \(subview.debugDescription)")
            alphaView.updateAlphaForSubviews(alpha)
        }
    }

    private func setupStyle() {
        backgroundColor = .clear
        axis = .vertical
        distribution = .fillProportionally
    }
}
