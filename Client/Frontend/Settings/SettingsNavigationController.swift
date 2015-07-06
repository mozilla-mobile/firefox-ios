/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import UIKit

class SettingsNavigationController: UINavigationController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var profile: Profile!
    var tabManager: TabManager!

    override func viewDidLoad() {
        super.viewDidLoad()

        let rootViewController = SettingsTableViewController()
        rootViewController.profile = profile
        rootViewController.tabManager = tabManager
        self.pushViewController(rootViewController, animated: false)
    }

    func SELdone() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    // UIImagePickerController really wants a UINavigationController, rather than just something that implements
    // UIImagePickerControllerDelegate and UINavigationControllerDelegate as the docs say. Until that's fixed we handle changing the
    // theme image in here.
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        picker.dismissViewControllerAnimated(true, completion: nil)
        if let img = info[UIImagePickerControllerEditedImage] as? UIImage {
            LightweightThemeManager.setThemeImage(img)
        }
    }

    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
}
