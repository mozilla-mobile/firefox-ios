// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SnapKit

extension UIView {
    /// If the view is installed in a view hierarchy that is part of a window,
    /// returns the window UUID. If not, returns nil.
    var currentWindowUUID: WindowUUID? {
        return (self.window as? BrowserWindow)?.uuid
    }
}
