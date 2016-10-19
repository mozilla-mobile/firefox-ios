/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

protocol HomeViewDelegate: class {
    func homeViewDidPressSettings(homeView: HomeView)
}

class HomeView: UIView {
    weak var delegate: HomeViewDelegate?

    init() {
        super.init(frame: CGRect.zero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didPressSettings() {
        delegate?.homeViewDidPressSettings(homeView: self)
    }
}
