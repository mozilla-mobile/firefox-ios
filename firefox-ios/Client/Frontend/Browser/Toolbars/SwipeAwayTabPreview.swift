// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import SiteImageView

class SwipeAwayTabPreview: UIView, ThemeApplicable {
    let screenShotView: UIView = .build()
    private let favicon: FaviconImageView = .build()
    private let deleteOverlay: UIView = .build()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setup() {
        if #available(iOS 26.0, *) {
            let background = UIVisualEffectView(effect: UIGlassEffect(style: .clear))
            addSubview(background)
            background.pinToSuperview()
        }

        addSubview(screenShotView)

        if #available(iOS 26.0, *) {
            let cardBack = UIVisualEffectView(effect: UIGlassEffect(style: .regular))
            screenShotView.addSubview(cardBack)
            cardBack.layer.cornerRadius = 55.0
            cardBack.pinToSuperview()
        }
        screenShotView.addSubview(favicon)
        screenShotView.addSubview(deleteOverlay)
        deleteOverlay.pinToSuperview()
        deleteOverlay.layer.cornerRadius = 55.0
        deleteOverlay.backgroundColor = .systemRed.withAlphaComponent(0.8)
        deleteOverlay.alpha = 0.0

        NSLayoutConstraint.activate([
            screenShotView.topAnchor.constraint(equalTo: topAnchor, constant: 100.0),
            screenShotView.leadingAnchor.constraint(equalTo: leadingAnchor),
            screenShotView.trailingAnchor.constraint(equalTo: trailingAnchor),
            screenShotView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -100.0),

            favicon.centerYAnchor.constraint(equalTo: screenShotView.centerYAnchor),
            favicon.centerXAnchor.constraint(equalTo: screenShotView.centerXAnchor),
            favicon.heightAnchor.constraint(equalToConstant: 80.0),
            favicon.widthAnchor.constraint(equalToConstant: 80.0),
        ])

        screenShotView.layer.masksToBounds = false
        screenShotView.layer.shadowColor = UIColor.black.cgColor
        screenShotView.layer.shadowOffset = CGSize(width: 2, height: 4)
        screenShotView.layer.shadowRadius = 27.0
        screenShotView.layer.shadowOpacity = 0.5
        screenShotView.contentMode = .scaleToFill
    }

    func addImage(url: String, startingPoint: CGFloat) {
        if url.contains("home") {
            favicon.manuallySetImage(UIImage(named: "faviconFox") ?? .checkmark)
        } else {
            favicon.setFavicon(FaviconImageViewModel(siteURLString: url, faviconCornerRadius: 20.0))
        }
        screenShotView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
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
        screenShotView.transform = .identity.translatedBy(x: position.x,
                                                          y: position.y).scaledBy(
            x: 0.7,
            y: 0.7
        )
    }

    private func addHaptics() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
    }

    func restore() {
        screenShotView.transform = .identity
    }

    func tossPreview() {
        screenShotView.transform = .identity.translatedBy(x: 0, y: -500).scaledBy(
            x: 0.6,
            y: 0.6
        )
    }

    func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layer2.withAlphaComponent(0.5)
    }
}
