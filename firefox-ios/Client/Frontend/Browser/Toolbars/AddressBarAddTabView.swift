// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Common

final class AddressBarAddTabView: UIView, ThemeApplicable {
    private struct UX {
        static let cornerRadius: CGFloat = 12.0
    }

    private(set) lazy var plusIconView: UIImageView  = .build {
        $0.alpha = 0.0
        $0.image = UIImage(named: StandardImageIdentifiers.Large.plus)
    }

    init() {
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        layer.cornerRadius = UX.cornerRadius
        addSubview(plusIconView)
        NSLayoutConstraint.activate([
            plusIconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            plusIconView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: any Theme) {
        plusIconView.tintColor = theme.colors.textPrimary
        let configuration: TabWebViewPreviewAppearanceConfiguration = .getAppearance(basedOn: theme)
        backgroundColor = configuration.addressBarBackgroundColor
    }
}
