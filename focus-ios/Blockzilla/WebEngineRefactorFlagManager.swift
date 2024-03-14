// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct WebEngineFlagManager {
    /// Whether the refactor for using the new WebEngine as the active browser engine for the client
    /// is enabled. If `true` the WebEngine will be used rather than the legacy browser code.
    ///
    /// TODO [FXIOS-8655]: currently this is hardcoded; eventually this will be updated to a Nimbus feature flag.
    static let isWebEngineEnabled = false
}
