// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared

extension UIView: ThemeUUIDIdentifiable {
    /// If the view is installed in a view hierarchy that is part of a window,
    /// returns the window UUID. If not, returns nil.
    public var currentWindowUUID: WindowUUID? {
        return (self.window as? BrowserWindow)?.uuid
    }
}
