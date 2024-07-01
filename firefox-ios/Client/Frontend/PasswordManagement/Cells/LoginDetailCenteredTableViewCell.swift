// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import Common

struct LoginDetailCenteredTableViewCellModel {
    let label: String
}

class LoginDetailCenteredTableViewCell: UITableViewCell, ThemeApplicable, ReusableCell {
    struct UX {
        static let spacingTopBottom: CGFloat = 26
        static let spacingLeadingTrailing: CGFloat = 16
    }

    private var viewModel: LoginDetailCenteredTableViewCellModel?

    private lazy var centeredLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.caption1.scaledFont()
        label.textAlignment = .center
        label.numberOfLines = 0
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupLayout()
    }

    func configure(viewModel: LoginDetailCenteredTableViewCellModel) {
        self.viewModel = viewModel
        centeredLabel.text = viewModel.label
        selectionStyle = .none
    }

    func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layer1
        centeredLabel.textColor = theme.colors.textSecondary
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private
    private func setupLayout() {
        contentView.addSubview(centeredLabel)

        NSLayoutConstraint.activate([
            centeredLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                   constant: UX.spacingLeadingTrailing),
            centeredLabel.topAnchor.constraint(equalTo: contentView.topAnchor,
                                               constant: UX.spacingTopBottom),
            centeredLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                    constant: -UX.spacingLeadingTrailing),
            centeredLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                  constant: -UX.spacingTopBottom)
        ])
    }
}
