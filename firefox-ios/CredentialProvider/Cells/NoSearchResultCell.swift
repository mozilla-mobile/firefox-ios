// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class NoSearchResultCell: UITableViewCell {
    static let identifier = "noSearchResultCell"

    private lazy var titleLabel: UILabel = .build { label in
        label.textColor = UIColor.CredentialProvider.titleColor
        label.text = .LoginsListNoMatchingResultTitle
        label.font = UIFont.systemFont(ofSize: 15)
    }

    private lazy var descriptionLabel: UILabel = .build { label in
        label.text = .LoginsListNoMatchingResultSubtitle
        label.textColor = .systemGray
        label.font = UIFont.systemFont(ofSize: 13)
        label.textAlignment = .center
        label.numberOfLines = 0
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = UIColor.CredentialProvider.tableViewBackgroundColor

        contentView.addSubviews(titleLabel, descriptionLabel)
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 55),
            descriptionLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.layoutMarginsGuide.bottomAnchor, constant: 15),
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
