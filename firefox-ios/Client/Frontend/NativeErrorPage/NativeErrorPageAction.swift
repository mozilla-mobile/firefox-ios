// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Common

final class NativeErrorPageAction: Action {
    let nativeErrorPageModel: ErrorPageModel?
    init(nativeErrorPageModel: ErrorPageModel, windowUUID: WindowUUID, actionType: any ActionType) {
        self.nativeErrorPageModel = nativeErrorPageModel
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum NativeErrorPageActionType: ActionType {
    case reload
//    case goBack
//    case tapAdvanced
//    case proceedToURL
//    case learMore
//    case viewCertificate
}
