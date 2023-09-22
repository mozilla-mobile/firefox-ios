// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import Foundation
import UIKit

class ButtonsViewController: UIViewController, Themeable {
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    private lazy var primaryButton: PrimaryRoundedButton = .build { _ in }
    private lazy var secondaryButton: SecondaryRoundedButton = .build { _ in }

    private lazy var buttonStackView: UIStackView = .build { stackView in
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.axis = .vertical
        stackView.spacing = 16
    }

    init(themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.themeManager = themeManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        listenForThemeChange(view)
        applyTheme()

        setupView()

        let primaryViewModel = PrimaryRoundedButtonViewModel(title: "Primary",
                                                             a11yIdentifier: "a11yPrimary")
        primaryButton.configure(viewModel: primaryViewModel)

        let secondaryViewModel = SecondaryRoundedButtonViewModel(title: "Secondary",
                                                                 a11yIdentifier: "a11ySecondary")
        secondaryButton.configure(viewModel: secondaryViewModel)

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

    // MARK: Themeable

    func applyTheme() {
        view.backgroundColor = themeManager.currentTheme.colors.layer1
        buttonStackView.backgroundColor = .clear
    }
}
