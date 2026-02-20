// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Common

struct NativeErrorPageAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let networkError: NSError?
    let nativePageErrorModel: ErrorPageModel?

    init(
        networkError: NSError? = nil,
        nativePageErrorModel: ErrorPageModel? = nil,
        windowUUID: WindowUUID,
        actionType: any ActionType
    ) {
        self.windowUUID = windowUUID
        self.actionType = actionType
        self.networkError = networkError
        self.nativePageErrorModel = nativePageErrorModel
    }
}

enum NativeErrorPageActionType: ActionType {
    case receivedError
    case errorPageLoaded
    case bypassCertificateWarning
}

enum NativeErrorPageMiddlewareActionType: ActionType {
    case initialize
}
