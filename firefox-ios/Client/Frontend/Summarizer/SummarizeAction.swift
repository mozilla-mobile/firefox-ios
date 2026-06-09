// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import WebKit
import SummarizeKit

struct SummarizeAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
}

enum SummarizeMiddlewareActionType: ActionType {
    case showReaderModeBarSummarizerButton
    case summaryNotAvailable
}
