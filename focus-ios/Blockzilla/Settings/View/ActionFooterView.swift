/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class ActionFooterView: UIView {
    lazy var textLabel: UILabel = {
        let label = UILabel()
        label.textColor = .secondaryLabel
        label.font = .preferredFont(forTextStyle: .footnote)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()

    lazy var detailTextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(.accent, for: .normal)
        button.setTitleColor(.accent, for: .highlighted)
        button.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.numberOfLines = 0
        return button
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [textLabel, detailTextButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 0
        stackView.alignment = .leading
        stackView.axis = .vertical
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: self.topAnchor, constant: UIConstants.layout.settingsVerticalOffset),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -UIConstants.layout.settingsVerticalOffset),
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: UIConstants.layout.settingsHorizontalOffset),
            stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -UIConstants.layout.settingsHorizontalOffset)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
