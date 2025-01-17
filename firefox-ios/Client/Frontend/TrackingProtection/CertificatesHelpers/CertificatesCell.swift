// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

final class CertificatesCell: UITableViewCell, ReusableCell, ThemeApplicable {
    struct UX {
        static let sectionLabelWidth = 150.0
        static let sectionLabelTopMargin = 20.0
        static let sectionLabelMargin = 20.0
        static let sectionItemsSpacing = 40.0
        static let allSectionItemsSpacing = 10.0
        static let allSectionItemsTopMargin = 20.0
    }

    var sectionLabel: UILabel = .build { label in
        label.font = FXFontStyles.Bold.headline.scaledFont()
        label.textAlignment = .right
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
    }

    var allSectionItemsStackView: UIStackView = .build { stack in
        stack.axis = .vertical
        stack.distribution = .equalSpacing
        stack.spacing = UX.allSectionItemsSpacing
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(sectionLabel)
        contentView.addSubview(allSectionItemsStackView)

        NSLayoutConstraint.activate([
            sectionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                  constant: UX.sectionLabelMargin),
            sectionLabel.topAnchor.constraint(equalTo: contentView.topAnchor,
                                              constant: UX.sectionLabelTopMargin),
            sectionLabel.widthAnchor.constraint(equalToConstant: UX.sectionLabelWidth),

            allSectionItemsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                              constant: UX.sectionLabelMargin),
            allSectionItemsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                               constant: -UX.sectionLabelMargin),
            allSectionItemsStackView.topAnchor.constraint(equalTo: sectionLabel.bottomAnchor,
                                                          constant: UX.allSectionItemsTopMargin),
            allSectionItemsStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                             constant: -UX.sectionLabelMargin)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        allSectionItemsStackView.removeAllArrangedViews()
        sectionLabel.text = nil
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(theme: Theme, sectionTitle: String, items: CertificateItems, isIssuerName: Bool = false) {
        applyTheme(theme: theme)
        sectionLabel.text = sectionTitle
        for (key, value) in items {
            let isUnderlined = isIssuerName && key == .Menu.EnhancedTrackingProtection.certificateCommonName
            let stackView = getSectionItemStackView()
            let titleLabel = getItemLabel(theme: theme, with: key, isTitle: true, isUnderlined: isUnderlined)
            titleLabel.widthAnchor.constraint(equalToConstant: UX.sectionLabelWidth).isActive = true
            stackView.addArrangedSubview(titleLabel)
            stackView.addArrangedSubview(getItemLabel(
                theme: theme,
                with: value,
                isTitle: false,
                isUnderlined: isUnderlined
            ))
            allSectionItemsStackView.addArrangedSubview(stackView)
        }
    }

    // MARK: Accessibility
    func setupAccessibilityIdentifiers() {
        typealias A11y = AccessibilityIdentifiers.EnhancedTrackingProtection.DetailsScreen
        sectionLabel.accessibilityIdentifier = A11y.sectionLabel
        allSectionItemsStackView.accessibilityIdentifier = A11y.allSectionItems
    }

    func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layer5
        sectionLabel.textColor = theme.colors.textPrimary
    }

    private func getItemLabel(theme: Theme, with title: String, isTitle: Bool, isUnderlined: Bool) -> UILabel {
        let itemLabel: UILabel = .build()
        itemLabel.font = FXFontStyles.Bold.headline.scaledFont()
        itemLabel.textAlignment = isTitle ? .right : .left
        itemLabel.numberOfLines = 0
        itemLabel.lineBreakMode = .byWordWrapping
        itemLabel.accessibilityIdentifier = AccessibilityIdentifiers.EnhancedTrackingProtection.DetailsScreen.itemLabel
        if isUnderlined, !isTitle {
            let attributedString = NSAttributedString(
                string: title,
                attributes: [
                    .underlineStyle: NSUnderlineStyle.single.rawValue
                ]
            )
            itemLabel.textColor = theme.colors.textAccent
            itemLabel.attributedText = attributedString
        } else {
            itemLabel.textColor = isTitle ? theme.colors.textSecondary : theme.colors.textPrimary
            itemLabel.text = title
        }
        return itemLabel
    }

    private func getSectionItemStackView() -> UIStackView {
        let sectionItemsStackView: UIStackView = .build { stack in
            stack.axis = .horizontal
            stack.spacing = UX.sectionItemsSpacing
        }
        return sectionItemsStackView
    }
}
