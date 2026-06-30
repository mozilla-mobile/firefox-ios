// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct WebCompatReporterViewAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let url: String?
    let category: WebCompatIssueCategory?
    let subOptionID: String?
    let additionalDetails: String?
    let includeScreenshot: Bool?
    let includeBlockedList: Bool?

    init(url: String? = nil,
         category: WebCompatIssueCategory? = nil,
         subOptionID: String? = nil,
         additionalDetails: String? = nil,
         includeScreenshot: Bool? = nil,
         includeBlockedList: Bool? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.url = url
        self.category = category
        self.subOptionID = subOptionID
        self.additionalDetails = additionalDetails
        self.includeScreenshot = includeScreenshot
        self.includeBlockedList = includeBlockedList
        self.windowUUID = windowUUID
        self.actionType = actionType
    }
}

struct WebCompatReporterMiddlewareAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let url: String?

    init(url: String? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.url = url
        self.windowUUID = windowUUID
        self.actionType = actionType
    }
}

enum WebCompatReporterViewActionType: ActionType {
    case viewDidLoad
    case editURL
    case selectCategory
    case selectSubOption
    case setAdditionalDetails
    case toggleScreenshot
    case toggleBlockedList
    case preview
    case submit
    case cancel
}

enum WebCompatReporterMiddlewareActionType: ActionType {
    case didLoadInitialDraft
}
