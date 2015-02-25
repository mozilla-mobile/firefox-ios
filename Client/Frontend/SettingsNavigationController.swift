/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class SettingsNavigationController: UINavigationController {
    var profile: Profile!

    override func viewDidLoad() {
        super.viewDidLoad()

        let settingsTableViewController = SettingsTableViewController()
        self.pushViewController(settingsTableViewController, animated: false)
    }

    func SELdone() {
        NSLog("Done!")
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
