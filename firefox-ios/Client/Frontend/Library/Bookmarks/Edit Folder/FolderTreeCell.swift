// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

final class FolderTreeCell: UITableViewCell, ReusableCell, ThemeApplicable {
    struct UX {
        static let imageSize: CGFloat = 29
        static let borderViewMargin: CGFloat = 16
        static let verticalMargin: CGFloat = 8
        static let leftImageViewSize: CGFloat = 28
        static let longLeadingMargin: CGFloat = 13
        static let labelMargin: CGFloat = {
            if #available(iOS 26.0, *) {
                return 8
            } else {
                return 4
            }
        }()
        static let breadcrumbTopSpacing: CGFloat = 1
    }

    private lazy var selectedView: UIView = .build { _ in }
    private lazy var containerView: UIView = .build { _ in }

    lazy var leftImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
    }

    lazy var titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
    }

    lazy var breadcrumbLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.caption1.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
    }

    private lazy var textStackView: UIStackView = .build { stack in
        stack.axis = .vertical
        stack.spacing = UX.breadcrumbTopSpacing
    }

    private var leftImageViewLeadingConstraint: NSLayoutConstraint?

    override var indentationLevel: Int {
        didSet { setMargin() }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        breadcrumbLabel.text = nil
        breadcrumbLabel.isHidden = true
        leftImageView.image = nil
        accessoryType = .none
        indentationLevel = 0
    }

    private func setMargin() {
        if indentationLevel == 0 {
            leftImageViewLeadingConstraint?.constant = UX.borderViewMargin
        } else {
            let indentationLevelMargin = UX.borderViewMargin + UX.imageSize + UX.longLeadingMargin
            let indentSize = UX.imageSize + UX.longLeadingMargin
            let indentLevel = indentSize * CGFloat(indentationLevel - 1)
            leftImageViewLeadingConstraint?.constant = indentationLevelMargin + indentLevel
        }
    }

    private func setupLayout() {
        selectionStyle = .default

        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(breadcrumbLabel)

        containerView.addSubviews(leftImageView, textStackView)
        contentView.addSubview(containerView)

        leftImageViewLeadingConstraint = leftImageView.leadingAnchor.constraint(
            equalTo: containerView.leadingAnchor,
            constant: UX.borderViewMargin
        )
        let imageViewDynamicSize = min(UIFontMetrics.default.scaledValue(for: UX.leftImageViewSize),
                                       2 * UX.leftImageViewSize)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UX.verticalMargin),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -UX.verticalMargin),

            leftImageViewLeadingConstraint,
            leftImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            leftImageView.widthAnchor.constraint(equalToConstant: imageViewDynamicSize),
            leftImageView.heightAnchor.constraint(equalToConstant: imageViewDynamicSize),
            leftImageView.trailingAnchor.constraint(equalTo: textStackView.leadingAnchor,
                                                    constant: -UX.longLeadingMargin),

            textStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: UX.labelMargin),
            textStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -UX.labelMargin),
            textStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor,
                                                    constant: -UX.borderViewMargin)
        ].compactMap { $0 })

        selectedBackgroundView = selectedView
    }

    func configure(title: String, breadcrumb: String?, image: UIImage?, isSelected: Bool) {
        titleLabel.text = title

        if let breadcrumb, !breadcrumb.isEmpty {
            breadcrumbLabel.text = breadcrumb
            breadcrumbLabel.isHidden = false
        } else {
            breadcrumbLabel.isHidden = true
        }

        leftImageView.image = image?.withRenderingMode(.alwaysTemplate)
        accessoryType = isSelected ? .checkmark : .none
        accessibilityIdentifier = AccessibilityIdentifiers.LibraryPanels.BookmarksPanel.bookmarkParentFolderCell
        accessibilityLabel = [title, breadcrumb].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
        accessibilityTraits = .button
    }

    func applyTheme(theme: Theme) {
        selectedView.backgroundColor = theme.colors.layer5Hover
        backgroundColor = theme.colors.layer5
        tintColor = theme.colors.iconSecondary
        leftImageView.tintColor = theme.colors.textPrimary
        titleLabel.textColor = theme.colors.textPrimary
        breadcrumbLabel.textColor = theme.colors.textSecondary
    }
}
