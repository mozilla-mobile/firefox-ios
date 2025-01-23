// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common

final class WallpaperAction: Action {
    let wallpaperConfiguration: WallpaperConfiguration

    init(wallpaperConfiguration: WallpaperConfiguration,
         windowUUID: WindowUUID,
         actionType: any ActionType
    ) {
        self.wallpaperConfiguration = wallpaperConfiguration
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum WallpaperActionType: ActionType {
    case wallpaperSelected
}

enum WallpaperMiddlewareActionType: ActionType {
    case wallpaperDidInitialize
    case wallpaperDidChange
}
