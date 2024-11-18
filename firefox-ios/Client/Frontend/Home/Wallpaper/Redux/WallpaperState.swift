// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Redux
import Common

struct WallpaperState: ScreenState, Equatable {
    var windowUUID: WindowUUID
    var wallpaper: Wallpaper

    init(windowUUID: WindowUUID, wallpaper: Wallpaper = Wallpaper.defaultWallpaper) {
        self.windowUUID = windowUUID
        self.wallpaper = wallpaper
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case WallpaperMiddlewareActionType.wallpaperDidInitialize:
            return handleWallpaperAction(action: action, state: state)
        case WallpaperMiddlewareActionType.wallpaperDidChange:
            return handleWallpaperAction(action: action, state: state)
        default:
            return defaultState(from: state)
        }
    }

    private static func handleWallpaperAction(action: Action, state: WallpaperState) -> WallpaperState {
        guard let wallpaperAction = action as? WallpaperAction else { return defaultState(from: state) }
        return WallpaperState(
            windowUUID: state.windowUUID,
            wallpaper: wallpaperAction.wallpaper
        )
    }

   static func defaultState(from state: WallpaperState) -> WallpaperState {
        return WallpaperState(
            windowUUID: state.windowUUID, wallpaper: state.wallpaper
        )
   }
}
