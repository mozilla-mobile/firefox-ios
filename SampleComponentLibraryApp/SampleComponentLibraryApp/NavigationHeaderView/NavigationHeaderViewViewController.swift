// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import ComponentLibrary
import Common
import UIKit

class NavigationHeaderViewViewController: UIViewController, Themeable {
    let headerTitle = "Website Title"
    let backButtonTitle = "Back"

    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    private lazy var navigationHeaderView: NavigationHeaderView = .build()

    init(themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.themeManager = themeManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()

        listenForThemeChange(view)
        applyTheme()

        navigationHeaderView.setViews(with: headerTitle, and: backButtonTitle)
        navigationHeaderView.adjustLayout()
        navigationHeaderView.setupAccessibility(closeButtonA11yLabel: "CloseA11yLabel",
                                                closeButtonA11yId: "CloseA11yId",
                                                backButtonA11yLabel: "BackButtonA11yLabel",
                                                backButtonA11yId: "BackButtonA11yId")
    }

    private func setupView() {
        view.addSubview(navigationHeaderView)

        NSLayoutConstraint.activate([
            navigationHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            navigationHeaderView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            navigationHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            navigationHeaderView.bottomAnchor.constraint(
                lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -20
            )
        ])
    }

    // MARK: Themeable
    func applyTheme() {
        view.backgroundColor = themeManager.currentTheme.colors.layer1
        navigationHeaderView.applyTheme(theme: themeManager.currentTheme)
    }
}
