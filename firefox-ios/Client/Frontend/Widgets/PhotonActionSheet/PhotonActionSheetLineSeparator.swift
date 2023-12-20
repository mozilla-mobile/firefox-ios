// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

// MARK: - PhotonActionSheetLineSeparator
class PhotonActionSheetLineSeparator: UITableViewHeaderFooterView, ReusableCell, ThemeApplicable {
    private lazy var separatorLineView: UIView = .build { _ in }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme(theme: Theme) {
        contentView.backgroundColor = .clear
        separatorLineView.backgroundColor = theme.colors.borderPrimary
    }

    // MARK: - Private
    private func setupLayout() {
        contentView.addSubview(separatorLineView)

        NSLayoutConstraint.activate([
            separatorLineView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorLineView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorLineView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            separatorLineView.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }
}
