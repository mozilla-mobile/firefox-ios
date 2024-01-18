// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A unique identifier for a particular window in Firefox iOS.
/// On iPad this UUID corresponds to an individual window which
/// manages its own unique set of tabs. Multiple Firefox windows
/// can be run side-by-side on iPad (once multi-window is enabled). [FXIOS-7349]
public typealias WindowUUID = UUID

extension WindowUUID {
    // Ideally we would not need this, however we want to enforce a non-optional WindowUUID in
    // the vast majority of the codebase. Conversely, in a few exceptional places or in unexpected
    // circumstances we may not be able to provide a WindowUUID or it may not make sense to provide
    // one. In order to avoid bugs caused by having code that simply passes in `WindowUUID()`,
    // which will constantly generate new and randomized UUIDs, this hardcoded UUID is provided as
    // a sentinel value to identify those areas where a proper UUID isn't available.
    static let unavailable = 
    {
        return WindowUUID(uuidString: "E63C9325-6B47-49E5-9D58-CD68A019860B")!
    }()
}
