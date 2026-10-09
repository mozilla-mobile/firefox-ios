// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

final class IntensityVisualEffectView: UIVisualEffectView {
    private var animator: UIViewPropertyAnimator?
    private let targetEffect: UIVisualEffect
    private let intensity: CGFloat

    /// - Parameter intensity: Linear scale, from 0.0 for no effect to 1.0 for the full effect.
    public init(effect: UIVisualEffect, intensity: CGFloat) {
        self.targetEffect = effect
        self.intensity = intensity
        super.init(effect: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// The effect's backdrop layers only exist once the view is in a window, so the paused animation
    /// has to be set up there, otherwise the effect is applied at full intensity.
    override func didMoveToWindow() {
        super.didMoveToWindow()
        animator?.stopAnimation(true)
        animator = nil
        effect = nil
        guard window != nil else { return }
        let animator = UIViewPropertyAnimator(duration: 1.0, curve: .linear) { [weak self] in
            self?.effect = self?.targetEffect
        }
        animator.fractionComplete = intensity
        self.animator = animator
    }
}

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
    }

    private let materialView: UIView = IntensityVisualEffectView(
        effect: UIBlurEffect(
            style: .systemThickMaterial
        ),
        intensity: 0.5
    )
    private let headerIconView: UIImageView = .build {
        $0.image = UIImage(named: StandardImageIdentifiers.Large.sparkle)
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
        let size = headerLabel.bounds.size
        guard size.width > 0, size.height > 0, !headerGradientColors.isEmpty else { return }
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(origin: .zero, size: size)
        gradient.colors = headerGradientColors.map(\.cgColor)
        let image = UIGraphicsImageRenderer(size: size).image { context in
            gradient.render(in: context.cgContext)
        }
        headerLabel.textColor = UIColor(patternImage: image)
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
        bodyLabel.textColor = theme.colors.textPrimary
    }
}
