// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import Common

class ThemedDefaultNavigationController: DismissableNavigationViewController, Themeable {
    var themeManager: ThemeManager
    var notificationCenter: NotificationProtocol
    var themeObserver: NSObjectProtocol?

    init(rootViewController: UIViewController,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(rootViewController: rootViewController)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        listenForThemeChange(view)
        applyTheme()
    }

    private func setupNavigationBarAppearance() {
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithDefaultBackground()
        standardAppearance.backgroundColor = themeManager.currentTheme.colors.layer1
        standardAppearance.shadowColor = nil
        standardAppearance.shadowImage = UIImage()
        standardAppearance.titleTextAttributes = [.foregroundColor: themeManager.currentTheme.colors.textPrimary]
        standardAppearance.largeTitleTextAttributes = [.foregroundColor: themeManager.currentTheme.colors.textPrimary]

        navigationBar.standardAppearance = standardAppearance
        navigationBar.compactAppearance = standardAppearance
        navigationBar.scrollEdgeAppearance = standardAppearance
        navigationBar.compactScrollEdgeAppearance = standardAppearance
        navigationBar.tintColor = themeManager.currentTheme.colors.textPrimary
    }

    private func setupToolBarAppearance() {
        let standardAppearance = UIToolbarAppearance()
        standardAppearance.configureWithDefaultBackground()
        standardAppearance.backgroundColor = themeManager.currentTheme.colors.layer1
        standardAppearance.shadowColor = nil
        standardAppearance.shadowImage = UIImage()

        toolbar.standardAppearance = standardAppearance
        toolbar.compactAppearance = standardAppearance
        toolbar.scrollEdgeAppearance = standardAppearance
        toolbar.compactScrollEdgeAppearance = standardAppearance
        toolbar.tintColor = themeManager.currentTheme.colors.textPrimary
    }

    // MARK: - Themable

    func applyTheme() {
        setupNavigationBarAppearance()
        setupToolBarAppearance()

        setNeedsStatusBarAppearanceUpdate()
    }
}
