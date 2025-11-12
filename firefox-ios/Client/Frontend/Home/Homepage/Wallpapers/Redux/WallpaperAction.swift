// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common

struct WallpaperAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let wallpaperConfiguration: WallpaperConfiguration

    init(wallpaperConfiguration: WallpaperConfiguration,
         windowUUID: WindowUUID,
         actionType: any ActionType
    ) {
        self.windowUUID = windowUUID
        self.actionType = actionType
        self.wallpaperConfiguration = wallpaperConfiguration
    }
}

enum WallpaperActionType: ActionType {
    case wallpaperSelected
}

enum WallpaperMiddlewareActionType: ActionType {
    case wallpaperDidInitialize
    case wallpaperDidChange
}
