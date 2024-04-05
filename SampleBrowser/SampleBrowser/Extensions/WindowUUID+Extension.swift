// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A unique identifier for a particular window in Firefox iOS.
/// On iPad this UUID corresponds to an individual window which
/// manages its own unique set of tabs. Multiple Firefox windows
/// can be run side-by-side on iPad (once multi-window is enabled). [FXIOS-7349]
public typealias WindowUUID = UUID

public extension WindowUUID {
    /// Sentinel UUID value for use when a window is unavailable or unknown.
    ///
    /// We want to enforce non-optional WindowUUIDs in the vast majority of codebase APIs.
    /// However, in some exceptional circumstances, or in error handlers, we may not be able
    /// to provide a UUID or it may not make sense. In order to avoid bugs caused by having
    /// code that defaults to `WindowUUID()` (which will constantly generate new and randomized
    /// UUIDs), this hardcoded UUID is provided as a sentinel value to be used when a valid
    /// UUID isn't available for some unexpected reason.
    static let unavailable = WindowUUID(uuidString: "E1E1E1E1-E1E1-E1E1-E1E1-CD68A019860B")!
}
