// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

final class PrivacyWindowHelper {
    private var privacyWindow: UIWindow?

    func showWindow(windowScene: UIWindowScene?, withThemedColor color: UIColor) {
        guard let windowScene else { return }

        privacyWindow = UIWindow(windowScene: windowScene)
        privacyWindow?.rootViewController = UIViewController()
        privacyWindow?.rootViewController?.view.backgroundColor = color
        // Set the privacy window level to be above alert windows (highest in importance).
        privacyWindow?.windowLevel = .alert + 1
        privacyWindow?.makeKeyAndVisible()
    }

    func removeWindow() {
        privacyWindow?.isHidden = true
        privacyWindow = nil
    }
}
