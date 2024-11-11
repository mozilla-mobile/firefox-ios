// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

final class MicrosurveyTableViewCell: UITableViewCell, ReusableCell, ThemeApplicable {
    private struct UX {
        static let radioButtonSize = CGSize(width: 24, height: 24)
        static let spacing: CGFloat = 12
        static let padding = NSDirectionalEdgeInsets(
            top: 10,
            leading: 16,
            bottom: -10,
            trailing: -16
        )
        static let separatorWidth = 0.5

        struct Images {
            static let selected = ImageIdentifiers.radioButtonSelected
            static let notSelected = ImageIdentifiers.radioButtonNotSelected
        }
    }

    private var topSeparatorView: UIView = .build()
    private var a11yOptionsOrderValue: String?

    private lazy var horizontalStackView: UIStackView = .build { stackView in
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = UX.spacing
    }

    private lazy var radioButton: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: UX.Images.notSelected)
        imageView.isAccessibilityElement = false
    }

    private lazy var optionLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.isAccessibilityElement = false
    }

    var title: String? {
        optionLabel.text
    }

    var checked = false {
        didSet {
            let checkedButton = UIImage(named: UX.Images.selected)
            let uncheckedButton = UIImage(named: UX.Images.notSelected)
            self.radioButton.image = checked ? checkedButton : uncheckedButton
            accessibilityValue = optionA11yValue
        }
    }

    var optionA11yValue: String {
        let unselectedLabel: String = .Microsurvey.Survey.UnselectedRadioButtonAccessibilityLabel

        // This check is due to the selected option having a system trait to read out selected
        // However, there is no system trait for unselected
        let a11yValue: String
        let order = a11yOptionsOrderValue ?? ""
        if checked {
            a11yValue = order
        } else {
            a11yValue = unselectedLabel + ", \(order)"
        }
        return a11yValue
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
        selectionStyle = .none
        isAccessibilityElement = true
        accessibilityIdentifier = AccessibilityIdentifiers.Microsurvey.Survey.radioButton
        accessibilityTraits.insert(.button)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        horizontalStackView.addArrangedSubview(radioButton)
        horizontalStackView.addArrangedSubview(optionLabel)
        horizontalStackView.accessibilityElements = [radioButton, optionLabel]
        contentView.addSubview(topSeparatorView)
        contentView.addSubview(horizontalStackView)

        NSLayoutConstraint.activate(
            [
                topSeparatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                topSeparatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                topSeparatorView.topAnchor.constraint(equalTo: contentView.topAnchor),
                topSeparatorView.heightAnchor.constraint(equalToConstant: UX.separatorWidth),

                radioButton.widthAnchor.constraint(equalToConstant: UX.radioButtonSize.width),
                radioButton.heightAnchor.constraint(equalToConstant: UX.radioButtonSize.height),

                horizontalStackView.topAnchor.constraint(
                    equalTo: topSeparatorView.bottomAnchor,
                    constant: UX.padding.top
                ),
                horizontalStackView.leadingAnchor.constraint(
                    equalTo: contentView.leadingAnchor,
                    constant: UX.padding.leading
                ),
                horizontalStackView.trailingAnchor.constraint(
                    equalTo: contentView.trailingAnchor,
                    constant: UX.padding.trailing
                ),
                horizontalStackView.bottomAnchor.constraint(
                    equalTo: contentView.bottomAnchor,
                    constant: UX.padding.bottom
                ),
            ]
        )
    }

    func configure(_ text: String) {
        optionLabel.text = text
        accessibilityLabel = optionLabel.text
    }

    func setA11yValue(for index: Int, outOf totalCount: Int) {
        a11yOptionsOrderValue = String(
            format: .Microsurvey.Survey.OptionsOrderAccessibilityLabel,
            NSNumber(value: index + 1 as Int),
            NSNumber(value: totalCount as Int)
        )
        accessibilityValue = optionA11yValue
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        let colors = theme.colors
        optionLabel.textColor = colors.textPrimary
        backgroundColor = theme.colors.layer2
        topSeparatorView.backgroundColor = theme.colors.borderPrimary
    }
}
