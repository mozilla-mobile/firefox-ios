// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Extension to add invisible tab capability to existing Tab class
/// Provides a convenient interface without modifying the core Tab implementation
extension Tab {

    /// Indicates whether this tab is invisible (hidden from user interface)
    /// 
    /// When set to true, the tab will be excluded from:
    /// - Tab count displays
    /// - Tab switcher interfaces
    /// - Inactive tab management
    /// - Other UI representations
    ///
    /// This property is commonly used for authentication tabs and other 
    /// background operations that should not be visible to users.
    var isInvisible: Bool {
        get {
            return InvisibleTabManager.shared.isTabInvisible(self)
        }
        set {
            if newValue {
                InvisibleTabManager.shared.markTabAsInvisible(self)
            } else {
                InvisibleTabManager.shared.markTabAsVisible(self)
            }
        }
    }

    /// Convenience method to mark this tab as invisible
    /// Equivalent to setting `isInvisible = true`
    func markAsInvisible() {
        isInvisible = true
    }

    /// Convenience method to mark this tab as visible
    /// Equivalent to setting `isInvisible = false`
    func markAsVisible() {
        isInvisible = false
    }
}
