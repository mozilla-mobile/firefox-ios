// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Common

public final class AddressToolbarAddTabView: UIView,
                                             ThemeApplicable {
    private lazy var plusIconView: UIImageView  = .build {
        $0.alpha = 0.0
        $0.image = UIImage(named: StandardImageIdentifiers.Large.plus)
    }

    public init() {
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        addSubview(plusIconView)
        NSLayoutConstraint.activate([
            plusIconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            plusIconView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    public func configure(_ configuration: AddressToolbarUXConfiguration) {
        layer.cornerRadius = configuration.toolbarCornerRadius
    }

    public func showHideAddTabIcon(shouldShow: Bool) {
        plusIconView.alpha = shouldShow ? 1.0 : 0.0
    }

    // MARK: - ThemeApplicable

    public func applyTheme(theme: any Theme) {
        plusIconView.tintColor = theme.colors.textPrimary
        backgroundColor = theme.colors.layer2
    }
}
