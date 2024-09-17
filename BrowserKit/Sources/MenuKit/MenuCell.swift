// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import UIKit

public class MenuCell: UITableViewCell, ReusableCell, ThemeApplicable {
    private struct UX {
        static let contentMargin: CGFloat = 10
        static let iconSize: CGFloat = 24
        static let iconMargin: CGFloat = 25
        static let contentSpacing: CGFloat = 2
    }

    // MARK: - UI Elements
    private var titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
    }

    private var descriptionLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.caption1.scaledFont()
    }

    private var icon: UIImageView = .build()

    private var contentStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.spacing = UX.contentSpacing
    }

    // MARK: - Properties
    public var model: MenuElement?

    // MARK: - Initializers
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configureCellWith(model: MenuElement) {
        self.model = model
        self.titleLabel.text = model.title
        self.descriptionLabel.text = model.a11yLabel // TODO: to be updated with the correct value
        self.icon.image = UIImage(named: model.iconName)
        setupView()
    }

    private func setupView() {
        self.addSubview(icon)
        self.addSubview(contentStackView)
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(descriptionLabel)
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.iconMargin),
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: UX.iconSize),
            icon.heightAnchor.constraint(equalToConstant: UX.iconSize),

            contentStackView.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: UX.contentMargin),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.contentMargin),
            contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: UX.contentMargin),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.contentMargin)
        ])
    }

    func performAction() {
        guard let action = model?.action else { return }
        action()
    }

    // TODO: FXIOS-10022 ⁃ Add themeing to the menu (applying this method remained)
    public func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layer2
        titleLabel.textColor = theme.colors.textPrimary
        descriptionLabel.textColor = theme.colors.textSecondary
    }
}
