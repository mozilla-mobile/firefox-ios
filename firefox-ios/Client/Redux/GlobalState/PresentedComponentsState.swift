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
    case termsOfUse(TermsOfUseState)
    case trackingProtection(TrackingProtectionState)
    case toolbar(ToolbarState)
    case searchEngineSelection(SearchEngineSelectionState)
    case passwordGenerator(PasswordGeneratorState)
    case nativeErrorPage(NativeErrorPageState)
    case shortcutsLibrary(ShortcutsLibraryState)
    case translationSettings(TranslationSettingsState)
    case webCompatReporter(WebCompatReporterState)

    static let reducer: Reducer<Self> = (legacyReducer, modernReducer)

    // swiftlint:disable closure_body_length
    static let modernReducer: ReducerMethod<Self> = { state, action, actionWindowUUID in
        switch state {
        case .browserViewController(let state):
            return .browserViewController(BrowserViewControllerState.reducer.modernReducer(state, action, actionWindowUUID))
        case .homepage(let state):
            return .homepage(HomepageState.reducer.modernReducer(state, action, actionWindowUUID))
        case .mainMenu(let state):
            return .mainMenu(MainMenuState.reducer.modernReducer(state, action, actionWindowUUID))
        case .microsurvey(let state):
            return .microsurvey(MicrosurveyState.reducer.modernReducer(state, action, actionWindowUUID))
        case .remoteTabsPanel(let state):
            return .remoteTabsPanel(RemoteTabsPanelState.reducer.modernReducer(state, action, actionWindowUUID))
        case .tabPeek(let state):
            return .tabPeek(TabPeekState.reducer.modernReducer(state, action, actionWindowUUID))
        case .tabsTray(let state):
            return .tabsTray(TabTrayState.reducer.modernReducer(state, action, actionWindowUUID))
        case .tabsPanel(let state):
            return .tabsPanel(TabsPanelState.reducer.modernReducer(state, action, actionWindowUUID))
        case .termsOfUse(let state):
            return .termsOfUse(TermsOfUseState.reducer.modernReducer(state, action, actionWindowUUID))
        case .trackingProtection(let state):
            return .trackingProtection(TrackingProtectionState.reducer.modernReducer(state, action, actionWindowUUID))
        case .toolbar(let state):
            return .toolbar(ToolbarState.reducer.modernReducer(state, action, actionWindowUUID))
        case .searchEngineSelection(let state):
            return .searchEngineSelection(SearchEngineSelectionState.reducer.modernReducer(state, action, actionWindowUUID))
        case .passwordGenerator(let state):
            return .passwordGenerator(PasswordGeneratorState.reducer.modernReducer(state, action, actionWindowUUID))
        case .nativeErrorPage(let state):
            return .nativeErrorPage(NativeErrorPageState.reducer.modernReducer(state, action, actionWindowUUID))
        case .shortcutsLibrary(let state):
            return .shortcutsLibrary(ShortcutsLibraryState.reducer.modernReducer(state, action, actionWindowUUID))
        case .translationSettings(let state):
            return .translationSettings(TranslationSettingsState.reducer.modernReducer(state, action, actionWindowUUID))
        case .webCompatReporter(let state):
            return .webCompatReporter(WebCompatReporterState.reducer.modernReducer(state, action, actionWindowUUID))
        }
    }

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
        case .webCompatReporter(let state):
            return .webCompatReporter(WebCompatReporterState.reducer.legacyReducer(state, action))
        }
    }
    // swiftlint:enable closure_body_length

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
        case .termsOfUse: return .termsOfUse
        case .trackingProtection: return .trackingProtection
        case .toolbar: return .toolbar
        case .searchEngineSelection: return .searchEngineSelection
        case .passwordGenerator: return .passwordGenerator
        case .nativeErrorPage: return .nativeErrorPage
        case .shortcutsLibrary: return .shortcutsLibrary
        case .translationSettings: return .translationSettings
        case .webCompatReporter: return .webCompatReporter
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
        case .termsOfUse(let state): return state.windowUUID
        case .trackingProtection(let state): return state.windowUUID
        case .toolbar(let state): return state.windowUUID
        case .searchEngineSelection(let state): return state.windowUUID
        case .passwordGenerator(let state): return state.windowUUID
        case .nativeErrorPage(let state): return state.windowUUID
        case .shortcutsLibrary(let state): return state.windowUUID
        case .translationSettings(let state): return state.windowUUID
        case .webCompatReporter(let state): return state.windowUUID
        }
    }
}

