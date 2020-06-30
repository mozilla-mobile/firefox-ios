/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

// Data Model
struct ETPCoverSheetModel {
    var titleImage: UIImage
    var titleText: String
    var descriptionText: String
}

// Data type for the type of sheet which is helpful to know when / how to show the ETP Cover Sheet
enum ETPCoverSheetShowType: String {
    case CleanInstall
    case Upgrade
    case DoNotShow
    case Unknown
}
