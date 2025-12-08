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
    let merinoStories: [MerinoStoryConfiguration]?
    let isEnabled: Bool?
    let telemetryConfig: OpenPocketTelemetryConfig?

    init(
        merinoStories: [MerinoStoryConfiguration]? = nil,
        isEnabled: Bool? = nil,
        telemetryConfig: OpenPocketTelemetryConfig? = nil,
        windowUUID: WindowUUID,
        actionType: any ActionType
    ) {
        self.windowUUID = windowUUID
        self.actionType = actionType
        self.merinoStories = merinoStories
        self.isEnabled = isEnabled
        self.telemetryConfig = telemetryConfig
    }
}

enum MerinoActionType: ActionType {
    case toggleShowSectionSetting
    case tapOnHomepageMerinoCell
    case viewedSection
}

enum MerinoMiddlewareActionType: ActionType {
    case retrievedUpdatedHomepageStories
    case retrievedUpdatedStoriesFeedStories
}
