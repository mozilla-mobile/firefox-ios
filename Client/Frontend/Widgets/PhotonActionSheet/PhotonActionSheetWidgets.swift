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

public enum PresentationStyle {
    case centered // used in the home panels
    case bottom // used to display the menu on phone sized devices
    case popover // when displayed on the iPad
}

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

public enum PhotonActionSheetCellAccessoryType {
    case Disclosure
    case Switch
    case Text
    case None
}

public enum PhotonActionSheetIconType {
    case Image
    case URL
    case TabsButton
    case None
}
