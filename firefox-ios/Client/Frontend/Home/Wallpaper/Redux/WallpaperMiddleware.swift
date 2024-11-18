// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

class WallpaperMiddleware {
    private let wallpaperManager: WallpaperManager

    init(wallpaperManager: WallpaperManager = WallpaperManager()) {
        self.wallpaperManager = wallpaperManager
    }

    lazy var wallpaperProvider: Middleware<AppState> = { state, action in
        if let action = action as? HomepageAction {
            self.resolveHomepageAction(action: action, state: state)
        } else if let action = action as? WallpaperAction {
            self.resolveWallpaperAction(action: action, state: state)
        }
    }

    private func resolveHomepageAction(action: HomepageAction, state: AppState) {
        switch action.actionType {
        case HomepageActionType.initialize:
            let action = WallpaperAction(wallpaper: wallpaperManager.currentWallpaper, windowUUID: action.windowUUID, actionType: WallpaperMiddlewareActionType.wallpaperDidInitialize)
            store.dispatch(action)
        default:
            break
        }
    }

    private func resolveWallpaperAction(action: WallpaperAction, state: AppState) {
        switch action.actionType {
        case WallpaperActionType.wallpaperSelected:
            let action = WallpaperAction(wallpaper: wallpaperManager.currentWallpaper, windowUUID: action.windowUUID, actionType: WallpaperMiddlewareActionType.wallpaperDidChange)
            store.dispatch(action)
        default:
            break
        }
    }
}
