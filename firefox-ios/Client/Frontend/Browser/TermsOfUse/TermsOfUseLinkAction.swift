// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct TermsOfUseLinkAction: Action {
    var windowUUID: WindowUUID
    var actionType: ActionType

    init(windowUUID: WindowUUID, actionType: TermsOfUseLinkActionType) {
        self.windowUUID = windowUUID
        self.actionType = actionType
    }
}

enum TermsOfUseLinkActionType: ActionType {
    case linkLoading
    case linkDismissed
}
