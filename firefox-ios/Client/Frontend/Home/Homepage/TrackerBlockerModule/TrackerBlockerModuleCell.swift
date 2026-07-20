// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

final class TrackerBlockerModuleCell: UICollectionViewCell, ReusableCell, ThemeApplicable {
    // MARK: - Display random number for now

    private func displayRandomNumber() {
        let magicNumbers = [10, 100, 45000, 56742445, 600000000000, 2305000]

        guard let randomNumber = magicNumbers.randomElement() else { return }
        let numberText = randomNumber.formatted(.number.notation(.compactName))
        let fullText = String(format: .Menu.EnhancedTrackingProtection.trackersBlockedLabel, numberText)

        titleLabel.attributedText = fullText.attributedText(boldString: numberText, font: titleLabel.font)
    }

    // MARK: - UX

    private struct UX {
        static let cornerRadius: CGFloat = 8
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 8
        static let spacing: CGFloat = 8
        static let iconSize: CGFloat = 20
    }

    // MARK: - UI

    private lazy var containerPillView: UIView = .build { view in
        view.clipsToBounds = true
    }

    private lazy var shieldIcon: UIImageView = .build { icon in
        icon.contentMode = .scaleAspectFit
        icon.adjustsImageSizeForAccessibilityContentSizeCategory = true
        icon.image = UIImage(named: StandardImageIdentifiers.Large.shieldCheckmark)?
            .withRenderingMode(.alwaysTemplate)
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.footnote.scaledFont()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.text = .Menu.EnhancedTrackingProtection.trackersBlockedLabel
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        displayRandomNumber()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        containerPillView.layoutIfNeeded()
        containerPillView.layer.cornerRadius = contentView.frame.height / 2
    }

    // MARK: Layout

    private func setupLayout() {
        containerPillView.addSubview(shieldIcon)
        containerPillView.addSubview(titleLabel)
        contentView.addSubview(containerPillView)

        NSLayoutConstraint.activate([
            shieldIcon.widthAnchor.constraint(equalToConstant: UX.iconSize),
            shieldIcon.heightAnchor.constraint(equalToConstant: UX.iconSize),

            shieldIcon.leadingAnchor.constraint(equalTo: containerPillView.leadingAnchor, constant: UX.horizontalPadding),
            shieldIcon.centerYAnchor.constraint(equalTo: containerPillView.centerYAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: shieldIcon.trailingAnchor, constant: UX.spacing),
            titleLabel.centerYAnchor.constraint(equalTo: shieldIcon.centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerPillView.trailingAnchor, constant: -UX.horizontalPadding),

            containerPillView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            containerPillView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerPillView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            containerPillView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor,
                                                       constant: UX.horizontalPadding),
            containerPillView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor,
                                                        constant: -UX.horizontalPadding)
        ])
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        containerPillView.backgroundColor = theme.colors.layer2
        titleLabel.textColor = theme.colors.textPrimary
        shieldIcon.tintColor = theme.colors.iconAccentViolet
    }
}
