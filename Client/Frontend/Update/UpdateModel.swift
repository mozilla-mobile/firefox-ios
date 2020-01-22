/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

protocol UpdateCoverSheet {
    var titleImage: UIImage { get set }
    var titleText: String { get set }
}

struct Update {
    var updateImage: UIImage
    var updateText: String
}

struct UpdateCoverSheetModel: UpdateCoverSheet {
    var titleImage: UIImage
    var titleText: String
    var updates:[Update]
}
