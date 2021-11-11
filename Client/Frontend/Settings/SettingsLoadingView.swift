// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import SnapKit

class SettingsLoadingView: UIView {
    var searchBarHeight: CGFloat = 0 {
        didSet {
            setNeedsUpdateConstraints()
        }
    }

    lazy var indicator: UIActivityIndicatorView = {
        let isDarkTheme = LegacyThemeManager.instance.currentName == .dark
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = isDarkTheme ? .white : .systemGray
        indicator.hidesWhenStopped = false
        return indicator
    }()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(indicator)
        backgroundColor = UIColor.theme.tableView.headerBackground
        indicator.startAnimating()
    }

    internal override func updateConstraints() {
        super.updateConstraints()

        indicator.snp.remakeConstraints { make in
            make.centerX.equalTo(self)
            make.centerY.equalTo(self).offset(-(searchBarHeight / 2))
        }
    }
}
