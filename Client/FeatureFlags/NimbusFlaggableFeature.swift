/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared

protocol FFlaggableFeature {
    var featureID: FeatureFlagID { get }
    var isActive: Bool { get }
    func toggle()
}

//struct NimbusFlaggableFeature: FFlaggableFeature {
//
//}
