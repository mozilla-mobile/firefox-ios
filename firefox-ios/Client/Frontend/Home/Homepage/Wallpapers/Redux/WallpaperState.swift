// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Redux
import Common
import ModifiedCopy

@Copyable
struct WallpaperState: ScreenState, Equatable {
    var windowUUID: WindowUUID
    let wallpaperConfiguration: WallpaperConfiguration

    /// `availableContentHeight` represents the height available for the homepage content to occupy when the address is not
    /// being edited. This is used to keep the homepage layout constant, such that it doesn't shift when the homepage's
    /// view size changes eg when the address bar is tapped and the keyboard is presented. This value is kept in state
    /// because it is determined by BVC
    let availableContentHeight: CGFloat

    /// `availableWallpaperHeight` is the height to apply to the homepage wallpaper background so it can remain pinned to
    /// the top of the window while still extending to the same visual bottom as the homepage content.
    let availableWallpaperHeight: CGFloat

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            wallpaperConfiguration: WallpaperConfiguration(),
            availableContentHeight: 0,
            availableWallpaperHeight: 0
        )
    }

    private init(
        windowUUID: WindowUUID,
        wallpaperConfiguration: WallpaperConfiguration,
        availableContentHeight: CGFloat,
        availableWallpaperHeight: CGFloat
    ) {
        self.windowUUID = windowUUID
        self.wallpaperConfiguration = wallpaperConfiguration
        self.availableContentHeight = availableContentHeight
        self.availableWallpaperHeight = availableWallpaperHeight
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case WallpaperMiddlewareActionType.wallpaperDidInitialize,
                WallpaperMiddlewareActionType.wallpaperDidChange:
            return handleWallpaperAction(action: action, state: state)
        case HomepageActionType.availableContentHeightDidChange:
            return handleAvailableContentHeightChangeAction(action: action, state: state)
        default:
            return defaultState(from: state)
        }
    }

    private static func handleWallpaperAction(action: Action, state: WallpaperState) -> WallpaperState {
        guard let wallpaperAction = action as? WallpaperAction else { return defaultState(from: state) }
        return state.copy(
            wallpaperConfiguration: wallpaperAction.wallpaperConfiguration
        )
    }

    private static func handleAvailableContentHeightChangeAction(action: Action,
                                                                 state: WallpaperState) -> WallpaperState {
        guard let homepageAction = action as? HomepageAction else { return defaultState(from: state) }

        // Height updates can arrive with only one field populated; keep the other value stable.
        let availableContentHeight = homepageAction.availableContentHeight ?? state.availableContentHeight
        let availableWallpaperHeight = homepageAction.availableWallpaperHeight ?? state.availableWallpaperHeight

        return state
            .copy(availableContentHeight: availableContentHeight)
            .copy(availableWallpaperHeight: availableWallpaperHeight)
    }

   static func defaultState(from state: WallpaperState) -> WallpaperState {
        return WallpaperState(
            windowUUID: state.windowUUID,
            wallpaperConfiguration: state.wallpaperConfiguration,
            availableContentHeight: state.availableContentHeight,
            availableWallpaperHeight: state.availableWallpaperHeight
        )
   }
}

struct WallpaperConfiguration: Equatable {
    var id: String?
    var landscapeImage: UIImage?
    var portraitImage: UIImage?
    var textColor: UIColor?
    var cardColor: UIColor?
    var logoTextColor: UIColor?
    var hasImage: Bool

    init(
        id: String? = nil,
        landscapeImage: UIImage? = nil,
        portraitImage: UIImage? = nil,
        textColor: UIColor? = nil,
        cardColor: UIColor? = nil,
        logoTextColor: UIColor? = nil,
        hasImage: Bool = false
    ) {
        self.id = id
        self.landscapeImage = landscapeImage
        self.portraitImage = portraitImage
        self.textColor = textColor
        self.cardColor = cardColor
        self.logoTextColor = logoTextColor
        self.hasImage = hasImage
    }

    init(wallpaper: Wallpaper) {
        self.init(
            id: wallpaper.id,
            landscapeImage: wallpaper.landscape,
            portraitImage: wallpaper.portrait,
            textColor: wallpaper.textColor,
            cardColor: wallpaper.cardColor,
            logoTextColor: wallpaper.logoTextColor,
            hasImage: wallpaper.hasImage
        )
    }
 }
