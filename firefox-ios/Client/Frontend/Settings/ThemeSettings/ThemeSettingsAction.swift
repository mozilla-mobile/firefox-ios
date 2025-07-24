// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct ThemeSettingsViewAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let useSystemAppearance: Bool?
    let automaticBrightnessEnabled: Bool?
    let manualThemeType: ThemeType?
    let userBrightness: Float?
    let systemBrightness: Float?

    init(useSystemAppearance: Bool? = nil,
         automaticBrightnessEnabled: Bool? = nil,
         manualThemeType: ThemeType? = nil,
         userBrightness: Float? = nil,
         systemBrightness: Float? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.windowUUID = windowUUID
        self.actionType = actionType
        self.useSystemAppearance = useSystemAppearance
        self.automaticBrightnessEnabled = automaticBrightnessEnabled
        self.manualThemeType = manualThemeType
        self.userBrightness = userBrightness
        self.systemBrightness = systemBrightness
    }
}

struct ThemeSettingsMiddlewareAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let themeSettingsState: ThemeSettingsState?

    init(themeSettingsState: ThemeSettingsState? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.windowUUID = windowUUID
        self.actionType = actionType
        self.themeSettingsState = themeSettingsState
    }
}

enum ThemeSettingsViewActionType: ActionType {
    case themeSettingsDidAppear
    case toggleUseSystemAppearance
    case enableAutomaticBrightness
    case switchManualTheme
    case updateUserBrightness
    case receivedSystemBrightnessChange
}

enum ThemeSettingsMiddlewareActionType: ActionType {
    case receivedThemeManagerValues
    case systemThemeChanged
    case automaticBrightnessChanged
    case manualThemeChanged
    case userBrightnessChanged
    case systemBrightnessChanged
}
