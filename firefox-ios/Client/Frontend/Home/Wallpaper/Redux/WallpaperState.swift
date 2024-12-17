// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Redux
import Common

struct WallpaperState: ScreenState, Equatable {
    var windowUUID: WindowUUID
    let wallpaperConfiguration: WallpaperConfiguration

    init(windowUUID: WindowUUID, wallpaperConfiguration: WallpaperConfiguration = WallpaperConfiguration()) {
        self.windowUUID = windowUUID
        self.wallpaperConfiguration = wallpaperConfiguration
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case WallpaperMiddlewareActionType.wallpaperDidInitialize,
                WallpaperMiddlewareActionType.wallpaperDidChange:
            return handleWallpaperAction(action: action, state: state)
        default:
            return defaultState(from: state)
        }
    }

    private static func handleWallpaperAction(action: Action, state: WallpaperState) -> WallpaperState {
        guard let wallpaperAction = action as? WallpaperAction else { return defaultState(from: state) }
        return WallpaperState(
            windowUUID: state.windowUUID,
            wallpaperConfiguration: wallpaperAction.wallpaperConfiguration
        )
    }

   static func defaultState(from state: WallpaperState) -> WallpaperState {
        return WallpaperState(
            windowUUID: state.windowUUID, wallpaperConfiguration: state.wallpaperConfiguration
        )
   }
}

struct WallpaperConfiguration: Equatable {
    var landscapeImage: UIImage?
    var portraitImage: UIImage?
    var textColor: UIColor?
    var cardColor: UIColor?
    var logoTextColor: UIColor?
    var hasImage: Bool

    init(
        landscapeImage: UIImage? = nil,
        portraitImage: UIImage? = nil,
        textColor: UIColor? = nil,
        cardColor: UIColor? = nil,
        logoTextColor: UIColor? = nil,
        hasImage: Bool = false
    ) {
        self.landscapeImage = landscapeImage
        self.portraitImage = portraitImage
        self.textColor = textColor
        self.cardColor = cardColor
        self.logoTextColor = logoTextColor
        self.hasImage = hasImage
    }

    init(wallpaper: Wallpaper) {
        self.init(
            landscapeImage: wallpaper.landscape,
            portraitImage: wallpaper.portrait,
            textColor: wallpaper.textColor,
            cardColor: wallpaper.cardColor,
            logoTextColor: wallpaper.logoTextColor,
            hasImage: wallpaper.hasImage
        )
    }
 }
