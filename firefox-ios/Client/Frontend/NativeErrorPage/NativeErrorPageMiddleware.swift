// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Shared
import Common

final class NativeErrorPageMiddleware {
    private var nativeErrorPageHelper: NativeErrorPageHelper?
    lazy var nativeErrorPageProvider: Middleware<AppState> = { [self] state, action in
        let windowUUID = action.windowUUID
        switch action.actionType {
        case NativeErrorPageActionType.receivedError:
            guard let action = action as? NativeErrorPageAction, let error = action.networkError else {return}
            nativeErrorPageHelper = NativeErrorPageHelper(error: error)
        case NativeErrorPageActionType.errorPageLoaded:
            self.initializeNativeErrorPage(windowUUID: windowUUID)
        default:
            break
        }
    }

    private func initializeNativeErrorPage(windowUUID: WindowUUID) {
        if let helper = nativeErrorPageHelper {
            let model = helper.parseErrorDetails()
            store.dispatch(NativeErrorPageAction(nativePageErrorModel: model,
                                                 windowUUID: windowUUID,
                                                 actionType: NativeErrorPageMiddlewareActionType.initialize)
            )
        }
    }
}
