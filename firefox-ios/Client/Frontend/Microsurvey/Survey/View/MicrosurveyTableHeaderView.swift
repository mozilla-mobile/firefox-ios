// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

final class MicrosurveyTableHeaderView: UITableViewHeaderFooterView, ReusableCell, ThemeApplicable {
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

    private lazy var iconContainer: UIView = .build()

    private lazy var iconView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
    }

    private lazy var questionLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        iconContainer.addSubview(iconView)
        horizontalStackView.addArrangedSubview(iconContainer)
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

                iconView.widthAnchor.constraint(
                    equalToConstant: UX.radioButtonSize.width
                ),
                iconView.heightAnchor.constraint(
                    equalToConstant: UX.radioButtonSize.height
                ),
                iconView.widthAnchor.constraint(
                    equalTo: iconContainer.widthAnchor
                ),
                iconView.centerYAnchor.constraint(
                    equalTo: iconContainer.centerYAnchor
                )
            ]
        )
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ text: String, icon: UIImage?) {
        questionLabel.text = text
        guard let icon else {
            horizontalStackView.removeArrangedView(iconView)
            return
        }
        iconView.image = icon.withRenderingMode(.alwaysTemplate)
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        let colors = theme.colors
        questionLabel.textColor = colors.textPrimary
        iconView.tintColor = colors.iconPrimary
    }
}
