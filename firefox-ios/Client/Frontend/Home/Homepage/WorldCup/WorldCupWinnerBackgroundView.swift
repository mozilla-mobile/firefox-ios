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
final class WorldCupWinnerBackgroundView: UIView, ThemeApplicable {
    struct Configuration: Equatable {
        let flagAssetName: String
        let teamName: String
        let subtitle: String
    }

    private struct UX {
        static let cornerRadius: CGFloat = 26
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
        view.layer.cornerRadius = UX.cornerRadius
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
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
    }

    private let subtitleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.footnote.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
    }

    private let textStack: UIStackView = .build { stack in
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = UX.textSpacing
    }

    private let contentStack: UIStackView = .build { stack in
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = UX.flagToTextSpacing
    }
    
    private let contentBackgroundView: UIView = .build { view in
        view.layer.cornerRadius = 16.0
    }
    
    var contentViewBottomAnchor: NSLayoutYAxisAnchor {
        return contentStack.bottomAnchor
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
        textStack.addArrangedSubview(teamNameLabel)
        textStack.addArrangedSubview(subtitleLabel)

        contentStack.addArrangedSubview(flagView)
        contentStack.addArrangedSubview(textStack)

        addSubviews(backgroundImageView, contentBackgroundView, contentStack)

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            contentBackgroundView.topAnchor.constraint(equalTo: flagView.centerYAnchor),
            contentBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: UX.flagTopPadding),
            contentStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: UX.horizontalPadding),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -UX.horizontalPadding),

            flagView.widthAnchor.constraint(equalToConstant: UX.flagSize.width),
            flagView.heightAnchor.constraint(equalToConstant: UX.flagSize.height),
        ])
    }

    // MARK: - Configuration

    func configure(with configuration: Configuration) {
        flagView.image = UIImage(named: configuration.flagAssetName)
        teamNameLabel.text = configuration.teamName
        teamNameLabel.accessibilityLabel = configuration.teamName
        subtitleLabel.text = configuration.subtitle
        subtitleLabel.accessibilityLabel = configuration.subtitle
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        contentBackgroundView.backgroundColor = theme.colors.layer5
        teamNameLabel.textColor = theme.colors.textPrimary
        subtitleLabel.textColor = theme.colors.textPrimary
        flagView.layer.borderColor = theme.colors.borderSecondary.cgColor
        flagView.backgroundColor = theme.colors.borderSecondary
    }
}
