// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

protocol ThemeManagerProvider {
    func getCurrentThemeManagerState(windowUUID: WindowUUID) -> ThemeSettingsState
    func updateManualTheme(with action: ThemeSettingsViewAction)
    func updateSystemTheme(with action: ThemeSettingsViewAction)
    func updateAutomaticBrightness(with action: ThemeSettingsViewAction)
    func updateAutomaticBrightnessValue(with action: ThemeSettingsViewAction)
    func updateThemeFromSystemBrightnessChange(with action: ThemeSettingsViewAction)
    func updatePrivateMode(with action: PrivateModeAction)
}

class ThemeManagerMiddleware: ThemeManagerProvider {
    var themeManager: ThemeManager

    init(themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.themeManager = themeManager
    }

    lazy var themeManagerProvider: Middleware<AppState> = { _, action in
        if let action = action as? ThemeSettingsViewAction {
            self.resolveThemeSettingsViewActionType(action: action)
        } else if let action = action as? PrivateModeAction {
            self.resolvePrivateModeAction(action: action)
        } else if let action = action as? MainMenuAction {
            self.resolveMainMenuAction(action: action)
        }
    }

    private func resolvePrivateModeAction(action: PrivateModeAction) {
        switch action.actionType {
        case PrivateModeActionType.privateModeUpdated:
            updatePrivateMode(with: action)

        default:
            break
        }
    }

    private func resolveMainMenuAction(action: MainMenuAction) {
        switch action.actionType {
        case MainMenuDetailsActionType.tapToggleNightMode:
            updateNightMode()
        default:
            break
        }
    }

    private func resolveThemeSettingsViewActionType(action: ThemeSettingsViewAction) {
        switch action.actionType {
        case ThemeSettingsViewActionType.themeSettingsDidAppear:
            dispatchMiddlewareAction(from: action, to: .receivedThemeManagerValues)

        case ThemeSettingsViewActionType.toggleUseSystemAppearance:
            updateSystemTheme(with: action)

        case ThemeSettingsViewActionType.enableAutomaticBrightness:
            updateAutomaticBrightness(with: action)

        case ThemeSettingsViewActionType.switchManualTheme:
            updateManualTheme(with: action)

        case ThemeSettingsViewActionType.updateUserBrightness:
            updateAutomaticBrightnessValue(with: action)

        case ThemeSettingsViewActionType.receivedSystemBrightnessChange:
            updateThemeFromSystemBrightnessChange(with: action)

        default:
            break
        }
    }

    // MARK: - Helper func
    func getCurrentThemeManagerState(windowUUID: WindowUUID) -> ThemeSettingsState {
        ThemeSettingsState(windowUUID: windowUUID,
                           useSystemAppearance: themeManager.systemThemeIsOn,
                           isAutomaticBrightnessEnable: themeManager.automaticBrightnessIsOn,
                           manualThemeSelected: themeManager.getUserManualTheme(),
                           userBrightnessThreshold: themeManager.automaticBrightnessValue,
                           systemBrightness: getScreenBrightness())
    }

    func getScreenBrightness() -> Float {
        return Float(UIScreen.main.brightness)
    }

    func updatePrivateMode(with action: PrivateModeAction) {
        guard let privateModeState = action.isPrivate else { return }
        themeManager.setPrivateTheme(isOn: privateModeState, for: action.windowUUID)
    }

    func updateSystemTheme(with action: ThemeSettingsViewAction) {
        guard let useSystemAppearance = action.useSystemAppearance else { return }
        themeManager.setSystemTheme(isOn: useSystemAppearance)
        dispatchMiddlewareAction(from: action, to: .systemThemeChanged)
    }

    func updateAutomaticBrightness(with action: ThemeSettingsViewAction) {
        guard let automaticBrightnessEnabled = action.automaticBrightnessEnabled else { return }
        themeManager.setAutomaticBrightness(isOn: automaticBrightnessEnabled)
        dispatchMiddlewareAction(from: action, to: .automaticBrightnessChanged)
    }

    func updateAutomaticBrightnessValue(with action: ThemeSettingsViewAction) {
        guard let userBrightness = action.userBrightness else { return }
        themeManager.setAutomaticBrightnessValue(userBrightness)
        dispatchMiddlewareAction(from: action, to: .userBrightnessChanged)
    }

    func updateThemeFromSystemBrightnessChange(with action: ThemeSettingsViewAction) {
        themeManager.applyThemeUpdatesToWindows()
        dispatchMiddlewareAction(from: action, to: .systemBrightnessChanged)
    }

    func updateManualTheme(with action: ThemeSettingsViewAction) {
        guard let manualThemeType = action.manualThemeType else { return }
        themeManager.setManualTheme(to: manualThemeType)
        dispatchMiddlewareAction(from: action, to: .manualThemeChanged)
    }

    func updateNightMode() {
        NightModeHelper.toggle()
        themeManager.applyThemeUpdatesToWindows()
    }

    private func dispatchMiddlewareAction(
        from oldAction: ThemeSettingsViewAction,
        to newActionType: ThemeSettingsMiddlewareActionType
    ) {
        let currentThemeState = getCurrentThemeManagerState(windowUUID: oldAction.windowUUID)
        let action = ThemeSettingsMiddlewareAction(
            themeSettingsState: currentThemeState,
            windowUUID: oldAction.windowUUID,
            actionType: newActionType)

        store.dispatch(action)
    }
}
