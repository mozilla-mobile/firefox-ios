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
    let windowUUID: WindowUUID

    var currentWindowUUID: UUID? { return windowUUID }

    init(rootViewController: UIViewController,
         windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.windowUUID = windowUUID
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
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithDefaultBackground()
        standardAppearance.backgroundColor = theme.colors.layer1
        standardAppearance.shadowColor = nil
        standardAppearance.shadowImage = UIImage()
        standardAppearance.titleTextAttributes = [.foregroundColor: theme.colors.textPrimary]
        standardAppearance.largeTitleTextAttributes = [.foregroundColor: theme.colors.textPrimary]

        navigationBar.standardAppearance = standardAppearance
        navigationBar.compactAppearance = standardAppearance
        navigationBar.scrollEdgeAppearance = standardAppearance
        navigationBar.compactScrollEdgeAppearance = standardAppearance
        navigationBar.tintColor = theme.colors.textPrimary
    }

    private func setupToolBarAppearance() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        let standardAppearance = UIToolbarAppearance()
        standardAppearance.configureWithDefaultBackground()
        standardAppearance.backgroundColor = theme.colors.layer1
        standardAppearance.shadowColor = nil
        standardAppearance.shadowImage = UIImage()

        toolbar.standardAppearance = standardAppearance
        toolbar.compactAppearance = standardAppearance
        toolbar.scrollEdgeAppearance = standardAppearance
        toolbar.compactScrollEdgeAppearance = standardAppearance
        toolbar.tintColor = theme.colors.textPrimary
    }

    // MARK: - Themable

    func applyTheme() {
        setupNavigationBarAppearance()
        setupToolBarAppearance()

        setNeedsStatusBarAppearanceUpdate()
    }
}
