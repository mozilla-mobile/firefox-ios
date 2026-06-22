// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common

enum ComponentState: Sendable, Equatable {
    case browserViewController(BrowserViewControllerState)
    case homepage(HomepageState)
    case mainMenu(MainMenuState)
    case microsurvey(MicrosurveyState)
    case remoteTabsPanel(RemoteTabsPanelState)
    case tabsPanel(TabsPanelState)
    case tabPeek(TabPeekState)
    case tabsTray(TabTrayState)
    case themeSettings(ThemeSettingsState)
    case termsOfUse(TermsOfUseState)
    case trackingProtection(TrackingProtectionState)
    case toolbar(ToolbarState)
    case searchEngineSelection(SearchEngineSelectionState)
    case passwordGenerator(PasswordGeneratorState)
    case nativeErrorPage(NativeErrorPageState)
    case shortcutsLibrary(ShortcutsLibraryState)
    case translationSettings(TranslationSettingsState)

    // FIXME: IHC
    static let reducer: Reducer<Self> = (legacyReducer, modernReducer)

    // swiftlint:disable:next closure_body_length
    static let modernReducer: ReducerMethod<Self> = { state, action, windowUUID in
        // Does not handle any modern actions, but substates might.
        // FXIOS-16139 Abstain from using the copy macro here, so the compiler tips off developers who add new reducer
        // parameters to forward those calls here until we have passthrough reducer guidelines in place.
        switch state {
        case .browserViewController(let state):
            return .browserViewController(BrowserViewControllerState.reducer.modernReducer(state, action, windowUUID))
        case .homepage(let state):
            return .homepage(HomepageState.reducer.modernReducer(state, action, windowUUID))
        case .mainMenu(let state):
            return .mainMenu(MainMenuState.reducer.modernReducer(state, action, windowUUID))
        case .microsurvey(let state):
            return .microsurvey(MicrosurveyState.reducer.modernReducer(state, action, windowUUID))
        case .remoteTabsPanel(let state):
            return .remoteTabsPanel(RemoteTabsPanelState.reducer.modernReducer(state, action, windowUUID))
        case .tabPeek(let state):
            return .tabPeek(TabPeekState.reducer.modernReducer(state, action, windowUUID))
        case .tabsTray(let state):
            return .tabsTray(TabTrayState.reducer.modernReducer(state, action, windowUUID))
        case .tabsPanel(let state):
            return .tabsPanel(TabsPanelState.reducer.modernReducer(state, action, windowUUID))
        case .termsOfUse(let state):
            return .termsOfUse(TermsOfUseState.reducer.modernReducer(state, action, windowUUID))
        case .themeSettings(let state):
            return .themeSettings(ThemeSettingsState.reducer.modernReducer(state, action, windowUUID))
        case .trackingProtection(let state):
            return .trackingProtection(TrackingProtectionState.reducer.modernReducer(state, action, windowUUID))
        case .toolbar(let state):
            return .toolbar(ToolbarState.reducer.modernReducer(state, action, windowUUID))
        case .searchEngineSelection(let state):
            return .searchEngineSelection(SearchEngineSelectionState.reducer.modernReducer(state, action, windowUUID))
        case .passwordGenerator(let state):
            return .passwordGenerator(PasswordGeneratorState.reducer.modernReducer(state, action, windowUUID))
        case .nativeErrorPage(let state):
            return .nativeErrorPage(NativeErrorPageState.reducer.modernReducer(state, action, windowUUID))
        case .shortcutsLibrary(let state):
            return .shortcutsLibrary(ShortcutsLibraryState.reducer.modernReducer(state, action, windowUUID))
        case .translationSettings(let state):
            return .translationSettings(TranslationSettingsState.reducer.modernReducer(state, action, windowUUID))
        }
    }

    // swiftlint:disable:next closure_body_length
    static let legacyReducer: LegacyReducerMethod<Self> = { state, action in
        switch state {
        case .browserViewController(let state):
            return .browserViewController(BrowserViewControllerState.reducer.legacyReducer(state, action))
        case .homepage(let state):
            return .homepage(HomepageState.reducer.legacyReducer(state, action))
        case .mainMenu(let state):
            return .mainMenu(MainMenuState.reducer.legacyReducer(state, action))
        case .microsurvey(let state):
            return .microsurvey(MicrosurveyState.reducer.legacyReducer(state, action))
        case .remoteTabsPanel(let state):
            return .remoteTabsPanel(RemoteTabsPanelState.reducer.legacyReducer(state, action))
        case .tabPeek(let state):
            return .tabPeek(TabPeekState.reducer.legacyReducer(state, action))
        case .tabsTray(let state):
            return .tabsTray(TabTrayState.reducer.legacyReducer(state, action))
        case .tabsPanel(let state):
            return .tabsPanel(TabsPanelState.reducer.legacyReducer(state, action))
        case .termsOfUse(let state):
            return .termsOfUse(TermsOfUseState.reducer.legacyReducer(state, action))
        case .themeSettings(let state):
            return .themeSettings(ThemeSettingsState.reducer.legacyReducer(state, action))
        case .trackingProtection(let state):
            return .trackingProtection(TrackingProtectionState.reducer.legacyReducer(state, action))
        case .toolbar(let state):
            return .toolbar(ToolbarState.reducer.legacyReducer(state, action))
        case .searchEngineSelection(let state):
            return .searchEngineSelection(SearchEngineSelectionState.reducer.legacyReducer(state, action))
        case .passwordGenerator(let state):
            return .passwordGenerator(PasswordGeneratorState.reducer.legacyReducer(state, action))
        case .nativeErrorPage(let state):
            return .nativeErrorPage(NativeErrorPageState.reducer.legacyReducer(state, action))
        case .shortcutsLibrary(let state):
            return .shortcutsLibrary(ShortcutsLibraryState.reducer.legacyReducer(state, action))
        case .translationSettings(let state):
            return .translationSettings(TranslationSettingsState.reducer.legacyReducer(state, action))
        }
    }

