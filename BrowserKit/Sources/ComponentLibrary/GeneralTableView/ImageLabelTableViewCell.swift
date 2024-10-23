// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import UIKit

public protocol ImageLabelTableViewCellModel: ElementData {
    var title: String { get }
    var description: String? { get }
    var image: UIImage { get }

    // Accessibility
    var a11yLabel: String { get }
    var a11yHint: String? { get }
    var a11yId: String { get }

    // Extra props for unique type?
    var isEnabled: Bool { get }
    var isActive: Bool { get }
    var hasDisclosure: Bool { get }

    var action: (() -> Void)? { get }
}

open class ImageLabelTableViewCell<
    Model: ImageLabelTableViewCellModel
>: UITableViewCell,
   ConfigurableTableViewCell,
   ReusableCell,
   ThemeApplicable {
    public typealias E = Model

    // Static stored properties not supported in generic types :(
    private struct UXType {
        let contentMargin: CGFloat = 10
        let iconSize: CGFloat = 24
        let largeIconSize: CGFloat = 48
        let contentSpacing: CGFloat = 2
    }
    private let UX = UXType()

    private var separatorInsetSize: CGFloat {
        return UX.contentMargin * 2 + UX.iconSize
    }

    // MARK: - UI Elements
    private var titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.numberOfLines = 2
    }

    private var descriptionLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.caption1.scaledFont()
    }

    private var icon: UIImageView = .build()

    private var contentStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
    }

    private var accessoryArrowView: UIImageView = .build()

    // MARK: - Properties
    public var model: Model?

    // MARK: - Initializers
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        // FIXME can't use UX in build atm because self isn't available :/
        contentStackView.spacing = UX.contentSpacing
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func configureCellWith(model: Model) {
        self.model = model
        self.titleLabel.text = model.title
        self.descriptionLabel.text = model.description
        self.icon.image = model.image.withRenderingMode(.alwaysTemplate)
        self.accessoryArrowView.image =
        UIImage(named: StandardImageIdentifiers.Large.chevronRight)?.withRenderingMode(.alwaysTemplate)
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
        self.addSubview(accessoryArrowView)
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(descriptionLabel)
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.contentMargin),
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),

            contentStackView.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: UX.contentMargin),
            contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: UX.contentMargin),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.contentMargin),

            accessoryArrowView.leadingAnchor.constraint(equalTo: contentStackView.trailingAnchor,
                                                        constant: UX.contentMargin),
            accessoryArrowView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.contentMargin),
            accessoryArrowView.centerYAnchor.constraint(equalTo: centerYAnchor),
            accessoryArrowView.widthAnchor.constraint(equalToConstant: UX.iconSize),
            accessoryArrowView.heightAnchor.constraint(equalToConstant: UX.iconSize)
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
    open func applyTheme(theme: Theme) {
        guard let model else { return }
        backgroundColor = theme.colors.layer2

        accessoryArrowView.isHidden = !model.hasDisclosure || model.isActive ? true : false
        if model.isActive {
            titleLabel.textColor = theme.colors.textAccent
            descriptionLabel.textColor = theme.colors.textSecondary
            icon.tintColor = theme.colors.iconAccentBlue
        } else if !model.isEnabled {
            titleLabel.textColor = theme.colors.textDisabled
            descriptionLabel.textColor = theme.colors.textDisabled
            icon.tintColor = theme.colors.iconDisabled
            accessoryArrowView.tintColor = theme.colors.iconDisabled
        } else {
            titleLabel.textColor = theme.colors.textPrimary
            descriptionLabel.textColor = theme.colors.textSecondary
            icon.tintColor = theme.colors.iconSecondary
            accessoryArrowView.tintColor = theme.colors.iconSecondary
        }
    }
}
