/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class HomeViewToolbar: UIView {
    private let stackView = UIStackView()

    init() {
        super.init(frame: CGRect.zero)
        stackView.distribution = .fill
        stackView.addArrangedSubview(UIView())
        addSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.top.equalTo(self)
            make.left.equalTo(self).offset(UIConstants.layout.urlBarMargin)
            make.right.equalTo(self).offset(-UIConstants.layout.urlBarMargin)
            make.height.equalTo(UIConstants.layout.browserToolbarHeight)
            make.bottom.equalTo(safeAreaLayoutGuide)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
