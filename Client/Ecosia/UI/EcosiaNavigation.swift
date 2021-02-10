/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

final class EcosiaNavigation: UINavigationController, Themeable {

    convenience init(delegate: EcosiaHomeDelegate?) {
        self.init(rootViewController: EcosiaHome(delegate: delegate))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        navigationBar.prefersLargeTitles = true
        NotificationCenter.default.addObserver(self, selector: #selector(displayThemeChanged), name: .DisplayThemeChanged, object: nil)
        applyTheme()
    }

    func applyTheme() {
        viewControllers.forEach { ($0 as? Themeable)?.applyTheme() }

        navigationBar.backgroundColor = UIColor.theme.ecosia.primaryBackground
        navigationBar.tintColor = UIColor.theme.ecosia.secondaryBrand
        navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.theme.ecosia.secondaryBrand
        ]
        navigationBar.largeTitleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.theme.ecosia.secondaryBrand
        ]
    }

    @objc private func displayThemeChanged(notification: Notification) {
        applyTheme()
    }
}
