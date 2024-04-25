// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

protocol ThemeManagerProvider {
    func getCurrentThemeManagerState(windowUUID: WindowUUID) -> ThemeSettingsState
    func toggleUseSystemAppearance(_ enabled: Bool)
    func toggleAutomaticBrightness(_ enabled: Bool)
    func updateManualTheme(_ theme: ThemeType, for window: WindowUUID)
    func updateUserBrightness(_ value: Float)
}

class ThemeManagerMiddleware: ThemeManagerProvider {
    var themeManager: ThemeManager

    init(themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.themeManager = themeManager
    }

    lazy var themeManagerProvider: Middleware<AppState> = { state, action in
        guard let action = action as? ThemeSettingsViewAction else { return }
        let windowUUID = action.windowUUID
        switch action.actionType {
        case ThemeSettingsViewActionType.themeSettingsDidAppear:
            let currentThemeState = self.getCurrentThemeManagerState(windowUUID: windowUUID)
            let newAction = ThemeSettingsMiddlewareAction(
                themeSettingsState: currentThemeState,
                windowUUID: windowUUID,
                actionType: ThemeSettingsMiddlewareActionType.receivedThemeManagerValues)
            store.dispatch(newAction)

        case ThemeSettingsViewActionType.toggleUseSystemAppearance:
            guard let useSystemAppearance = action.useSystemAppearance else { return }
            self.toggleUseSystemAppearance(useSystemAppearance)
            let currentThemeState = self.getCurrentThemeManagerState(windowUUID: action.windowUUID)
            let action = ThemeSettingsMiddlewareAction(
                themeSettingsState: currentThemeState,
                windowUUID: windowUUID,
                actionType: ThemeSettingsMiddlewareActionType.systemThemeChanged)
            store.dispatch(action)

        case ThemeSettingsViewActionType.enableAutomaticBrightness:
            guard let automaticBrightnessEnabled = action.automaticBrightnessEnabled else { return }
            self.toggleAutomaticBrightness(automaticBrightnessEnabled)
            let currentThemeState = self.getCurrentThemeManagerState(windowUUID: windowUUID)
            let action = ThemeSettingsMiddlewareAction(
                themeSettingsState: currentThemeState,
                windowUUID: windowUUID,
                actionType: ThemeSettingsMiddlewareActionType.automaticBrightnessChanged)
            store.dispatch(action)

        case ThemeSettingsViewActionType.switchManualTheme:
            guard let manualThemeType = action.manualThemeType else { return }
            self.updateManualTheme(manualThemeType, for: windowUUID)
            let currentThemeState = self.getCurrentThemeManagerState(windowUUID: windowUUID)
            let action = ThemeSettingsMiddlewareAction(
                themeSettingsState: currentThemeState,
                windowUUID: windowUUID,
                actionType: ThemeSettingsMiddlewareActionType.manualThemeChanged)
            store.dispatch(action)

        case ThemeSettingsViewActionType.updateUserBrightness:
            guard let userBrightness = action.userBrightness else { return }
            self.updateUserBrightness(userBrightness)
            let currentThemeState = self.getCurrentThemeManagerState(windowUUID: windowUUID)
            let action = ThemeSettingsMiddlewareAction(
                themeSettingsState: currentThemeState,
                windowUUID: windowUUID,
                actionType: ThemeSettingsMiddlewareActionType.userBrightnessChanged)
            store.dispatch(action)

        case ThemeSettingsViewActionType.receivedSystemBrightnessChange:
            self.updateThemeBasedOnSystemBrightness()
            let currentThemeState = self.getCurrentThemeManagerState(windowUUID: windowUUID)
            let action = ThemeSettingsMiddlewareAction(
                themeSettingsState: currentThemeState,
                windowUUID: windowUUID,
                actionType: ThemeSettingsMiddlewareActionType.systemBrightnessChanged)
            store.dispatch(action)

            // TODO: Will never get hit
//        case PrivateModeMiddlewareAction.privateModeUpdated(let context):
//            let newState = context.boolValue
//            self.toggleUsePrivateTheme(to: newState, for: windowUUID)
        default:
            break
        }
    }

    // MARK: - Helper func
    func getCurrentThemeManagerState(windowUUID: WindowUUID) -> ThemeSettingsState {
        ThemeSettingsState(windowUUID: windowUUID,
                           useSystemAppearance: themeManager.systemThemeIsOn,
                           isAutomaticBrightnessEnable: themeManager.automaticBrightnessIsOn,
                           manualThemeSelected: themeManager.getNormalSavedTheme(),
                           userBrightnessThreshold: themeManager.automaticBrightnessValue,
                           systemBrightness: getScreenBrightness())
    }

    func toggleUseSystemAppearance(_ enabled: Bool) {
        themeManager.setSystemTheme(isOn: enabled)
    }

    func toggleUsePrivateTheme(to state: Bool, for window: WindowUUID) {
        themeManager.setPrivateTheme(isOn: state, for: window)
    }

    func toggleAutomaticBrightness(_ enabled: Bool) {
        themeManager.setAutomaticBrightness(isOn: enabled)
    }

    func updateManualTheme(_ newTheme: ThemeType, for window: UUID) {
        themeManager.setSystemTheme(isOn: false)
        themeManager.changeCurrentTheme(newTheme, for: window)
    }

    func updateUserBrightness(_ value: Float) {
        themeManager.setAutomaticBrightnessValue(value)
    }

    func updateThemeBasedOnSystemBrightness() {
        themeManager.brightnessChanged()
    }

    func getScreenBrightness() -> Float {
        return Float(UIScreen.main.brightness)
    }
}
