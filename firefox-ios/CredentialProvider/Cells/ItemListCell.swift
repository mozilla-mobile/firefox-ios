// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class ItemListCell: UITableViewCell {
    static let identifier = "itemListCell"

    lazy var titleLabel: UILabel = .build { label in
        label.textColor = UIColor.CredentialProvider.titleColor
        label.font = .systemFont(ofSize: 16)
    }

    lazy var detailLabel: UILabel = .build { label in
        label.textColor = .systemGray
        label.font = .systemFont(ofSize: 13)
    }

    lazy var separatorView: UIView = .build { view in
        view.backgroundColor = .lightGray
        view.alpha = 0.6
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = UIColor.CredentialProvider.cellBackgroundColor
        contentView.addSubviews(titleLabel, detailLabel, separatorView)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            detailLabel.topAnchor.constraint(equalTo: titleLabel.layoutMarginsGuide.bottomAnchor, constant: 8),
            detailLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorView.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 0.8)
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        backgroundColor = selected ? .lightGray : UIColor.CredentialProvider.cellBackgroundColor
    }
}
