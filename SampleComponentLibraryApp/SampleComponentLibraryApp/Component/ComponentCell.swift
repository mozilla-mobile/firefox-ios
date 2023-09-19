// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Common

class ComponentCell: UITableViewCell, ThemeApplicable {
    static var cellIdentifier: String { return String(describing: self) }

    private lazy var label: UILabel = .build { label in
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.textAlignment = .center
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
        contentView.addSubview(label)

        NSLayoutConstraint.activate([
            label.heightAnchor.constraint(greaterThanOrEqualToConstant: 32),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    func setup(_ data: ComponentViewModel) {
        label.text = data.title
    }

    // MARK: ThemeApplicable

    func applyTheme(theme: Theme) {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        label.backgroundColor = theme.colors.actionPrimary
        label.textColor = theme.colors.textInverted
    }
}