/// Pairs a component's state with the identity of the screen instance that added it, so an instance can
/// add, remove, and read exactly its own entry. `screenIdentity` is `nil` for screens that don't opt
/// into per-instance ownership, they keep the original match-by-`(component, window)` behavior.
struct ActiveComponent: Sendable, Equatable {
    let screenIdentity: UUID?
    let state: ComponentState
}

struct PresentedComponentsState: Sendable, Equatable {
    let components: [ActiveComponent]

    init() {
        self.components = []
    }

    init(components: [ActiveComponent]) {
        self.components = components
    }

    /// Convenience for callers/tests that don't use per-instance identity.
    init(components: [ComponentState]) {
        self.components = components.map { ActiveComponent(screenIdentity: nil, state: $0) }
    }

    static let reducer: Reducer<Self> = (legacyReducer, modernReducer)

    static let modernReducer: ReducerMethod<Self> = { state, action, actionWindowUUID in
        // This reducer does not handle any modern actions for component state; those are in the legacy reducer, so skip
        // updating active components.
        // Reduce each component state (forward the modern action to child reducers which may act on them)
        let components = state.components.map {
            ActiveComponent(
                screenIdentity: $0.screenIdentity,
                state: ComponentState.reducer.modernReducer($0.state, action, actionWindowUUID)
            )
        }

        return PresentedComponentsState(components: components)
    }

    static let legacyReducer: LegacyReducerMethod<Self> = { state, action in
        // Add or remove components from the active component list as needed
        var components = updateActiveComponents(action: action, components: state.components)

        // Reduce each component state, preserving the identity of the screen that owns it.
        components = components.map {
            ActiveComponent(screenIdentity: $0.screenIdentity, state: ComponentState.legacyReducer($0.state, action))
        }

        return PresentedComponentsState(components: components)
    }

    private static func updateActiveComponents(action: Action, components: [ActiveComponent]) -> [ActiveComponent] {
        guard let action = action as? ComponentAction else { return components }

        var components = components

        switch action.actionType {
        case ComponentActionType.removeComponent:
            components = components.filter {
                let matches = $0.state.associatedAppComponent == action.component && $0.state.windowUUID == action.windowUUID
                guard matches else { return true }
                // With an identity, only remove that instance's entry; without one, remove every
                // matching `(component, window)` entry (the original behavior).
                if let identity = action.screenIdentity {
                    return $0.screenIdentity != identity
                }
                return false
            }
        case ComponentActionType.addComponent:
            let state = makeComponentState(for: action.component, windowUUID: action.windowUUID)
            components.append(ActiveComponent(screenIdentity: action.screenIdentity, state: state))
        default:
            return components
        }

        return components
    }

    private static func makeComponentState(for component: AppComponent, windowUUID uuid: WindowUUID) -> ComponentState {
        switch component {
        case .browserViewController: return .browserViewController(BrowserViewControllerState(windowUUID: uuid))
        case .homepage: return .homepage(HomepageState(windowUUID: uuid))
        case .mainMenu: return .mainMenu(MainMenuState(windowUUID: uuid))
        case .microsurvey: return .microsurvey(MicrosurveyState(windowUUID: uuid))
        case .remoteTabsPanel: return .remoteTabsPanel(RemoteTabsPanelState(windowUUID: uuid))
        case .tabsTray: return .tabsTray(TabTrayState(windowUUID: uuid))
        case .tabsPanel: return .tabsPanel(TabsPanelState(windowUUID: uuid))
        case .tabPeek: return .tabPeek(TabPeekState(windowUUID: uuid))
        case .termsOfUse: return .termsOfUse(TermsOfUseState(windowUUID: uuid))
        case .trackingProtection: return .trackingProtection(TrackingProtectionState(windowUUID: uuid))
        case .toolbar: return .toolbar(ToolbarState(windowUUID: uuid))
        case .searchEngineSelection: return .searchEngineSelection(SearchEngineSelectionState(windowUUID: uuid))
        case .passwordGenerator: return .passwordGenerator(PasswordGeneratorState(windowUUID: uuid))
        case .nativeErrorPage: return .nativeErrorPage(NativeErrorPageState(windowUUID: uuid))
        case .shortcutsLibrary: return .shortcutsLibrary(ShortcutsLibraryState(windowUUID: uuid))
        case .translationSettings: return .translationSettings(TranslationSettingsState(windowUUID: uuid))
        case .webCompatReporter: return .webCompatReporter(WebCompatReporterState(windowUUID: uuid))
        }
    }
}
