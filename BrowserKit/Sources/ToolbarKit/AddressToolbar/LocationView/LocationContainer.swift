// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

final class LocationContainer: UIView, ThemeApplicable {
    private enum UX {
        static let shadowRadius: CGFloat = 14
        static let shadowOpacity: Float = 1
        static let shadowOffset = CGSize(width: 0, height: 2)
    }

    private lazy var glass: UIVisualEffectView = .build { view in
        if #available(iOS 26.0, *) {
            let glassEffect = UIGlassEffect(style: .regular)
            glassEffect.isInteractive = true
            glassEffect.tintColor = .darkGray
            view.effect = glassEffect
        }
    }

    private var theme: Theme?

    override public func layoutSubviews() {
        super.layoutSubviews()
        guard let theme else { return }
        setupShadow(theme: theme)
        self.addSubview(glass)

        NSLayoutConstraint.activate([
            glass.topAnchor.constraint(equalTo: topAnchor),
            glass.leadingAnchor.constraint(equalTo: leadingAnchor),
            glass.trailingAnchor.constraint(equalTo: trailingAnchor),
            glass.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func setupShadow(theme: Theme) {
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
        layer.shadowRadius = UX.shadowRadius
        layer.shadowOffset = UX.shadowOffset
        layer.shadowColor = theme.colors.shadowStrong.cgColor
        layer.shadowOpacity = UX.shadowOpacity
        layer.masksToBounds = false
    }

    // MARK: - ThemeApplicable
    public func applyTheme(theme: Theme) {
        setupShadow(theme: theme)
        self.theme = theme
        self.backgroundColor = .clear
    }
}
