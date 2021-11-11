// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

class ThemedNavigationController: DismissableNavigationViewController {
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
    }
}

extension ThemedNavigationController: NotificationThemeable {
    private func setupNavigationBarAppearance() {
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithDefaultBackground()
        standardAppearance.backgroundColor = UIColor.theme.tableView.headerBackground
        standardAppearance.titleTextAttributes = [.foregroundColor: UIColor.theme.tableView.headerTextDark]
        
        navigationBar.standardAppearance = standardAppearance
        navigationBar.compactAppearance = standardAppearance
        navigationBar.scrollEdgeAppearance = standardAppearance
        if #available(iOS 15.0, *) {
            navigationBar.compactScrollEdgeAppearance = standardAppearance
        }
        navigationBar.tintColor = UIColor.theme.general.controlTint
    }
    func applyTheme() {
        setupNavigationBarAppearance()
        setNeedsStatusBarAppearanceUpdate()
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
