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

final class PocketAction: Action {
    let pocketStories: [PocketStoryConfiguration]?
    let isEnabled: Bool?
    let telemetryConfig: OpenPocketTelemetryConfig?

    init(
        pocketStories: [PocketStoryConfiguration]? = nil,
        isEnabled: Bool? = nil,
        telemetryConfig: OpenPocketTelemetryConfig? = nil,
        windowUUID: WindowUUID,
        actionType: any ActionType
    ) {
        self.pocketStories = pocketStories
        self.isEnabled = isEnabled
        self.telemetryConfig = telemetryConfig
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum PocketActionType: ActionType {
    case toggleShowSectionSetting
    case tapOnHomepagePocketCell
    case viewedSection
}

enum PocketMiddlewareActionType: ActionType {
    case retrievedUpdatedStories
}
