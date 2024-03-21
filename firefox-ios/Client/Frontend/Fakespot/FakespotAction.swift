// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

class FakespotUIContext: ActionContext {
    let isExpanded: Bool
    init(isExpanded: Bool, windowUUID: WindowUUID) {
        self.isExpanded = isExpanded
        super.init(windowUUID: windowUUID)
    }
}

class FakespotTabContext: ActionContext {
    let tabUUID: TabUUID?
    init(tabUUID: TabUUID?, windowUUID: WindowUUID) {
        self.tabUUID = tabUUID
        super.init(windowUUID: windowUUID)
    }
}

class FakespotProductContext: FakespotTabContext {
    let productId: String
    init(productId: String, tabUUID: TabUUID?, windowUUID: WindowUUID) {
        self.productId = productId
        super.init(tabUUID: tabUUID, windowUUID: windowUUID)
    }
}

enum FakespotAction: Action {
    case settingsStateDidChange(FakespotUIContext)
    case reviewQualityDidChange(FakespotUIContext)
    case highlightsDidChange(FakespotUIContext)
    case tabDidChange(FakespotTabContext)
    case tabDidReload(FakespotProductContext)
    case pressedShoppingButton(ActionContext)
    case show(ActionContext)
    case dismiss(ActionContext)
    case setAppearanceTo(BoolValueContext)
    case adsImpressionEventSendFor(FakespotProductContext)
    case adsExposureEventSendFor(FakespotProductContext)
    case surfaceDisplayedEventSend(ActionContext)

    var windowUUID: UUID {
        switch self {
        case .settingsStateDidChange(let context as ActionContext),
                .reviewQualityDidChange(let context as ActionContext),
                .highlightsDidChange(let context as ActionContext),
                .tabDidChange(let context as ActionContext),
                .tabDidReload(let context as ActionContext),
                .pressedShoppingButton(let context),
                .show(let context),
                .dismiss(let context),
                .setAppearanceTo(let context as ActionContext),
                .adsImpressionEventSendFor(let context as ActionContext),
                .adsExposureEventSendFor(let context as ActionContext),
                .surfaceDisplayedEventSend(let context):
            return context.windowUUID
        }
    }
}
