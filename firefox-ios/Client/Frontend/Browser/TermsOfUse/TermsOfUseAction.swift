// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Common
import Redux

class TermsOfUseAction: Action {
    init(windowUUID: WindowUUID, actionType: TermsOfUseActionType) {
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum TermsOfUseActionType: ActionType {
    case markAccepted
    case markDismissed
    case markShownThisLaunch
}
