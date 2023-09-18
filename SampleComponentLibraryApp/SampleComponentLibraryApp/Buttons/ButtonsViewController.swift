// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import Foundation
import UIKit

class ButtonsViewController: UIViewController {
    private lazy var primaryButton: PrimaryRoundedButton = .build { _ in }
    private lazy var secondaryButton: SecondaryRoundedButton = .build { _ in }

    private lazy var buttonStackView: UIStackView = .build { stackView in
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        stackView.axis = .vertical
        stackView.spacing = 16
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()

        view.backgroundColor = .white
        let primaryViewModel = PrimaryRoundedButtonViewModel(title: "Primary",
                                                             a11yIdentifier: "a11yPrimary")
        primaryButton.configure(viewModel: primaryViewModel)

        let secondaryViewModel = SecondaryRoundedButtonViewModel(title: "Secondary",
                                                                 a11yIdentifier: "a11ySecondary")
        secondaryButton.configure(viewModel: secondaryViewModel)

        let themeManager: ThemeManager = AppContainer.shared.resolve()
        primaryButton.applyTheme(theme: themeManager.currentTheme)
        secondaryButton.applyTheme(theme: themeManager.currentTheme)
    }

    private func setupView() {
        view.addSubview(buttonStackView)
        buttonStackView.addArrangedSubview(primaryButton)
        buttonStackView.addArrangedSubview(secondaryButton)

        NSLayoutConstraint.activate([
            buttonStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            buttonStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
}
