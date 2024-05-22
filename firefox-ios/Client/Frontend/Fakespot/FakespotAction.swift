// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

class FakespotAction: Action {
    let isOpen: Bool?
    let isExpanded: Bool?
    let tabUUID: TabUUID?
    let productId: String?

    init(isOpen: Bool? = nil,
         isExpanded: Bool? = nil,
         tabUUID: TabUUID? = nil,
         productId: String? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.isOpen = isOpen
        self.isExpanded = isExpanded
        self.tabUUID = tabUUID
        self.productId = productId
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum FakespotActionType: ActionType {
    case settingsStateDidChange
    case reviewQualityDidChange
    case highlightsDidChange
    case tabDidChange
    case tabDidReload
    case pressedShoppingButton
    case show
    case dismiss
    case setAppearanceTo
    case adsImpressionEventSendFor
    case adsExposureEventSendFor
    case surfaceDisplayedEventSend
}
