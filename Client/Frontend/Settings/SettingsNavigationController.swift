/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class SettingsNavigationController: UINavigationController {
    var popoverDelegate: PresentingModalViewControllerDelegate?

    func SELdone() {
        if let delegate = popoverDelegate {
            delegate.dismissPresentedModalViewController(self, animated: true)
        } else {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
}

protocol PresentingModalViewControllerDelegate {
    func dismissPresentedModalViewController(modalViewController: UIViewController, animated: Bool)
}
