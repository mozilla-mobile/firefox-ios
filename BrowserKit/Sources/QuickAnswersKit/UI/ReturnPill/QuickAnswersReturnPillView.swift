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
        static let capsuleCornerRadius: CGFloat = 100.0
        static let leadingPadding: CGFloat = 10.0
        static let trailingPadding: CGFloat = 16.0
        static let iconSpacing: CGFloat = 8.0
        static let iconContainerSize: CGFloat = 30.0
        static let iconSize: CGFloat = 16.0
        static let iconBackgroundAlpha: CGFloat = 0.1
        static let iconGradientStartPoint = CGPoint(x: 0.5, y: 0.0)
        static let iconGradientEndPoint = CGPoint(x: 0.5, y: 1.0)
        static let tintAlpha: CGFloat = 0.25
        static let borderWidth: CGFloat = 0.5
        static let shadowOffset = CGSize(width: 0, height: 8)
        static let shadowRadius: CGFloat = 15.0
        static let shadowOpacity: Float = 0.02
        static let minimizeDuration: TimeInterval = 0.2
        static let fadeDistance: CGFloat = 200.0
        static let maxFade: CGFloat = 0.6
        static let removeDuration: TimeInterval = 0.2
        static let flyOutSizeMultiplier: CGFloat = 1.5
        static let minimumDirectionVelocity: CGFloat = 1.0
        static let springBackDuration: TimeInterval = 0.5
        static let springBackDamping: CGFloat = 0.7
        static let springBackVelocity: CGFloat = 1.0
    }

    public static let identifier = "QuickAnswers.returnPill"

    private let onTap: (Bool) -> Void
    private let onSwipeAway: () -> Void
    private let icon = UIImage(named: StandardImageIdentifiers.Large.audioWave)

    private(set) var isMinimized = false
    private let labelStack: UIStackView = .build {
        $0.axis = .vertical
    }
    private let titleLabel: UILabel = .build {
        $0.font = FXFontStyles.Bold.caption1.scaledFont()
        $0.adjustsFontForContentSizeCategory = true
        $0.maximumContentSizeCategory = .accessibilityMedium
        $0.lineBreakMode = .byTruncatingTail
    }
    private let subtitleLabel: UILabel = .build {
        $0.font = FXFontStyles.Regular.caption1.scaledFont()
        $0.adjustsFontForContentSizeCategory = true
        $0.maximumContentSizeCategory = .accessibilityMedium
        $0.lineBreakMode = .byTruncatingTail
    }
    private let effectView: UIVisualEffectView = .build {
        $0.clipsToBounds = true
        $0.layer.cornerRadius = UX.capsuleCornerRadius
        if #available(iOS 26, *), !DeviceInfo.isRunningLiquidGlassEarlyBeta {
            let glassEffect = UIGlassEffect()
            glassEffect.isInteractive = true
            $0.effect = glassEffect
        } else {
            $0.effect = UIBlurEffect(style: .systemUltraThinMaterial)
        }
    }
    private let iconContainer: UIView = .build()
    private let iconBackgroundView: UIView = .build {
        $0.layer.cornerRadius = UX.iconContainerSize / 2
        $0.clipsToBounds = true
    }
    private let iconBackgroundGradient: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.frame = CGRect(x: 0.0, y: 0.0, width: UX.iconContainerSize, height: UX.iconContainerSize)
        layer.startPoint = UX.iconGradientStartPoint
        layer.endPoint = UX.iconGradientEndPoint
        return layer
    }()
    private let iconImageView: UIImageView = .build {
        $0.contentMode = .scaleAspectFit
    }

    private var expandedConstraints: [NSLayoutConstraint] = []
    private var minimizedConstraints: [NSLayoutConstraint] = []

    public init(onTap: @escaping (Bool) -> Void, onSwipeAway: @escaping () -> Void) {
        self.onTap = onTap
        self.onSwipeAway = onSwipeAway
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
        setupGestures()
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
        let isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        let layoutHost = superview ?? self
        if animated {
            layoutHost.layoutIfNeeded()
        }
        if isMinimized {
            NSLayoutConstraint.deactivate(expandedConstraints)
            NSLayoutConstraint.activate(minimizedConstraints)
        } else {
            NSLayoutConstraint.deactivate(minimizedConstraints)
            NSLayoutConstraint.activate(expandedConstraints)
        }

        let updateAppearance: @MainActor () -> Void = {
            let contentAlpha: CGFloat = isMinimized ? 0.0 : 1.0
            self.labelStack.alpha = contentAlpha
            self.iconBackgroundView.alpha = contentAlpha
        }
        guard animated else {
            updateAppearance()
            return
        }
        UIView.animate(withDuration: UX.minimizeDuration, delay: 0, options: .curveEaseOut) {
            updateAppearance()
            if !isReduceMotionEnabled {
                layoutHost.layoutIfNeeded()
            }
        }
    }

    override public func accessibilityActivate() -> Bool {
        onTap(isMinimized)
        return true
    }

    // MARK: - Setup

    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.shadowOffset = UX.shadowOffset
        layer.shadowRadius = UX.shadowRadius
        layer.shadowOpacity = UX.shadowOpacity

        iconBackgroundView.layer.addSublayer(iconBackgroundGradient)
        labelStack.addArrangedSubview(titleLabel)
        labelStack.addArrangedSubview(subtitleLabel)
        iconContainer.addSubviews(iconBackgroundView, iconImageView)
        addSubviews(effectView, iconContainer, labelStack)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            effectView.topAnchor.constraint(equalTo: topAnchor),
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),

            widthAnchor.constraint(lessThanOrEqualToConstant: UX.maxWidth),

            iconContainer.widthAnchor.constraint(equalToConstant: UX.iconContainerSize),
            iconContainer.heightAnchor.constraint(equalToConstant: UX.iconContainerSize),
            iconContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconBackgroundView.topAnchor.constraint(equalTo: iconContainer.topAnchor),
            iconBackgroundView.leadingAnchor.constraint(equalTo: iconContainer.leadingAnchor),
            iconBackgroundView.trailingAnchor.constraint(equalTo: iconContainer.trailingAnchor),
            iconBackgroundView.bottomAnchor.constraint(equalTo: iconContainer.bottomAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: UX.iconSize),
            iconImageView.heightAnchor.constraint(equalToConstant: UX.iconSize),
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),

            labelStack.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: UX.iconSpacing),
            labelStack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        expandedConstraints = [
            heightAnchor.constraint(equalToConstant: UX.expandedHeight),
            iconContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.leadingPadding),
            labelStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.trailingPadding)
        ]
        minimizedConstraints = [
            widthAnchor.constraint(equalToConstant: UX.minimizedSize),
            heightAnchor.constraint(equalToConstant: UX.minimizedSize),
            iconContainer.centerXAnchor.constraint(equalTo: centerXAnchor)
        ]
        NSLayoutConstraint.activate(expandedConstraints)
    }

    private func setupGestures() {
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
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
            let distance = hypot(translation.x, translation.y)
            transform = CGAffineTransform(translationX: translation.x, y: translation.y)
            alpha = 1.0 - min(distance / UX.fadeDistance, 1.0) * UX.maxFade
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
        let reference = hypot(velocity.x, velocity.y) > UX.minimumDirectionVelocity ? velocity : translation
        let length = hypot(reference.x, reference.y)
        let direction = length > 0 ? CGPoint(x: reference.x / length, y: reference.y / length) : .zero
        let distance = max(bounds.width, bounds.height) * UX.flyOutSizeMultiplier
        let isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        UIView.animate(withDuration: UX.removeDuration, delay: 0, options: .curveEaseOut) {
            self.alpha = 0.0
            guard !isReduceMotionEnabled else { return }
            self.transform = CGAffineTransform(
                translationX: translation.x + direction.x * distance,
                y: translation.y + direction.y * distance
            )
        } completion: { _ in
            self.onSwipeAway()
        }
    }

    private func springBack() {
        let restore = {
            self.transform = .identity
            self.alpha = 1.0
        }
        guard !UIAccessibility.isReduceMotionEnabled else {
            UIView.animate(withDuration: UX.removeDuration, delay: 0, options: .curveEaseOut, animations: restore)
            return
        }
        UIView.animate(
            withDuration: UX.springBackDuration,
            delay: 0,
            usingSpringWithDamping: UX.springBackDamping,
            initialSpringVelocity: UX.springBackVelocity,
            animations: restore
        )
    }

    // MARK: - ThemeApplicable

    public func applyTheme(theme: Theme) {
        let colors = theme.colors
        let gradientStops = [colors.gradientAIStrongStop1, colors.gradientAIStrongStop2, colors.gradientAIStrongStop3]
        iconBackgroundGradient.colors = gradientStops.map { $0.withAlphaComponent(UX.iconBackgroundAlpha).cgColor }
        iconImageView.image = gradientTintedIcon(stops: gradientStops)
        titleLabel.textColor = colors.textPrimary
        subtitleLabel.textColor = colors.textSecondary
        layer.shadowColor = colors.shadowDefault.cgColor
        if effectView.effect is UIBlurEffect {
            effectView.contentView.backgroundColor = colors.layer1.withAlphaComponent(UX.tintAlpha)
            effectView.layer.borderWidth = UX.borderWidth
            effectView.layer.borderColor = colors.borderPrimary.cgColor
        }
    }

    private func gradientTintedIcon(stops: [UIColor]) -> UIImage? {
        guard let icon,
              let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: stops.map(\.cgColor) as CFArray,
                locations: nil
              )
        else { return nil }

        let rect = CGRect(origin: .zero, size: icon.size)
        return UIGraphicsImageRenderer(size: icon.size).image { context in
            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: rect.midX, y: rect.minY),
                end: CGPoint(x: rect.midX, y: rect.maxY),
                options: []
            )
            icon.draw(in: rect, blendMode: .destinationIn, alpha: 1.0)
        }.withRenderingMode(.alwaysOriginal)
    }
}
