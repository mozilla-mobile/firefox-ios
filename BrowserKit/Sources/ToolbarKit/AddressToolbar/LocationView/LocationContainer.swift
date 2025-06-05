// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

class LocationContainer: UIView, ThemeApplicable {
    private enum UX {
        static let shadowRadius: CGFloat = 14
        static let shadowOpacity: Float = 1
        static let shadowOffset = CGSize(width: 0, height: 2)
    }

    private var theme: Theme?

    override public func layoutSubviews() {
        super.layoutSubviews()

        guard let theme else { return }
        setupShadow(theme: theme)
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
    }
}
