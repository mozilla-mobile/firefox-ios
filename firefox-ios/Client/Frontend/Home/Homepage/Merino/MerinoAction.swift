// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux

struct OpenPocketTelemetryConfig {
    let isZeroSearch: Bool
    let position: Int
}

struct MerinoAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let merinoResponse: MerinoStoryResponse?
    let isEnabled: Bool?
    let telemetryConfig: OpenPocketTelemetryConfig?
    let selectedCategoryID: String?

    init(
        merinoStoryResponse: MerinoStoryResponse? = nil,
        isEnabled: Bool? = nil,
        telemetryConfig: OpenPocketTelemetryConfig? = nil,
        selectedCategoryID: String? = nil,
        windowUUID: WindowUUID,
        actionType: any ActionType
    ) {
        self.windowUUID = windowUUID
        self.actionType = actionType
        self.merinoResponse = merinoStoryResponse
        self.isEnabled = isEnabled
        self.telemetryConfig = telemetryConfig
        self.selectedCategoryID = selectedCategoryID
    }
}

enum MerinoActionType: ActionType {
    case toggleShowSectionSetting
    case tapOnHomepageMerinoCell
    case viewedSection
    case categorySelected
}

enum MerinoMiddlewareActionType: ActionType {
    case retrievedUpdatedHomepageStories
}
