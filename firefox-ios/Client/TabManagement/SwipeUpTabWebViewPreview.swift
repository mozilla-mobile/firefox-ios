// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import SiteImageView

class SwipeUpTabWebViewPreview: UIView, ThemeApplicable {
    private struct UX {
        static let screenshotViewContainerShadowCornerRadius: CGFloat = 25.0
        static let screenshotViewContainerVerticalPadding: CGFloat = 100.0
        static let screenshotViewContainerShadowOffset = CGSize(width: 2, height: 4)
        static let triggerBoundsHeightPercentage: CGFloat = 0.25
        static let fingerCardPositionRatio: CGFloat = 2.0 / 3.0
        static let closeReleaseThreshold: CGFloat = 1.0 / 3.0
        static let tabTrayReleaseThreshold: CGFloat = 2.0 / 3.0
        static let previewFadeOutDuration: CGFloat = 0.2
        static let restoreDuration: CGFloat = 0.2
        static let translateDuration: CGFloat = 0.15
        static let initialTransformDuration: CGFloat = 0.2
        static let tossPreviewEndingHeight: CGFloat = -1000.0
        static let minimumTabPreviewScale: CGFloat = 0.33
        static let tossPreviewXScale: CGFloat = 0.6
        static let tossPreviewYScale: CGFloat = 0.6
    }

    private let swipeGestureFeatureFlagProvider: SwipeGestureFeatureFlagProvider

