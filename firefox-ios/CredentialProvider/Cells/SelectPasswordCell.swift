// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class SelectPasswordCell: UITableViewCell {
    static let identifier = "selectPasswordCell"

    private lazy var selectLabel: UILabel = .build { label in
        label.text = .LoginsListSelectPasswordTitle.uppercased()
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = .systemGray
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = UIColor.CredentialProvider.tableViewBackgroundColor

        contentView.addSubview(selectLabel)
        NSLayoutConstraint.activate([
            selectLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, multiplier: 1.4),
            selectLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14)
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
