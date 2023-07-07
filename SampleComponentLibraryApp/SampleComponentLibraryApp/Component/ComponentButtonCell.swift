// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Common

class ComponentButtonCell: UITableViewCell {
    static var cellIdentifier: String { return String(describing: self) }

    private lazy var button: UIButton = .build { button in
        button.backgroundColor = .lightGray
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
    }

    // MARK: - Initializers
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initialViewSetup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initialViewSetup() {
        contentView.backgroundColor = .clear
        contentView.addSubview(button)

        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            button.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    func setup(_ data: ComponentViewModel) {
        button.setTitle(data.title, for: .normal)
    }
}
