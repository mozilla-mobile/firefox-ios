/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

public extension UIApplication {
    var orientation: UIInterfaceOrientation? {
        UIApplication
            .shared
            .windows
            .first(where: { $0.isKeyWindow })?
            .windowScene?
            .interfaceOrientation
    }

    static var textInputMode: UITextInputMode? {
        UIApplication
            .shared
            .delegate?
            .window??
            .textInputMode
    }
}
