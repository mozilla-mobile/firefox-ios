// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct AISearchMVPExperiment {

    private init() {}

    public static var isEnabled: Bool {
        Unleash.isEnabled(.aiSearchMVP) && !isControl
    }

    private static var variant: Unleash.Variant {
        Unleash.getVariant(.aiSearchMVP)
    }

    // More variants might be introduced, but control should remain the same
    private static let controlVariantName: String = "st_3000_0"
    public static var isControl: Bool {
        variant.name == controlVariantName
    }
}
