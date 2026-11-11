// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import UIKit

/// Floating pill that takes the user back to a parked Quick Answers session. The host owns its position.
public final class QuickAnswersReturnPillView: UIView, ThemeApplicable {
    private struct UX {
        static let expandedHeight: CGFloat = 47.0
        static let maxWidth: CGFloat = 217.0
        static let minimizedSize: CGFloat = 28.0
        static let leadingPadding: CGFloat = 10.0
        static let trailingPadding: CGFloat = 16.0
        static let iconSpacing: CGFloat = 8.0
        static let iconBackgroundSize: CGFloat = 30.0
        static let iconSize: CGFloat = 16.0
        static let iconBackgroundAlpha: CGFloat = 0.1
        static let minimizeDuration: TimeInterval = 0.2
        static let fadeDistance: CGFloat = 200.0
        static let maxFade: CGFloat = 0.6
        static let removeDuration: TimeInterval = 0.2
        static let flyOutSizeMultiplier: CGFloat = 1.5
        static let springBackDuration: TimeInterval = 0.5
        static let springBackDamping: CGFloat = 0.7
    }

    public static let identifier = "QuickAnswers.returnPill"

    private let onTap: (Bool) -> Void
    private let onSwipeAway: () -> Void
    private let icon = UIImage(named: StandardImageIdentifiers.Large.audioWave)

