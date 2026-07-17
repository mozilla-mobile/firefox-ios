// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

protocol ThemeManagerProvider {
    @MainActor
    func updatePrivateMode(with action: PrivateModeAction)
}

@MainActor
final class ThemeManagerMiddleware: ThemeManagerProvider {
    var themeManager: ThemeManager

    init(themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.themeManager = themeManager
    }

    lazy var themeManagerProvider: Middleware<AppState> = (legacyProvider, modernProvider)

    lazy var modernProvider: MiddlewareClosure<AppState> = { [self] state, action, windowUUID in
        // Does not test any modern actions
    }

    lazy var legacyProvider: LegacyMiddlewareClosure<AppState> = { [self] state, action in
        if let action = action as? PrivateModeAction {
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
        case MainMenuActionType.tapToggleNightMode:
            updateNightMode()
        default:
            break
        }
    }

    func updatePrivateMode(with action: PrivateModeAction) {
        guard let privateModeState = action.isPrivate else { return }
        themeManager.setPrivateTheme(isOn: privateModeState, for: action.windowUUID)
    }

    func updateNightMode() {
        NightModeHelper.toggle()
    }
}