    /// Returns the matching AppComponent enum for a given AppComponentState
    var associatedAppComponent: AppComponent {
        switch self {
        case .browserViewController: return .browserViewController
        case .homepage: return .homepage
        case .mainMenu: return .mainMenu
        case .microsurvey: return .microsurvey
        case .remoteTabsPanel: return .remoteTabsPanel
        case .tabsPanel: return .tabsPanel
        case .tabPeek: return .tabPeek
        case .tabsTray: return .tabsTray
        case .themeSettings: return .themeSettings
        case .termsOfUse: return .termsOfUse
        case .trackingProtection: return .trackingProtection
        case .toolbar: return .toolbar
        case .searchEngineSelection: return .searchEngineSelection
        case .passwordGenerator: return .passwordGenerator
        case .nativeErrorPage: return .nativeErrorPage
        case .shortcutsLibrary: return .shortcutsLibrary
        case .translationSettings: return .translationSettings
        }
    }

    var windowUUID: WindowUUID? {
        switch self {
        case .browserViewController(let state): return state.windowUUID
        case .homepage(let state): return state.windowUUID
        case .mainMenu(let state): return state.windowUUID
        case .microsurvey(let state): return state.windowUUID
        case .remoteTabsPanel(let state): return state.windowUUID
        case .tabsPanel(let state): return state.windowUUID
        case .tabPeek(let state): return state.windowUUID
        case .tabsTray(let state): return state.windowUUID
        case .themeSettings(let state): return state.windowUUID
        case .termsOfUse(let state): return state.windowUUID
        case .trackingProtection(let state): return state.windowUUID
        case .toolbar(let state): return state.windowUUID
        case .searchEngineSelection(let state): return state.windowUUID
        case .passwordGenerator(let state): return state.windowUUID
        case .nativeErrorPage(let state): return state.windowUUID
        case .shortcutsLibrary(let state): return state.windowUUID
        case .translationSettings(let state): return state.windowUUID
        }
    }
}

struct PresentedComponentsState: Sendable, Equatable {
    let components: [ComponentState]

    init() {
        self.components = []
    }

    init(components: [ComponentState]) {
        self.components = components
    }

    static let reducer: Reducer<Self> = (legacyReducer, modernReducer)

    static let modernReducer: ReducerMethod<Self> = { state, action, windowUUID in
        // This reducer does not yet handle any modern actions. Simply pass along to substate reducers.

        // Reduce each component state
        var components = state.components.map { ComponentState.reducer.modernReducer($0, action, windowUUID) }

        return PresentedComponentsState(components: components)
    }

    static let legacyReducer: LegacyReducerMethod<Self> = { state, action in
        // Add or remove components from the active component list as needed (ComponentActionType is a legacy action)
        var components = updateActiveComponents(action: action, components: state.components)

        // Reduce each component state
        components = components.map { ComponentState.reducer.legacyReducer($0, action) }

        return PresentedComponentsState(components: components)
    }

    private static func updateActiveComponents(action: Action, components: [ComponentState]) -> [ComponentState] {
        guard let action = action as? ComponentAction else { return components }

        var components = components

        switch action.actionType {
        case ComponentActionType.removeComponent:
            components = components.filter({
                return $0.associatedAppComponent != action.component || $0.windowUUID != action.windowUUID
            })
        case ComponentActionType.addComponent:
            let uuid = action.windowUUID
            switch action.component {
            case .browserViewController:
                components.append(.browserViewController(BrowserViewControllerState(windowUUID: uuid)))
            case .homepage:
                components.append(.homepage(HomepageState(windowUUID: uuid)))
            case .mainMenu:
                components.append(.mainMenu(MainMenuState(windowUUID: uuid)))
            case .microsurvey:
                components.append(.microsurvey(MicrosurveyState(windowUUID: uuid)))
            case .remoteTabsPanel:
                components.append(.remoteTabsPanel(RemoteTabsPanelState(windowUUID: uuid)))
            case .tabsTray:
                components.append(.tabsTray(TabTrayState(windowUUID: uuid)))
            case .tabsPanel:
                components.append(.tabsPanel(TabsPanelState(windowUUID: uuid)))
            case .tabPeek:
                components.append(.tabPeek(TabPeekState(windowUUID: uuid)))
            case .themeSettings:
                components.append(.themeSettings(ThemeSettingsState(windowUUID: uuid)))
            case .termsOfUse:
                components.append(.termsOfUse(TermsOfUseState(windowUUID: uuid)))
            case .trackingProtection:
                components.append(.trackingProtection(TrackingProtectionState(windowUUID: uuid)))
            case .toolbar:
                components.append(.toolbar(ToolbarState(windowUUID: uuid)))
            case .searchEngineSelection:
                components.append(.searchEngineSelection(SearchEngineSelectionState(windowUUID: uuid)))
            case .passwordGenerator:
                components.append(.passwordGenerator(PasswordGeneratorState(windowUUID: uuid)))
            case .nativeErrorPage:
                components.append(.nativeErrorPage(NativeErrorPageState(windowUUID: uuid)))
            case .shortcutsLibrary:
                components.append(.shortcutsLibrary(ShortcutsLibraryState(windowUUID: uuid)))
            case .translationSettings:
                components.append(.translationSettings(TranslationSettingsState(windowUUID: uuid)))
            }
        default:
            return components
        }

        return components
    }
}
