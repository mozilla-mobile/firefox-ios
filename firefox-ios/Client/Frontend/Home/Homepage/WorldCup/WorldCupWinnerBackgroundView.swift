// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import UIKit

/// Celebration backdrop shown around the match card when a followed team has
/// won. Holds the celebration artwork, the winning team's flag and the
/// supporting team name and subtitle (e.g. "Third place", "World Cup
/// Champions"). It is laid out behind `WorldCupMatchCardView` inside the cell.
final class WorldCupWinnerBackgroundView: UIView, ThemeApplicable, Blurrable {
    private struct UX {
        static let backgroundImageViewCornerRadius: CGFloat = 16.0
        static let flagSize = CGSize(width: 90, height: 60)
        static let flagCornerRadius: CGFloat = 9
        static let flagBorderWidth: CGFloat = 1
        static let flagTopPadding: CGFloat = 19
        static let flagToTextSpacing: CGFloat = 8
        static let textSpacing: CGFloat = 4
        static let horizontalPadding: CGFloat = 16
        static let backgroundImage = "winnerBackground"
    }

    // MARK: - UI

    private let backgroundImageView: UIImageView = .build { view in
        view.image = UIImage(named: UX.backgroundImage)
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = UX.backgroundImageViewCornerRadius
        view.isAccessibilityElement = false
    }

    private let flagView: UIImageView = .build { view in
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = UX.flagCornerRadius
        view.layer.borderWidth = UX.flagBorderWidth
        view.isAccessibilityElement = false
    }

    private let teamNameLabel: UILabel = .build { label in
        label.font = FXFontStyles.Bold.title2.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 0
    }

    private let subtitleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.footnote.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 0
    }

    private let contentBackgroundView: UIView = .build { view in
        view.layer.cornerRadius = 16.0
    }

    var contentViewBottomAnchor: NSLayoutYAxisAnchor {
        return subtitleLabel.bottomAnchor
    }

    // MARK: - Init

    init() {
        super.init(frame: .zero)
        shouldGroupAccessibilityChildren = true
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    private func setupLayout() {
        addSubviews(backgroundImageView, contentBackgroundView, flagView, teamNameLabel, subtitleLabel)

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentBackgroundView.topAnchor.constraint(equalTo: flagView.centerYAnchor),
            contentBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8.0),
            contentBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8.0),
            contentBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8.0),

            flagView.topAnchor.constraint(equalTo: topAnchor, constant: UX.flagTopPadding),
            flagView.centerXAnchor.constraint(equalTo: centerXAnchor),
            flagView.widthAnchor.constraint(equalToConstant: UX.flagSize.width),
            flagView.heightAnchor.constraint(equalToConstant: UX.flagSize.height),

            teamNameLabel.topAnchor.constraint(equalTo: flagView.bottomAnchor, constant: UX.flagToTextSpacing),
            teamNameLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            teamNameLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: UX.horizontalPadding),
            teamNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -UX.horizontalPadding),

            subtitleLabel.topAnchor.constraint(equalTo: teamNameLabel.bottomAnchor, constant: UX.textSpacing),
            subtitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            subtitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: UX.horizontalPadding),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -UX.horizontalPadding),
        ])
    }

    /// Vertical distance from the view's top edge down to the bottom of the
    /// content stack (i.e. the anchor exposed via `contentViewBottomAnchor`).
    /// This is the offset the match card needs to be pushed down by when the
    /// winner backdrop is visible, so the cell can size itself correctly.
    func contentBottomOffset(fittingWidth width: CGFloat) -> CGFloat {
        let availableWidth = max(width - UX.horizontalPadding * 2, 0)
        let fittingSize = CGSize(width: availableWidth, height: UIView.layoutFittingCompressedSize.height)
        let teamNameHeight = teamNameLabel.systemLayoutSizeFitting(
            fittingSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        let subtitleHeight = subtitleLabel.systemLayoutSizeFitting(
            fittingSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        return UX.flagTopPadding
            + UX.flagSize.height
            + UX.flagToTextSpacing
            + teamNameHeight
            + UX.textSpacing
            + subtitleHeight
    }

    // MARK: - Configuration

    func configure(teamName: String, subtitle: String) {
        flagView.image = UIImage(named: teamName)
        teamNameLabel.text = teamName
        subtitleLabel.text = subtitle
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        teamNameLabel.textColor = theme.colors.textPrimary
        subtitleLabel.textColor = theme.colors.textPrimary
        flagView.layer.borderColor = theme.colors.borderSecondary.cgColor
        flagView.backgroundColor = theme.colors.borderSecondary
        adjustBlur(theme: theme)
    }
    
    func adjustBlur(theme: Theme) {
        if shouldApplyWallpaperBlur {
            contentBackgroundView.addBlurEffectWithClearBackgroundAndClipping(using: .systemThickMaterial)
        } else {
            contentBackgroundView.removeVisualEffectView()
            contentBackgroundView.backgroundColor = theme.colors.layer5
        }
    }
}
