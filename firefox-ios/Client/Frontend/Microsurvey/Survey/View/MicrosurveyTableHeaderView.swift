// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

class MicrosurveyTableHeaderView: UITableViewHeaderFooterView, ReusableCell, ThemeApplicable {
    private struct UX {
        static let radioButtonSize = CGSize(width: 24, height: 24)
        static let spacing: CGFloat = 12
        static let padding = NSDirectionalEdgeInsets(
            top: 0,
            leading: 16,
            bottom: -20,
            trailing: -16
        )
    }

    private lazy var horizontalStackView: UIStackView = .build { stackView in
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = UX.spacing
    }

    private lazy var iconView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        // TODO: FXIOS-9108: This image should come from the data source, based on the target feature
        // imageView.image = UIImage(systemName: "printer")
    }

    private lazy var questionLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        if iconView.image != nil {
            horizontalStackView.addArrangedSubview(iconView)
        }
        horizontalStackView.addArrangedSubview(questionLabel)
        contentView.addSubview(horizontalStackView)

        NSLayoutConstraint.activate(
            [
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

                iconView.heightAnchor.constraint(equalToConstant: UX.radioButtonSize.height),
                iconView.widthAnchor.constraint(equalToConstant: UX.radioButtonSize.width)
            ]
        )
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ text: String) {
        questionLabel.text = text
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        let colors = theme.colors
        questionLabel.textColor = colors.textPrimary
        iconView.tintColor = colors.iconPrimary
    }
}
