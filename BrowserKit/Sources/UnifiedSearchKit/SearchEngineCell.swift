// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import UIKit

// FXIOS-10189 This class will be refactored into a generic UITableView solution later. For now, it is largely a clone of
// MenuKit's work. Eventually both this target and the MenuKit target will leverage a common reusable tableView component.
public class SearchEngineCell: UITableViewCell, ReusableCell, ThemeApplicable {
    private struct UX {
        static let contentMargin: CGFloat = 11
        static let iconSize: CGFloat = 24
        static let largeIconSize: CGFloat = 48
        static let contentSpacing: CGFloat = 5
        static let noDescriptionContentSpacing: CGFloat = 0
    }

    private var separatorInsetSize: CGFloat {
        return UX.contentMargin * 2 + UX.iconSize
    }

    // MARK: - UI Elements
    private var titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.numberOfLines = 2
    }

    private var icon: UIImageView = .build()

    private var contentStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
    }

    private var accessoryArrowView: UIImageView = .build()

    // MARK: - Properties
    public var model: SearchEngineElement?

    // MARK: - Initializers
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configureCellWith(model: SearchEngineElement) {
        self.model = model
        self.titleLabel.text = model.title
        self.contentStackView.spacing = UX.noDescriptionContentSpacing
        self.icon.image = model.image
        self.isAccessibilityElement = true
        self.accessibilityIdentifier = model.a11yId
        self.accessibilityLabel = model.a11yLabel
        self.accessibilityHint = model.a11yHint
        self.separatorInset = UIEdgeInsets(top: 0, left: separatorInsetSize, bottom: 0, right: 0)
        setupView()
    }

    private func setupView() {
        self.addSubview(icon)
        self.addSubview(contentStackView)
        contentStackView.addArrangedSubview(titleLabel)
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.contentMargin),
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),

            contentStackView.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: UX.contentMargin),
            contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: UX.contentMargin),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.contentMargin),
        ])
        adjustLayout(isAccessibilityCategory: UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory)
    }

    private func adjustLayout(isAccessibilityCategory: Bool) {
        let iconSize = isAccessibilityCategory ? UX.largeIconSize : UX.iconSize
        icon.widthAnchor.constraint(equalToConstant: iconSize).isActive = true
        icon.heightAnchor.constraint(equalToConstant: iconSize).isActive = true
    }

    func performAction() {
        guard let action = model?.action else { return }
        action()
    }

    // MARK: - Theme Applicable
    public func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layer2
        titleLabel.textColor = theme.colors.textPrimary
        icon.tintColor = theme.colors.iconSecondary
        accessoryArrowView.tintColor = theme.colors.iconSecondary
    }
}
