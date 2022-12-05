// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

// MARK: - PhotonActionSheetLineSeparator
class PhotonActionSheetLineSeparator: UITableViewHeaderFooterView, ReusableCell, ThemeApplicable {

    private let separatorLineView = UIView()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        self.backgroundView = UIView()
        self.backgroundView?.backgroundColor = .clear
        self.contentView.addSubview(separatorLineView)

        separatorLineView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.centerY.equalTo(self)
            make.height.equalTo(0.5)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme(theme: Theme) {
        separatorLineView.backgroundColor = theme.colors.layerLightGrey30
    }
}
