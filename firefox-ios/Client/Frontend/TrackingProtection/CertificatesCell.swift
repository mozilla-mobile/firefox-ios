// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

final class CertificatesCell: UITableViewCell, ReusableCell, ThemeApplicable {
    var sectionLabel: UILabel = .build { label in
        label.font = FXFontStyles.Bold.headline.scaledFont()
        label.textAlignment = .right
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
    }

    var allSectionItemsStackView: UIStackView = .build { stack in
        stack.axis = .vertical
        stack.distribution = .equalSpacing
        stack.spacing = CertificatesUX.allSectionItemsSpacing
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(sectionLabel)
        contentView.addSubview(allSectionItemsStackView)

        NSLayoutConstraint.activate([
            sectionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                  constant: CertificatesUX.sectionLabelMargin),
            sectionLabel.topAnchor.constraint(equalTo: contentView.topAnchor,
                                              constant: CertificatesUX.sectionLabelMargin),
            sectionLabel.widthAnchor.constraint(equalToConstant: CertificatesUX.sectionLabelWidth),

            allSectionItemsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                              constant: CertificatesUX.sectionLabelMargin),
            allSectionItemsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                               constant: -CertificatesUX.sectionLabelMargin),
            allSectionItemsStackView.topAnchor.constraint(equalTo: sectionLabel.bottomAnchor,
                                                          constant: CertificatesUX.allSectionItemsTopMargin),
            allSectionItemsStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                             constant: -CertificatesUX.sectionLabelMargin)
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

    func configure(theme: Theme, sectionTitle: String, items: CertificateItems) {
        applyTheme(theme: theme)
        sectionLabel.text = sectionTitle
        for (key, value) in items {
            let stackView = getSectionItemStackView()
            let titleLabel = getItemLabel(theme: theme, with: key, isTitle: true)
            titleLabel.widthAnchor.constraint(equalToConstant: CertificatesUX.sectionLabelWidth).isActive = true
            stackView.addArrangedSubview(titleLabel)
            stackView.addArrangedSubview(getItemLabel(theme: theme, with: value, isTitle: false))
            allSectionItemsStackView.addArrangedSubview(stackView)
        }
    }

    func applyTheme(theme: Theme) {
        sectionLabel.textColor = theme.colors.textPrimary
    }

    private func getItemLabel(theme: Theme, with title: String, isTitle: Bool) -> UILabel {
        let itemLabel: UILabel = .build { label in
            label.font = FXFontStyles.Bold.headline.scaledFont()
            label.textColor = isTitle ? theme.colors.textSecondary : theme.colors.textPrimary
            label.text = title
            label.textAlignment = isTitle ? .right : .left
            label.numberOfLines = 0
            label.lineBreakMode = .byWordWrapping
        }
        return itemLabel
    }

    private func getSectionItemStackView() -> UIStackView {
        let sectionItemsStackView: UIStackView = .build { stack in
            stack.axis = .horizontal
            stack.spacing = CertificatesUX.sectionItemsSpacing
        }
        return sectionItemsStackView
    }
}
