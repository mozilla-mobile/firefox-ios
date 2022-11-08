/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

final class EcosiaNavigation: UINavigationController, NotificationThemeable {
    required init?(coder aDecoder: NSCoder) {
        nil
    }
    
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)

        if traitCollection.userInterfaceIdiom == .pad {
            modalPresentationStyle = .formSheet
            preferredContentSize = .init(width: 544, height: .max)
        } else {
            modalPresentationCapturesStatusBarAppearance = true
        }
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
        (topViewController as? NotificationThemeable)?.applyTheme()
    }

    @objc private func displayThemeChanged(notification: Notification) {
        applyTheme()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
}
