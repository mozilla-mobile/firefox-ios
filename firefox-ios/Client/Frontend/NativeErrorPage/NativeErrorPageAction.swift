// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Common

final class NativeErrorPageAction: Action {
    let networkError: NSError?
    let nativePageErrorModel: ErrorPageModel?

    init(
        networkError: NSError? = nil,
        nativePageErrorModel: ErrorPageModel? = nil,
        windowUUID: WindowUUID,
        actionType: any ActionType
    ) {
        self.networkError = networkError
        self.nativePageErrorModel = nativePageErrorModel
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum NativeErrorPageActionType: ActionType {
    case receivedError
}

enum NativeErrorPageMiddlewareActionType: ActionType {
    case initialize
}
