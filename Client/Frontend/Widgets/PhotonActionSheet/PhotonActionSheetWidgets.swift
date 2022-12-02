// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Storage
import SnapKit
import Shared
import UIKit
import MapKit

// Misc table components used for the PhotonActionSheet table view.

extension UIModalPresentationStyle {
    func getPhotonPresentationStyle() -> PresentationStyle {
        switch self {
        case .popover:
            return .popover
        case .overFullScreen:
            return .centered
        default:
            return .bottom
        }
    }
}