    private(set) var isMinimized = false
    private let glassView: UIVisualEffectView = .build {
        $0.clipsToBounds = true
        if #available(iOS 26, *), !DeviceInfo.isRunningLiquidGlassEarlyBeta {
            let glassEffect = UIGlassEffect()
            glassEffect.isInteractive = true
            $0.effect = glassEffect
        } else {
            $0.effect = UIBlurEffect(style: .systemUltraThinMaterial)
        }
    }
    private let iconBackgroundView: UIView = .build {
        $0.layer.cornerRadius = UX.iconBackgroundSize / 2
        $0.clipsToBounds = true
    }
    private let iconBackgroundGradient: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.frame = CGRect(x: 0.0, y: 0.0, width: UX.iconBackgroundSize, height: UX.iconBackgroundSize)
        return layer
    }()
    private let iconImageView: UIImageView = .build {
        $0.contentMode = .scaleAspectFit
    }
    private let labelStack: UIStackView = .build {
        $0.axis = .vertical
    }
    private let titleLabel: UILabel = .build {
        $0.font = FXFontStyles.Bold.caption1.scaledFont()
        $0.adjustsFontForContentSizeCategory = true
        $0.maximumContentSizeCategory = .accessibilityMedium
    }
    private let subtitleLabel: UILabel = .build {
        $0.font = FXFontStyles.Regular.caption1.scaledFont()
        $0.adjustsFontForContentSizeCategory = true
        $0.maximumContentSizeCategory = .accessibilityMedium
    }

    private var expandedConstraints: [NSLayoutConstraint] = []
    private var minimizedConstraints: [NSLayoutConstraint] = []

    public init(onTap: @escaping (Bool) -> Void, onSwipeAway: @escaping () -> Void) {
        self.onTap = onTap
        self.onSwipeAway = onSwipeAway
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan)))
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityIdentifier = Self.identifier
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(question: String, subtitle: String, accessibilityRemoveActionName: String) {
        titleLabel.text = question
        subtitleLabel.text = subtitle
        accessibilityLabel = question
        accessibilityHint = subtitle
        let onSwipeAway = onSwipeAway
        accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: accessibilityRemoveActionName) { _ in
                onSwipeAway()
                return true
            }
        ]
    }

    public func setMinimized(_ isMinimized: Bool, animated: Bool) {
        guard isMinimized != self.isMinimized else { return }
        self.isMinimized = isMinimized
        let layoutHost = superview ?? self
        layoutHost.layoutIfNeeded()
        NSLayoutConstraint.deactivate(isMinimized ? expandedConstraints : minimizedConstraints)
        NSLayoutConstraint.activate(isMinimized ? minimizedConstraints : expandedConstraints)

        UIView.animate(withDuration: animated ? UX.minimizeDuration : 0.0, delay: 0, options: .curveEaseOut) {
            let contentAlpha: CGFloat = isMinimized ? 0.0 : 1.0
            self.labelStack.alpha = contentAlpha
            self.iconBackgroundView.alpha = contentAlpha
            layoutHost.layoutIfNeeded()
        }
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        glassView.layer.cornerRadius = bounds.height / 2
    }

    override public func accessibilityActivate() -> Bool {
        onTap(isMinimized)
        return true
    }

    // MARK: - Setup

    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        iconBackgroundView.layer.addSublayer(iconBackgroundGradient)
        labelStack.addArrangedSubview(titleLabel)
        labelStack.addArrangedSubview(subtitleLabel)
        addSubviews(glassView, iconBackgroundView, iconImageView, labelStack)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            glassView.topAnchor.constraint(equalTo: topAnchor),
            glassView.leadingAnchor.constraint(equalTo: leadingAnchor),
            glassView.trailingAnchor.constraint(equalTo: trailingAnchor),
            glassView.bottomAnchor.constraint(equalTo: bottomAnchor),

            widthAnchor.constraint(lessThanOrEqualToConstant: UX.maxWidth),

            iconBackgroundView.widthAnchor.constraint(equalToConstant: UX.iconBackgroundSize),
            iconBackgroundView.heightAnchor.constraint(equalToConstant: UX.iconBackgroundSize),
            iconBackgroundView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: UX.iconSize),
            iconImageView.heightAnchor.constraint(equalToConstant: UX.iconSize),
            iconImageView.centerXAnchor.constraint(equalTo: iconBackgroundView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconBackgroundView.centerYAnchor),

            labelStack.leadingAnchor.constraint(equalTo: iconBackgroundView.trailingAnchor, constant: UX.iconSpacing),
            labelStack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        expandedConstraints = [
            heightAnchor.constraint(equalToConstant: UX.expandedHeight),
            iconBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.leadingPadding),
            labelStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.trailingPadding)
        ]
        minimizedConstraints = [
            widthAnchor.constraint(equalToConstant: UX.minimizedSize),
            heightAnchor.constraint(equalToConstant: UX.minimizedSize),
            iconBackgroundView.centerXAnchor.constraint(equalTo: centerXAnchor)
        ]
        NSLayoutConstraint.activate(expandedConstraints)
    }

    // MARK: - Gestures

    @objc
    private func handleTap() {
        onTap(isMinimized)
    }

    @objc
    private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: superview)
        switch gesture.state {
        case .changed:
            transform = CGAffineTransform(translationX: translation.x, y: translation.y)
            alpha = 1.0 - min(hypot(translation.x, translation.y) / UX.fadeDistance, 1.0) * UX.maxFade
        case .ended, .cancelled:
            let velocity = gesture.velocity(in: superview)
            if QuickAnswersReturnPillDragEvaluator.shouldRemove(translation: translation, velocity: velocity) {
                flyAway(translation: translation, velocity: velocity)
            } else {
                springBack()
            }
        default:
            break
        }
    }

    private func flyAway(translation: CGPoint, velocity: CGPoint) {
        let reference = hypot(velocity.x, velocity.y) > 1.0 ? velocity : translation
        let length = hypot(reference.x, reference.y)
        let distance = length > 0 ? max(bounds.width, bounds.height) * UX.flyOutSizeMultiplier / length : 0
        let isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        UIView.animate(withDuration: UX.removeDuration, delay: 0, options: .curveEaseOut) {
            self.alpha = 0.0
            guard !isReduceMotionEnabled else { return }
            self.transform = CGAffineTransform(
                translationX: translation.x + reference.x * distance,
                y: translation.y + reference.y * distance
            )
        } completion: { _ in
            self.onSwipeAway()
        }
    }

    private func springBack() {
        let damping = UIAccessibility.isReduceMotionEnabled ? 1.0 : UX.springBackDamping
        UIView.animate(
            withDuration: UX.springBackDuration,
            delay: 0,
            usingSpringWithDamping: damping,
            initialSpringVelocity: 0
        ) {
            self.transform = .identity
            self.alpha = 1.0
        }
    }

    // MARK: - ThemeApplicable

    public func applyTheme(theme: Theme) {
        let colors = theme.colors
        let gradientStops = [colors.gradientAIStrongStop1, colors.gradientAIStrongStop2, colors.gradientAIStrongStop3]
        iconBackgroundGradient.colors = gradientStops.map { $0.withAlphaComponent(UX.iconBackgroundAlpha).cgColor }
        iconImageView.image = icon?.verticalGradientTinted(with: gradientStops)
        titleLabel.textColor = colors.textPrimary
        subtitleLabel.textColor = colors.textSecondary
    }
}
