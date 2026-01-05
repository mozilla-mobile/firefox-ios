// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import SiteImageView

class SwipeUpTabWebViewPreview: UIView, ThemeApplicable {
    private struct UX {
        @MainActor
        static var screenshotViewContainerCornerRadius: CGFloat {
            return UIScreen.main.value(forKey: "_displayCornerRadius") as? CGFloat ?? 25.0
        }
        static let screenshotViewContainerShadowCornerRadius: CGFloat = 25.0
        static let screenshotViewContainerVerticalPadding: CGFloat = 100.0
        static let screenshotViewContainerShadowOffset = CGSize(width: 2, height: 4)
        static let deleteOverlayBackgroundColor: UIColor = .systemRed.withAlphaComponent(0.8)
    }
    
    private let tabBackgroundHover: UIView = .build()
    private let screenshotViewContainer: UIView = .build {
        $0.layer.masksToBounds = false
        $0.layer.shadowOffset = UX.screenshotViewContainerShadowOffset
        $0.layer.shadowRadius = UX.screenshotViewContainerCornerRadius
    }
    private let screenshotView: UIImageView = .build {
        $0.contentMode = .top
        $0.clipsToBounds = true
        $0.layer.cornerRadius = UX.screenshotViewContainerCornerRadius
    }
    private let deleteOverlay: UIView = .build {
        $0.layer.cornerRadius = UX.screenshotViewContainerCornerRadius
        $0.backgroundColor = UX.deleteOverlayBackgroundColor
        $0.alpha = 0.0
    }
    
    private var screenshotViewContainerTopConstraint: NSLayoutConstraint?
    private var screenshotViewContainerBottomConstraint: NSLayoutConstraint?
    private var tabBackgroundHoverTopConstraint: NSLayoutConstraint?
    private var tabBackgroundHoverBottomConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setup() {
        addSubview(tabBackgroundHover)
        if #available(iOS 26.0, *) {
            let background = UIVisualEffectView(effect: UIGlassEffect(style: .clear))
            addSubview(background)
            background.pinToSuperview()
        }
        
        addSubview(screenshotViewContainer)
        screenshotViewContainer.addSubview(screenshotView)
        screenshotViewContainer.addSubview(deleteOverlay)
        
        tabBackgroundHoverTopConstraint = tabBackgroundHover.topAnchor.constraint(equalTo: topAnchor)
        tabBackgroundHoverBottomConstraint = tabBackgroundHover.bottomAnchor.constraint(equalTo: bottomAnchor)
        tabBackgroundHoverTopConstraint?.isActive = true
        tabBackgroundHoverBottomConstraint?.isActive = true
        
        screenshotViewContainerTopConstraint = screenshotViewContainer.topAnchor.constraint(equalTo: topAnchor)
        screenshotViewContainerBottomConstraint = screenshotViewContainer.bottomAnchor.constraint(equalTo: bottomAnchor)
        screenshotViewContainerTopConstraint?.isActive = true
        screenshotViewContainerBottomConstraint?.isActive = true
        NSLayoutConstraint.activate([
            tabBackgroundHover.leadingAnchor.constraint(equalTo: leadingAnchor),
            tabBackgroundHover.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            screenshotViewContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            screenshotViewContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        screenshotView.pinToSuperview()
        deleteOverlay.pinToSuperview()
    }

    func addTabScreenshot(image: UIImage?) {
        screenshotView.image = image
    }
    
    func setInitialTransform(topPadding: CGFloat, bottomPadding: CGFloat) {
        screenshotView.layer.cornerRadius = 0
        tabBackgroundHoverTopConstraint?.constant = topPadding
        tabBackgroundHoverBottomConstraint?.constant = -bottomPadding
        UIView.animate(withDuration: 0.2) { [self] in
            alpha = 1.0
            layer.zPosition = 1000
            screenshotViewContainerTopConstraint?.constant = topPadding
            screenshotViewContainerBottomConstraint?.constant = -bottomPadding
            screenshotView.layer.cornerRadius = UX.screenshotViewContainerCornerRadius
            layoutIfNeeded()
        }
    }

    func translate(position: CGPoint) {
        let shouldShowRemoveOverlay = position.y < -(bounds.size.height / 2.7)
        let shouldAnimateOverlay = deleteOverlay.alpha != (shouldShowRemoveOverlay ? 1 : 0)
        if shouldAnimateOverlay {
            addHaptics()
        }
        UIView.animate(withDuration: 0.15) {
            self.deleteOverlay.alpha = shouldShowRemoveOverlay ? 1 : 0
        }
        let scale = 1 - abs(position.y) / bounds.height
        screenshotViewContainer.transform = .identity.translatedBy(x: position.x,
                                                          y: position.y).scaledBy(
            x: scale,
            y: scale
        )
    }

    private func addHaptics() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
    }

    func restore() {
        UIView.animate(withDuration: 0.2) { [self] in
            screenshotViewContainer.transform = .identity
            screenshotView.layer.cornerRadius = 0
        } completion: { [weak self] _ in
            self?.alpha = 0.0
        }
    }

    func tossPreview() {
        screenshotViewContainer.transform = .identity.translatedBy(x: 0, y: -500).scaledBy(
            x: 0.6,
            y: 0.6
        )
    }

    func applyTheme(theme: Theme) {
        tabBackgroundHover.backgroundColor = theme.colors.layer3
        screenshotViewContainer.layer.shadowColor = theme.colors.shadowStrong.cgColor
    }
}
