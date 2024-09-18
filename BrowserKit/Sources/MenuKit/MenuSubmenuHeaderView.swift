// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit

public protocol MainMenuDetailNavigationHandler: AnyObject {
    func backToMainView()
}

final class MenuSubmenuHeaderView: UIView, ThemeApplicable {
    // MARK: - UI Elements
    private lazy var backButton: UIButton = .build { button in
        button.addTarget(self, action: #selector(self.backButtonTapped), for: .touchUpInside)
    }

    // MARK: - Properties
    weak var navigationDelegate: MainMenuDetailNavigationHandler?

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup
    private func setupView() {
        addSubviews(backButton)

        NSLayoutConstraint.activate([
            backButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            backButton.heightAnchor.constraint(equalToConstant: 35),
            backButton.widthAnchor.constraint(equalToConstant: 60),
        ])
    }

    @objc
    private func backButtonTapped() {
        navigationDelegate?.backToMainView()
    }

    // MARK: Theme Applicable
    func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layer3
        backButton.tintColor = theme.colors.textAccent
    }
}
