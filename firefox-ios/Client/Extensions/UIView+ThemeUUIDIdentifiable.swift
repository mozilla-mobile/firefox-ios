// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared

extension UIView: ThemeUUIDIdentifiable {
    /// Convenience that allows most UIViews to automatically reference their parent window UUID.
    /// If the view is installed in a view hierarchy that is part of a window, or is a type
    /// that has its UUID injected, this returns the window UUID. If not, returns nil.
    public var currentWindowUUID: WindowUUID? {
        if let injectedUUID = (self as? InjectedThemeUUIDIdentifiable)?.windowUUID {
            return injectedUUID
        }
        if let tableView = self as? UITableView,
           let uuidProvider = tableView.delegate as? InjectedThemeUUIDIdentifiable {
            return uuidProvider.windowUUID
        }
        return (self.window as? BrowserWindow)?.uuid
    }
}
