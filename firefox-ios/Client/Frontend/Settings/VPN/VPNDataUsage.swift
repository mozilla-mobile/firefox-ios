// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// TODO: FXIOS-16876 Replace the sample values with real usage data once the VPN backend provides it
struct VPNDataUsage: Equatable {
    static let placeholder = VPNDataUsage(usedDataInGB: 2.3, dataLimitInGB: 5)

    let usedDataInGB: Double
    let dataLimitInGB: Double

    var clampedUsedDataInGB: Double {
        min(usedDataInGB, dataLimitInGB)
    }

    var usageFraction: Double {
        guard dataLimitInGB > 0 else { return 0 }
        return min(usedDataInGB / dataLimitInGB, 1)
    }

    var isLimitReached: Bool {
        usageFraction >= 1
    }
}
