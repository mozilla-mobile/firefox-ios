// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

// MARK: - PhotonActionSheetTitleHeaderView
class PhotonActionSheetTitleHeaderView: UITableViewHeaderFooterView, ReusableCell, ThemeApplicable {
    struct UX {
        static let padding: CGFloat = 18
    }

    lazy var titleLabel: UILabel = .build { label in
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .caption1, size: 12)
        label.numberOfLines = 1
    }

    lazy var separatorView: UIView = .build { _ in }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with title: String) {
        titleLabel.text = title
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
    }

    func applyTheme(theme: Theme) {
        separatorView.backgroundColor = theme.colors.borderPrimary
        titleLabel.textColor = theme.colors.textSecondary
    }

    // MARK: - Private
    private func setupLayout() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(separatorView)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UX.padding),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor,
                                            constant: PhotonActionSheet.UX.tablePadding),

            separatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor,
                                               constant: PhotonActionSheet.UX.tablePadding),
            separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                  constant: PhotonActionSheet.UX.tablePadding),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }
}
