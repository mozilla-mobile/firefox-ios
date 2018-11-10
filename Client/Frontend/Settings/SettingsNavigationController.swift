/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class ThemedNavigationController: UINavigationController {
    var popoverDelegate: PresentingModalViewControllerDelegate?

    @objc func done() {
        if let delegate = popoverDelegate {
            delegate.dismissPresentedModalViewController(self, animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.instance.statusBarStyle
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        applyTheme()
    }
}

extension ThemedNavigationController: Themeable {
    func applyTheme() {
        navigationBar.barTintColor = UIColor.theme.tableView.headerBackground
        navigationBar.tintColor = UIColor.theme.general.controlTint
        navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.theme.tableView.headerTextDark]
        setNeedsStatusBarAppearanceUpdate()
        viewControllers.forEach {
            ($0 as? Themeable)?.applyTheme()
        }
    }
}

protocol PresentingModalViewControllerDelegate {
    func dismissPresentedModalViewController(_ modalViewController: UIViewController, animated: Bool)
}

class ModalSettingsNavigationController: UINavigationController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
}
