// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

class ThemeTypeContext: ActionContext {
    let themeType: ThemeType
    init(themeType: ThemeType, windowUUID: WindowUUID   ) {
        self.themeType = themeType
        super.init(windowUUID: windowUUID)
    }
}

class ThemeSettingsStateContext: ActionContext {
    let state: ThemeSettingsState
    init(state: ThemeSettingsState, windowUUID: WindowUUID) {
        self.state = state
        super.init(windowUUID: windowUUID)
    }
}

enum ThemeSettingsAction: Action {
    // UI trigger actions
    case themeSettingsDidAppear(ActionContext)
    case toggleUseSystemAppearance(BoolValueContext)
    case enableAutomaticBrightness(BoolValueContext)
    case switchManualTheme(ThemeTypeContext)
    case updateUserBrightness(FloatValueContext)
    case receivedSystemBrightnessChange(ActionContext)

    // Middleware trigger actions
    case receivedThemeManagerValues(ThemeSettingsStateContext)
    case systemThemeChanged(BoolValueContext)
    case automaticBrightnessChanged(BoolValueContext)
    case manualThemeChanged(ThemeTypeContext)
    case userBrightnessChanged(FloatValueContext)
    case systemBrightnessChanged(FloatValueContext)

    var windowUUID: UUID {
        switch self {
        case .themeSettingsDidAppear(let context),
                .toggleUseSystemAppearance(let context as ActionContext),
                .enableAutomaticBrightness(let context as ActionContext),
                .switchManualTheme(let context as ActionContext),
                .updateUserBrightness(let context as ActionContext),
                .receivedSystemBrightnessChange(let context),
                .receivedThemeManagerValues(let context as ActionContext),
                .systemThemeChanged(let context as ActionContext),
                .automaticBrightnessChanged(let context as ActionContext),
                .manualThemeChanged(let context as ActionContext),
                .userBrightnessChanged(let context as ActionContext),
                .systemBrightnessChanged(let context as ActionContext):
            return context.windowUUID
        }
    }
}
