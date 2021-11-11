// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

struct EnhancedTrackingProtectionDetailsVM {
    let topLevelDomain: String
    let title: String
    let image: UIImage
    let URL: String

    let lockIcon: UIImage
    let connectionStatusMessage: String
    let connectionVerifier: String
    let connectionSecure: Bool
}
