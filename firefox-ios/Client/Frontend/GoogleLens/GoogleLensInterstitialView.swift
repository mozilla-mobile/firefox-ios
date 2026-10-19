// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

final class GoogleLensInterstitialView: UIView, ThemeApplicable {
    private let materialView: UIVisualEffectView = .build { view in
        view.effect = UIBlurEffect(style: .systemUltraThinMaterialDark)
    }
    private let reduceTransparencyProvider: () -> Bool

    init(reduceTransparencyProvider: @escaping () -> Bool = { UIAccessibility.isReduceTransparencyEnabled }) {
        self.reduceTransparencyProvider = reduceTransparencyProvider
        super.init(frame: .zero)
        accessibilityViewIsModal = true
        addSubview(materialView)
        NSLayoutConstraint.activate([
            materialView.topAnchor.constraint(equalTo: topAnchor),
            materialView.bottomAnchor.constraint(equalTo: bottomAnchor),
            materialView.leadingAnchor.constraint(equalTo: leadingAnchor),
            materialView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme(theme: Theme) {
        let reduceTransparency = reduceTransparencyProvider()
        materialView.isHidden = reduceTransparency
        backgroundColor = reduceTransparency ? theme.colors.layerScrim.withAlphaComponent(1) : .clear
    }
}