    private let backgroundView: UIVisualEffectView = .build {
        if #available(iOS 26, *) {
            $0.effect = UIGlassEffect(style: .regular)
        } else {
            $0.effect = UIBlurEffect(style: .systemUltraThinMaterial)
        }
    }
    private let tabBackgroundHover: UIView = .build()
    private let screenshotViewContainer: UIView = .build {
        $0.layer.masksToBounds = false
        $0.layer.shadowOffset = UX.screenshotViewContainerShadowOffset
        $0.applyScreenCornerRadius()
    }
    private let screenshotView: UIImageView = .build {
        $0.contentMode = .top
        $0.clipsToBounds = true
        $0.applyScreenCornerRadius()
    }
    private let closeButton: UIButton = .build {
        if #available(iOS 26, *) {
            $0.configuration = .prominentClearGlass()
        } else {
            $0.configuration = .filled()
            $0.configuration?.cornerStyle = .capsule
        }
        $0.configuration?.image = UIImage(named: StandardImageIdentifiers.Large.cross)?.withRenderingMode(.alwaysTemplate)
    }

    private var screenshotViewContainerTopConstraint: NSLayoutConstraint?
    private var screenshotViewContainerBottomConstraint: NSLayoutConstraint?
    private var tabBackgroundHoverTopConstraint: NSLayoutConstraint?
    private var tabBackgroundHoverBottomConstraint: NSLayoutConstraint?

    var previewCardFrame: CGRect {
        return screenshotViewContainer.frame
    }

    /// The action to take when the pan gesture ends, based on where the finger is released on screen.
    enum ReleaseOutcome {
        case cancel
        case openTabTray
        case closeTab
    }

    // MARK: - Inits
    init(frame: CGRect, swipeGestureFeatureFlagProvider: SwipeGestureFeatureFlagProvider) {
        self.swipeGestureFeatureFlagProvider = swipeGestureFeatureFlagProvider
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not implemented")
    }

    // MARK: - Layout
    private func setup() {
        addSubviews(tabBackgroundHover, backgroundView, screenshotViewContainer, closeButton)
        screenshotViewContainer.addSubview(screenshotView)

        tabBackgroundHoverTopConstraint = tabBackgroundHover.topAnchor.constraint(equalTo: topAnchor)
        tabBackgroundHoverBottomConstraint = tabBackgroundHover.bottomAnchor.constraint(equalTo: bottomAnchor)
        tabBackgroundHoverTopConstraint?.isActive = true
        tabBackgroundHoverBottomConstraint?.isActive = true

        screenshotViewContainerTopConstraint = screenshotViewContainer.topAnchor.constraint(equalTo: topAnchor)
        screenshotViewContainerBottomConstraint = screenshotViewContainer.bottomAnchor.constraint(equalTo: bottomAnchor)
        screenshotViewContainerTopConstraint?.isActive = true
        screenshotViewContainerBottomConstraint?.isActive = true
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            closeButton.centerXAnchor.constraint(equalTo: centerXAnchor),

            tabBackgroundHover.leadingAnchor.constraint(equalTo: leadingAnchor),
            tabBackgroundHover.trailingAnchor.constraint(equalTo: trailingAnchor),

            screenshotViewContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            screenshotViewContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        screenshotView.pinToSuperview()
        backgroundView.pinToSuperview()
    }

    // MARK: - Public Functions
    func addTabScreenshot(image: UIImage?) {
        screenshotView.image = image
    }

    func setInitialTransform(topPadding: CGFloat, bottomPadding: CGFloat) {
        screenshotView.layer.cornerRadius = 0
        tabBackgroundHoverTopConstraint?.constant = topPadding
        tabBackgroundHoverBottomConstraint?.constant = -bottomPadding

        if swipeGestureFeatureFlagProvider.isCloseTabEnabled {
            closeButton.transform = .identity.translatedBy(x: 0.0, y: -closeButton.bounds.height * 2.0)
            closeButton.alpha = 0.0
        } else {
            closeButton.isHidden = true
        }

        UIView.animate(withDuration: UX.initialTransformDuration) { [self] in
            alpha = 1.0
            layer.zPosition = 1000
            screenshotView.applyScreenCornerRadius()
            guard screenshotViewContainerTopConstraint?.constant != topPadding ||
                  screenshotViewContainerBottomConstraint?.constant != bottomPadding else { return }
            screenshotViewContainerTopConstraint?.constant = topPadding
            screenshotViewContainerBottomConstraint?.constant = -bottomPadding
            layoutIfNeeded()
        }
    }

    func translate(_ translation: CGPoint, fingerLocation: CGPoint) {
        let shouldShowCloseButton = (
            releaseOutcome(fingerLocation: fingerLocation) == .closeTab &&
            swipeGestureFeatureFlagProvider.isCloseTabEnabled
        )

        let shouldTriggerHaptic = closeButton.alpha != (shouldShowCloseButton ? 1 : 0)
        if shouldTriggerHaptic {
            addHaptics()
        }
        UIView.animate(withDuration: UX.translateDuration) {
            self.closeButton.transform = shouldShowCloseButton ?
                .identity :
                .init(translationX: 0.0, y: -self.closeButton.bounds.height * 2)
            self.closeButton.alpha = shouldShowCloseButton ? 1.0 : 0.0
        }

        // Shrink continuously during the gesture
        let scale = max((1 - abs(translation.y) / bounds.height), UX.minimumTabPreviewScale)

        // Transform that places the finger horizontally centered and <fingerCardPositionRatio> down the card.
        let naturalCenter = screenshotViewContainer.center
        let scaledHeight = scale * screenshotViewContainer.bounds.height
        let centerOffsetFromFinger = (UX.fingerCardPositionRatio - 0.5) * scaledHeight
        let targetTranslationX = fingerLocation.x - naturalCenter.x
        let targetTranslationY = fingerLocation.y - centerOffsetFromFinger - naturalCenter.y

        // Blend in from the full-screen start so the preview slides into place instead of jumping.
        let clampDistance = bounds.height * UX.triggerBoundsHeightPercentage
        let progress = min(1, abs(translation.y) / clampDistance)

        screenshotViewContainer.transform = .identity.translatedBy(
            x: targetTranslationX * progress,
            y: targetTranslationY * progress
        ).scaledBy(
            x: scale,
            y: scale
        )
    }

    func releaseOutcome(fingerLocation: CGPoint) -> ReleaseOutcome {
        guard bounds.height > 0 else { return .cancel }
        let fractionFromTop = fingerLocation.y / bounds.height
        if fractionFromTop <= UX.closeReleaseThreshold {
            if swipeGestureFeatureFlagProvider.isCloseTabEnabled {
                return .closeTab
            }
        }
        if fractionFromTop <= UX.tabTrayReleaseThreshold {
            return .openTabTray
        }
        return .cancel
    }

    func restore() {
        UIView.animate(withDuration: UX.restoreDuration) { [self] in
            screenshotViewContainer.transform = .identity
            screenshotView.layer.cornerRadius = 0
        } completion: { [weak self] _ in
            self?.alpha = 0.0
        }
    }

    func tossPreview() {
        screenshotViewContainer.transform = .identity.translatedBy(x: 0, y: UX.tossPreviewEndingHeight).scaledBy(
            x: UX.tossPreviewXScale,
            y: UX.tossPreviewYScale
        )
    }

    /// Fades the preview out in place (without snapping back to full screen) and resets it for reuse.
    func dismissForTabTray() {
        UIView.animate(withDuration: UX.previewFadeOutDuration) { [self] in
            alpha = 0.0
        } completion: { [weak self] _ in
            self?.screenshotViewContainer.transform = .identity
            self?.screenshotView.layer.cornerRadius = 0
            self?.layer.zPosition = 0
        }
    }

    func applyTheme(theme: Theme) {
        tabBackgroundHover.backgroundColor = theme.colors.layer3
        if #unavailable(iOS 26) {
            closeButton.configuration?.baseBackgroundColor = theme.colors.layer2
        }
        closeButton.configuration?.baseForegroundColor = theme.colors.iconPrimary
        screenshotViewContainer.layer.shadowColor = theme.colors.shadowStrong.cgColor
    }

    // MARK: - Private Functions
    private func addHaptics() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
    }
}
