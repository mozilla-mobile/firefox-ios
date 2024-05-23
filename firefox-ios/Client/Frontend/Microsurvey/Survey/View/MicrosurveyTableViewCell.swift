// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

class MicrosurveyTableViewCell: UITableViewCell, ReusableCell, ThemeApplicable {
    private struct UX {
        static let radioButtonSize = CGSize(width: 24, height: 24)
        static let spacing: CGFloat = 12
        static let padding = NSDirectionalEdgeInsets(
            top: 10,
            leading: 16,
            bottom: -10,
            trailing: -16
        )

        struct Images {
            // TODO: FXIOS-9028 Fix radio button for accessibility
            static let selected = ImageIdentifiers.Onboarding.MultipleChoiceButtonImages.checkmarkFilled
            static let notSelected = ImageIdentifiers.Onboarding.MultipleChoiceButtonImages.checkmarkEmpty
        }
    }

    private lazy var horizontalStackView: UIStackView = .build { stackView in
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = UX.spacing
    }

    private lazy var radioButton: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: UX.Images.notSelected)
        imageView.accessibilityIdentifier = AccessibilityIdentifiers.Microsurvey.Survey.radioButton
    }

    private lazy var optionLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
    }

    var checked = false {
        didSet {
            let checkedButton = UIImage(named: UX.Images.selected)
            let uncheckedButton = UIImage(named: UX.Images.notSelected)
            self.radioButton.image = checked ? checkedButton : uncheckedButton
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
        self.selectionStyle = .none
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        horizontalStackView.addArrangedSubview(radioButton)
        horizontalStackView.addArrangedSubview(optionLabel)
        horizontalStackView.accessibilityElements = [radioButton, optionLabel]
        contentView.addSubview(horizontalStackView)

        NSLayoutConstraint.activate(
            [
                radioButton.widthAnchor.constraint(equalToConstant: UX.radioButtonSize.width),
                radioButton.heightAnchor.constraint(equalToConstant: UX.radioButtonSize.height),

                horizontalStackView.topAnchor.constraint(
                    equalTo: contentView.topAnchor,
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
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        let colors = theme.colors
        optionLabel.textColor = colors.textPrimary
        backgroundColor = theme.colors.layer5
    }
}
