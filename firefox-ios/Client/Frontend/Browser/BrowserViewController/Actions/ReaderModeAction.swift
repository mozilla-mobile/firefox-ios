// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Redux

struct ReaderModeAction: Action {
    let windowUUID: WindowUUID
    let actionType: any ActionType
    /// Wether the summarizer button should be shown inside the `ReaderModeBarView`.
    var shouldShowSummarizerButton: Bool = false
}

enum ReaderModeActionType: ActionType {
    case showSummarizerButton
    case didTapSummarizerButton
}
