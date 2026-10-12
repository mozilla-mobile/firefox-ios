// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import ComponentLibrary

/// The card displaying a Quick Answers result: a gradient header and the answer body, laid over a
/// material background.
final class QuickAnswersAnswerCardView: UIView, ThemeApplicable {
    private struct UX {
        static let cornerRadius: CGFloat = 38.0
        static let borderWidth: CGFloat = 0.25
        static let padding: CGFloat = 20.0
        static let headerIconSize: CGFloat = 20.0
        static let headerSpacing: CGFloat = 2.0
        static let bodyTopSpacing: CGFloat = 6.0
        static let materialIntensity: CGFloat = 0.8
    }

    private let materialView: UIView = IntensityVisualEffectView(
        effect: UIBlurEffect(style: .systemThickMaterial),
        intensity: UX.materialIntensity
    )
    private let headerIcon = UIImage(named: StandardImageIdentifiers.Large.sparkle)
    private let headerIconView: UIImageView = .build {
        $0.contentMode = .scaleAspectFit
    }
    private let headerLabel: UILabel = .build {
        $0.font = FXFontStyles.Bold.caption1.scaledFont()
        $0.adjustsFontForContentSizeCategory = true
    }
    private let bodyLabel: UILabel = .build {
        $0.font = FXFontStyles.Regular.body.scaledFont()
        $0.numberOfLines = 0
        $0.adjustsFontForContentSizeCategory = true
    }
    private var headerGradientColors: [UIColor] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupSubviews() {
        layer.cornerRadius = UX.cornerRadius
        layer.cornerCurve = .continuous
        layer.borderWidth = UX.borderWidth
        clipsToBounds = true
        addSubviews(materialView, headerIconView, headerLabel, bodyLabel)
        materialView.pinToSuperview()

        NSLayoutConstraint.activate([
            headerIconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.padding),
            headerIconView.centerYAnchor.constraint(equalTo: headerLabel.centerYAnchor),
            headerIconView.widthAnchor.constraint(equalToConstant: UX.headerIconSize),
            headerIconView.heightAnchor.constraint(equalToConstant: UX.headerIconSize),

            headerLabel.topAnchor.constraint(equalTo: topAnchor, constant: UX.padding),
            headerLabel.leadingAnchor.constraint(equalTo: headerIconView.trailingAnchor, constant: UX.headerSpacing),
            headerLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.padding),
            headerLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: UX.headerIconSize),

            bodyLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: UX.bodyTopSpacing),
            bodyLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.padding),
            bodyLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.padding),
            bodyLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.padding)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyHeaderGradient()
    }

    // MARK: - Configuration
    func configure(header: String, body: String) {
        headerLabel.text = header
        bodyLabel.text = body
        setNeedsLayout()
    }

    /// Fills the header text with the AI gradient, since a label can't take a gradient text color directly.
    private func applyHeaderGradient() {
        guard let gradient = gradientImage(size: headerLabel.bounds.size) else { return }
        headerLabel.textColor = UIColor(patternImage: gradient)
    }

    private func applyHeaderIconGradient() {
        guard let headerIcon, let iconGradient = gradientImage(size: headerIcon.size) else { return }
        let rect = CGRect(origin: .zero, size: headerIcon.size)
        headerIconView.image = UIGraphicsImageRenderer(size: headerIcon.size).image { _ in
            iconGradient.draw(in: rect)
            headerIcon.draw(in: rect, blendMode: .destinationIn, alpha: 1.0)
        }
    }

    private func gradientImage(size: CGSize) -> UIImage? {
        guard size.width > 0, size.height > 0, !headerGradientColors.isEmpty else { return nil }
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(origin: .zero, size: size)
        gradient.colors = headerGradientColors.map(\.cgColor)
        return UIGraphicsImageRenderer(size: size).image { context in
            gradient.render(in: context.cgContext)
        }
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {
        layer.borderColor = theme.colors.borderPrimary.cgColor
        headerGradientColors = [
            theme.colors.gradientAIStrongStop1,
            theme.colors.gradientAIStrongStop2,
            theme.colors.gradientAIStrongStop3
        ]
        applyHeaderGradient()
        applyHeaderIconGradient()
        bodyLabel.textColor = theme.colors.textPrimary
    }
}
