// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import UIKit

/// Floating pill that takes the user back to a parked Quick Answers session. The host owns its position.
public final class QuickAnswersReturnPillView: UIView, ThemeApplicable {
    private enum UX {
        static let verticalPadding: CGFloat = 8.0
        static let maxWidth: CGFloat = 220.0
        static let minimizedSize: CGFloat = 28.0
        static let leadingPadding: CGFloat = 10.0
        static let trailingPadding: CGFloat = 16.0
        static let iconSpacing: CGFloat = 8.0
        static let iconBackgroundSize: CGFloat = 30.0
        static let iconSize: CGFloat = 16.0
        static let iconBackgroundAlpha: CGFloat = 0.1
        static let blurBorderWidth: CGFloat = 0.5
        static let minimizeDuration: TimeInterval = 0.35
        static let minimizeDamping: CGFloat = 0.9
        static let fadeDistance: CGFloat = 200.0
        static let maxFade: CGFloat = 0.6
        static let removeDuration: TimeInterval = 0.2
        static let flyOutDistance: CGFloat = 40.0
        static let springBackDuration: TimeInterval = 0.5
        static let springBackDamping: CGFloat = 0.7
    }

    private let onTap: (Bool) -> Void
    private let onSwipeAway: () -> Void
    private let icon = UIImage(named: StandardImageIdentifiers.Large.audioWave)

    private(set) var isMinimized = false
    private let glassView: UIVisualEffectView = .build {
        if #available(iOS 26, *) {
            let glassEffect = UIGlassEffect()
            glassEffect.isInteractive = true
            $0.effect = glassEffect
            $0.cornerConfiguration = .capsule()
        } else {
            $0.effect = UIBlurEffect(style: .systemUltraThinMaterial)
            $0.clipsToBounds = true
        }
    }
    /// Clips the content to the capsule while it resizes. The glass itself stays unclipped, so its press effect can grow.
    private let contentContainer: UIView = .build {
        $0.clipsToBounds = true
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
    }
    private let subtitleLabel: UILabel = .build {
        $0.font = FXFontStyles.Regular.caption1.scaledFont()
        $0.adjustsFontForContentSizeCategory = true
    }

    private var expandedConstraints: [NSLayoutConstraint] = []
    private var minimizedConstraints: [NSLayoutConstraint] = []
    /// Pins the labels to their expanded width while minimized, so they slide under the glass instead of re-truncating.
    private lazy var labelWidthConstraint = labelStack.widthAnchor.constraint(equalToConstant: 0)

    public init(accessibilityIdentifier: String, onTap: @escaping (Bool) -> Void, onSwipeAway: @escaping () -> Void) {
        self.onTap = onTap
        self.onSwipeAway = onSwipeAway
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
        setupGestures()
        isAccessibilityElement = true
        accessibilityTraits = .button
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(question: String, subtitle: String) {
        titleLabel.text = question
        subtitleLabel.text = subtitle
        accessibilityLabel = question
        accessibilityHint = subtitle
    }

    /// When `animated` is false the changes are applied directly, so a host can run them inside its own animation.
    public func setMinimized(_ isMinimized: Bool, animated: Bool) {
        guard isMinimized != self.isMinimized else { return }
        self.isMinimized = isMinimized
        let layoutHost = superview ?? self
        layoutHost.layoutIfNeeded()
        labelWidthConstraint.constant = labelStack.bounds.width
        labelWidthConstraint.isActive = isMinimized
        NSLayoutConstraint.deactivate(isMinimized ? expandedConstraints : minimizedConstraints)
        NSLayoutConstraint.activate(isMinimized ? minimizedConstraints : expandedConstraints)

        let changes = {
            let contentAlpha: CGFloat = isMinimized ? 0.0 : 1.0
            self.labelStack.alpha = contentAlpha
            self.iconBackgroundView.alpha = contentAlpha
            layoutHost.layoutIfNeeded()
        }
        guard animated else {
            changes()
            return
        }
        UIView.animate(
            withDuration: UX.minimizeDuration,
            delay: 0,
            usingSpringWithDamping: UX.minimizeDamping,
            initialSpringVelocity: 0,
            animations: changes
        )
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        contentContainer.layer.cornerRadius = bounds.height / 2
        if #unavailable(iOS 26) {
            glassView.layer.cornerRadius = bounds.height / 2
        }
    }

    override public func accessibilityActivate() -> Bool {
        onTap(isMinimized)
        return true
    }

    /// VoiceOver's built-in dismiss gesture (two-finger scrub) removes the pill, like swiping it away.
    override public func accessibilityPerformEscape() -> Bool {
        onSwipeAway()
        return true
    }

    // MARK: - Setup

    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        iconBackgroundView.layer.addSublayer(iconBackgroundGradient)
        labelStack.addArrangedSubview(titleLabel)
        labelStack.addArrangedSubview(subtitleLabel)
        contentContainer.addSubviews(iconBackgroundView, iconImageView, labelStack)
        glassView.contentView.addSubview(contentContainer)
        addSubview(glassView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            glassView.topAnchor.constraint(equalTo: topAnchor),
            glassView.leadingAnchor.constraint(equalTo: leadingAnchor),
            glassView.trailingAnchor.constraint(equalTo: trailingAnchor),
            glassView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentContainer.topAnchor.constraint(equalTo: topAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

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

        // Hugs the taller of the icon and the labels, so the height follows Dynamic Type.
        let hugHeight = heightAnchor.constraint(equalToConstant: 0)
        hugHeight.priority = .defaultLow
        expandedConstraints = [
            hugHeight,
            labelStack.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: UX.verticalPadding),
            iconBackgroundView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: UX.verticalPadding),
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

    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        // Lets the touches reach the glass, so its interactive press effect still plays.
        tap.cancelsTouchesInView = false
        addGestureRecognizer(tap)
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan)))
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
            // Fades with the straight-line distance dragged, down to `1 - UX.maxFade` at `UX.fadeDistance`.
            let draggedDistance = hypot(translation.x, translation.y)
            alpha = 1.0 - min(draggedDistance / UX.fadeDistance, 1.0) * UX.maxFade
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

    /// Slides the pill a further `UX.flyOutDistance` along the swipe while fading it out, then removes it.
    private func flyAway(translation: CGPoint, velocity: CGPoint) {
        // The swipe direction is the release velocity, or the drag itself when the finger stopped before lifting.
        let direction = velocity == .zero ? translation : velocity
        let length = hypot(direction.x, direction.y)
        // Scales the direction to `UX.flyOutDistance` points.
        let scale = length > 0 ? UX.flyOutDistance / length : 0
        let isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        UIView.animate(withDuration: UX.removeDuration, delay: 0, options: .curveEaseOut) {
            self.alpha = 0.0
            guard !isReduceMotionEnabled else { return }
            self.transform = CGAffineTransform(
                translationX: translation.x + direction.x * scale,
                y: translation.y + direction.y * scale
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
        if glassView.effect is UIBlurEffect {
            glassView.layer.borderWidth = UX.blurBorderWidth
            glassView.layer.borderColor = colors.borderPrimary.cgColor
        }
    }
}
