// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared

extension UIView: Common.ThemeUUIDIdentifiable {
    /// Convenience that allows most UIViews to automatically reference their parent window UUID.
    /// If the view is installed in a view hierarchy that is part of a window, or is a type
    /// that has its UUID injected, this returns the window UUID. If not, returns nil.
    public var currentWindowUUID: WindowUUID? {
        // If the view has opted in to InjectedThemeUUIDIdentifiable, we prefer that UUID
        // since it is injected and should always be correct even if the view isn't installed
        // in a window or view hierarchy.
        if let injectedUUID = (self as? InjectedThemeUUIDIdentifiable)?.windowUUID {
            return injectedUUID
        }

        // Edge-case: if the view is a UITableView, allow delegates to opt-in to InjectedThemeUUIDIdentifiable.
        if let tableView = self as? UITableView,
           let uuidProvider = tableView.delegate as? InjectedThemeUUIDIdentifiable {
            return uuidProvider.windowUUID
        }

        // Finally, for most views, we can simply return the associated UUID of the window the
        // view is installed in. This covers 99% of use cases, however care needs to be used with
        // UI that is not always inserted into a view hierarchy. In those situations, the view
        // can opt-in to `InjectedThemeUUIDIdentifiable`.
        return (self.window as? BrowserWindow)?.uuid
    }
}
