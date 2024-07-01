// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

final class MicrosurveyConfirmationView: UIView, ThemeApplicable {
    private struct UX {
        static let stackSpacing: CGFloat = 28
        static let padding = NSDirectionalEdgeInsets(
            top: 56,
            leading: 16,
            bottom: -56,
            trailing: -16
        )
    }

    private var confirmationStackView: UIStackView = .build { view in
        view.axis = .vertical
        view.spacing = UX.stackSpacing
        view.alignment = .center
    }

    private var confirmationImage: UIImageView = .build { imageView in
        imageView.image = UIImage(imageLiteralResourceName: ImageIdentifiers.foxConfirmation)
        imageView.contentMode = .scaleAspectFit
    }

    private var confirmationLabel: UILabel = .build { label in
        label.text = .Microsurvey.Survey.ConfirmationPage.ConfirmationLabel
        label.font = FXFontStyles.Regular.title3.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        confirmationStackView.addArrangedSubview(confirmationImage)
        confirmationStackView.addArrangedSubview(confirmationLabel)
        addSubview(confirmationStackView)
        NSLayoutConstraint.activate(
            [
                confirmationStackView.topAnchor.constraint(
                    equalTo: topAnchor,
                    constant: UX.padding.top
                ),
                confirmationStackView.leadingAnchor.constraint(
                    greaterThanOrEqualTo: leadingAnchor,
                    constant: UX.padding.leading
                ),
                confirmationStackView.trailingAnchor.constraint(
                    greaterThanOrEqualTo: trailingAnchor,
                    constant: UX.padding.trailing
                ),
                confirmationStackView.bottomAnchor.constraint(
                    equalTo: bottomAnchor,
                    constant: UX.padding.bottom
                ),

                confirmationStackView.centerXAnchor.constraint(equalTo: centerXAnchor)
            ]
        )
    }

    // MARK: ThemeApplicable
    public func applyTheme(theme: Theme) {
        confirmationLabel.textColor = theme.colors.textPrimary
    }
}
