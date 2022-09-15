// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

class ThemedNavigationController: DismissableNavigationViewController, Themeable {

    var themeManager: ThemeManager = AppContainer.shared.resolve()
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    var presentingModalViewControllerDelegate: PresentingModalViewControllerDelegate?

    @objc func done() {
        if let delegate = presentingModalViewControllerDelegate {
            delegate.dismissPresentedModalViewController(self, animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return topViewController?.preferredStatusBarStyle ?? LegacyThemeManager.instance.statusBarStyle
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        modalPresentationStyle = .overFullScreen
        modalPresentationCapturesStatusBarAppearance = true
        applyTheme()
        listenForThemeChange()
    }
}

extension ThemedNavigationController {
    private func setupNavigationBarAppearance(theme: Theme) {
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithDefaultBackground()
        standardAppearance.backgroundColor = theme.colors.layer1
        standardAppearance.titleTextAttributes = [.foregroundColor: theme.colors.textPrimary]

        navigationBar.standardAppearance = standardAppearance
        navigationBar.compactAppearance = standardAppearance
        navigationBar.scrollEdgeAppearance = standardAppearance
        if #available(iOS 15.0, *) {
            navigationBar.compactScrollEdgeAppearance = standardAppearance
        }
        navigationBar.tintColor = theme.colors.actionPrimary
    }

    func applyTheme() {
        setupNavigationBarAppearance(theme: themeManager.currentTheme)
        setNeedsStatusBarAppearanceUpdate()

        // TODO: Remove with legacy theme clean up FXIOS-3960
        viewControllers.forEach {
            ($0 as? NotificationThemeable)?.applyTheme()
        }
    }
}

protocol PresentingModalViewControllerDelegate: AnyObject {
    func dismissPresentedModalViewController(_ modalViewController: UIViewController, animated: Bool)
}

class ModalSettingsNavigationController: UINavigationController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
}
