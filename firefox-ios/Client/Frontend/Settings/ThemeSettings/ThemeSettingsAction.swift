// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

class ThemeSettingsViewAction: Action {
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
        self.useSystemAppearance = useSystemAppearance
        self.automaticBrightnessEnabled = automaticBrightnessEnabled
        self.manualThemeType = manualThemeType
        self.userBrightness = userBrightness
        self.systemBrightness = systemBrightness
        super.init(windowUUID: windowUUID,
                   actionType: actionType)
    }
}

class ThemeSettingsMiddlewareAction: Action {
    let themeSettingsState: ThemeSettingsState?

    init(themeSettingsState: ThemeSettingsState? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.themeSettingsState = themeSettingsState
        super.init(windowUUID: windowUUID, actionType: actionType)
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
