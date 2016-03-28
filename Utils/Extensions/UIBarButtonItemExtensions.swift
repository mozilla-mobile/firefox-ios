/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

public extension UIBarButtonItem {
    class func flexibleSpaceItem() -> UIBarButtonItem {
        return UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
    }

    class func fixedSpaceItem() -> UIBarButtonItem {
        return UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: nil, action: nil)
    }

    class func customButtonItem(button: UIButton) -> UIBarButtonItem {
        return UIBarButtonItem(customView: button)
    }
}