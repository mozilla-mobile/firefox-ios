// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A unique identifier for a particular window in Firefox iOS.
/// On iPad this UUID corresponds to an individual window which
/// manages its own unique set of tabs. Multiple Firefox windows
/// can be run side-by-side on iPad (once multi-window is enabled). [FXIOS-7349]
public typealias WindowUUID = UUID

/// Describes a UUID available for use in a window on either iPhone or iPad.
public struct ReservedWindowUUID {
    /// The UUID of the window.
    public let uuid: WindowUUID

    /// True if the UUID is for a newly-created window (with no tabs on disk)
    public let isNew: Bool

    public init(uuid: WindowUUID, isNew: Bool) {
        self.uuid = uuid
        self.isNew = isNew
    }
}

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

    /// Default window UUID for single-window unit tests.
    static let XCTestDefaultUUID = WindowUUID(uuidString: "D9D9D9D9-D9D9-D9D9-D9D9-CD68A019860B")!

    /// Default window UUID for UI testing.
    static let DefaultUITestingUUID = WindowUUID(uuidString: "44BA0B7D-097A-484D-8358-91A6E374451D")!
}

public extension WindowUUID {
    /// Key for setting (or obtaining) the windowUUID from notification userInfo payloads
    static let userInfoKey = "windowUUID"

    /// Convenience. Returns a Notification user info payload containing the receiving UUID.
    var userInfo: [AnyHashable: Any] {
        return [WindowUUID.userInfoKey: self]
    }
}

public extension Notification {
    /// Convenience for obtaining the windowUUID for a posted notification
    var windowUUID: WindowUUID? {
        guard let info = userInfo,
        let uuid = info[WindowUUID.userInfoKey] as? WindowUUID
        else { return nil }

        return uuid
    }
}
