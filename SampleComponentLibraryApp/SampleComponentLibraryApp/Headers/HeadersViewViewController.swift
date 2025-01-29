// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import ComponentLibrary
import Common
import UIKit

class HeadersViewViewController: UIViewController, Themeable {
    let headerTitle = "Website Title"
    let backButtonTitle = "Back"
    let headerSubtitle = "Website Subtitle"
    let errorHeaderSubtitle = "Website Error"

    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    private lazy var navigationHeaderView: NavigationHeaderView = .build()
    private lazy var headerView: HeaderView = .build()
    private lazy var errorHeaderView: HeaderView = .build()

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

        headerView.adjustLayout()
        errorHeaderView.adjustLayout()

        headerView.setupDetails(subtitle: headerSubtitle,
                                title: headerTitle,
                                icon: UIImage(named: StandardImageIdentifiers.Large.logoFirefox))
        errorHeaderView.setupDetails(subtitle: errorHeaderSubtitle,
                                     title: headerTitle,
                                     icon: UIImage(named: StandardImageIdentifiers.Large.logoFirefox),
                                     warningIcon: StandardImageIdentifiers.Large.criticalFill,
                                     theme: themeManager.currentTheme)

        headerView.setupAccessibility(closeButtonA11yLabel: "CloseA11yLabel",
                                      closeButtonA11yId: "CloseA11yId")
        errorHeaderView.setupAccessibility(closeButtonA11yLabel: "ErrorCloseA11yLabel",
                                           closeButtonA11yId: "ErrorCloseA11yId")
    }

    private func setupView() {
        view.addSubview(navigationHeaderView)
        view.addSubview(headerView)
        view.addSubview(errorHeaderView)

        NSLayoutConstraint.activate([
            navigationHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            navigationHeaderView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            navigationHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            headerView.topAnchor.constraint(equalTo: navigationHeaderView.bottomAnchor, constant: 40),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            errorHeaderView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 40),
            errorHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            errorHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            errorHeaderView.bottomAnchor.constraint(
                lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -20
            )
        ])
    }

    // MARK: Themeable
    func applyTheme() {
        view.backgroundColor = themeManager.currentTheme.colors.layer1
        navigationHeaderView.applyTheme(theme: themeManager.currentTheme)
        headerView.applyTheme(theme: themeManager.currentTheme)
        errorHeaderView.applyTheme(theme: themeManager.currentTheme)
    }
}
