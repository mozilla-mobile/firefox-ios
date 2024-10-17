// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Shared
import Common

final class NativeErrorPageMiddleware {

    lazy var nativeErrorPageProvider: Middleware<AppState> = { state, action in
        let windowUUID = action.windowUUID
//        switch action.actionType {
//        case NativeErrorPageActionType.learMore:
//            //
//        case NativeErrorPageActionType.tapAdvanced:
//            //
//        case NativeErrorPageActionType.viewCertificate:
//            //
//        case NativeErrorPageMiddlewareActionType.getError:
//            //
//        case NativeErrorPageMiddlewareActionType.initialize:
//            //
//        default:
//           break
//        }
    }

    private func initializeNativeErrorPage(windowUUID: WindowUUID, model: ErrorPageModel) {
        let newAction = NativeErrorPageAction(
            nativeErrorPageModel: model,
            windowUUID: windowUUID,
            actionType: NativeErrorPageMiddlewareActionType.initialize
        )
        store.dispatch(newAction)
    }
}
