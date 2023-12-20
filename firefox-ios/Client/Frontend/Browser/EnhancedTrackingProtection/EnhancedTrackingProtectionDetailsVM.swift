// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

struct EnhancedTrackingProtectionDetailsVM {
    let topLevelDomain: String
    let title: String
    let URL: String

    let getLockIcon: (ThemeType) -> UIImage
    let connectionStatusMessage: String
    let connectionSecure: Bool
}
