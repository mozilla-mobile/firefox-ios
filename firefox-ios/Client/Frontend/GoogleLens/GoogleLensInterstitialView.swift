// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

final class GoogleLensInterstitialView: UIView, ThemeApplicable {
    private let materialView: UIVisualEffectView = .build { view in
        view.effect = UIBlurEffect(style: .systemUltraThinMaterialDark)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        accessibilityViewIsModal = true
        addSubview(materialView)
        materialView.pinToSuperview()
    }

    func applyTheme(theme: Theme) {
        let reduceTransparency = UIAccessibility.isReduceTransparencyEnabled
        materialView.isHidden = reduceTransparency
        backgroundColor = reduceTransparency ? theme.colors.layerScrim.withAlphaComponent(1) : .clear
    }
}
