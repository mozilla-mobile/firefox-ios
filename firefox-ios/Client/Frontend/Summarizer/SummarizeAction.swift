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
    let summarizerConfig: SummarizerConfig

    init(
        windowUUID: WindowUUID,
        actionType: any ActionType,
        summarizerConfig: SummarizerConfig
    ) {
        self.windowUUID = windowUUID
        self.actionType = actionType
        self.summarizerConfig = summarizerConfig
    }
}

enum SummarizeMiddlewareActionType: ActionType {
    case configuredSummarizer
}
