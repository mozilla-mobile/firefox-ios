// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Common

final class TabWebViewPreviewAction: Action {
    let screenshot: UIImage?

    init(screenshot: UIImage? = nil, actionType: ActionType) {
        self.screenshot = screenshot
        super.init(windowUUID: .unavailable, actionType: actionType)
    }
}

enum TabWebViewPreviewActionType: ActionType {
    case didTakeScreenshot
}
