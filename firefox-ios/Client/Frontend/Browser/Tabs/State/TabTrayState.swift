// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import ModifiedCopy
import Redux
import Common

enum TabTrayLayoutType: Equatable {
    case regular // iPad
    case compact // iPhone
}

@Copyable
struct TabTrayState: ScreenState, Equatable {
    var windowUUID: WindowUUID
    var isPrivateMode: Bool
    var selectedPanel: TabTrayPanelType
    var normalTabsCount: String
    var privateTabsCount: String
    var hasSyncableAccount: Bool
    var shouldDismiss: Bool
    var toastType: ToastType?
    var showCloseConfirmation: Bool
    var enableDeleteTabsButton: Bool?

    var navigationTitle: String {
        return selectedPanel.navTitle
    }

    var isSyncTabsPanel: Bool {
        return selectedPanel == .syncedTabs
    }

    var isNormalTabsPanel: Bool {
        return selectedPanel == .tabs
    }

    init(appState: AppState, uuid: WindowUUID) {
        guard let panelState = appState.componentState(
            TabTrayState.self,
            for: .tabsTray,
            window: uuid
        ) else {
            self.init(windowUUID: uuid, panelType: .tabs)
            return
        }

        self.init(windowUUID: panelState.windowUUID,
                  isPrivateMode: panelState.isPrivateMode,
                  selectedPanel: panelState.selectedPanel,
                  normalTabsCount: panelState.normalTabsCount,
                  privateTabsCount: panelState.privateTabsCount,
                  hasSyncableAccount: panelState.hasSyncableAccount,
                  shouldDismiss: panelState.shouldDismiss,
                  toastType: panelState.toastType,
                  showCloseConfirmation: panelState.showCloseConfirmation,
                  enableDeleteTabsButton: panelState.enableDeleteTabsButton)
    }

    init(windowUUID: WindowUUID) {
        self.init(windowUUID: windowUUID,
                  isPrivateMode: false,
                  selectedPanel: .tabs,
                  normalTabsCount: "0",
                  privateTabsCount: "0",
                  hasSyncableAccount: false,
                  toastType: nil)
    }

    init(windowUUID: WindowUUID, panelType: TabTrayPanelType) {
        self.init(windowUUID: windowUUID,
                  isPrivateMode: panelType == .privateTabs,
                  selectedPanel: panelType,
                  normalTabsCount: "0",
                  privateTabsCount: "0",
                  hasSyncableAccount: false)
    }

    init(windowUUID: WindowUUID,
         isPrivateMode: Bool,
         selectedPanel: TabTrayPanelType,
         normalTabsCount: String,
         privateTabsCount: String,
         hasSyncableAccount: Bool,
         shouldDismiss: Bool = false,
         toastType: ToastType? = nil,
         showCloseConfirmation: Bool = false,
         enableDeleteTabsButton: Bool? = nil) {
        self.windowUUID = windowUUID
        self.isPrivateMode = isPrivateMode
        self.selectedPanel = selectedPanel
        self.normalTabsCount = normalTabsCount
        self.privateTabsCount = privateTabsCount
        self.hasSyncableAccount = hasSyncableAccount
        self.shouldDismiss = shouldDismiss
        self.toastType = toastType
        self.showCloseConfirmation = showCloseConfirmation
        self.enableDeleteTabsButton = enableDeleteTabsButton
    }

    static let reducer: Reducer<Self> = (legacyReducer, modernReducer)

    static let modernReducer: ReducerMethod<Self> = { state, action, actionWindowUUID in
        // Does not handle any modern actions
        return defaultState(from: state)
    }

    static let legacyReducer: LegacyReducerMethod<Self> = { state, action in
        // Only process actions for the current window
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        if let action  = action as? TabTrayAction {
            return reduceTabTrayAction(action: action, state: state)
        } else if let action = action as? TabPanelMiddlewareAction {
            return reduceTabPanelMiddlewareAction(action: action, state: state)
        } else if let action = action as? TabPanelViewAction {
            return reduceTabPanelViewAction(action: action, state: state)
        }

        return defaultState(from: state)
    }

    @MainActor
    static func reduceTabTrayAction(action: TabTrayAction, state: TabTrayState) -> TabTrayState {
        switch action.actionType {
        case TabTrayActionType.didLoadTabTray:
            guard let tabTrayModel = action.tabTrayModel else { return defaultState(from: state) }
            return state
                .copy(isPrivateMode: tabTrayModel.isPrivateMode)
                .copy(selectedPanel: tabTrayModel.selectedPanel)
                .copy(normalTabsCount: tabTrayModel.normalTabsCount)
                .copy(privateTabsCount: tabTrayModel.privateTabsCount)
                .copy(hasSyncableAccount: tabTrayModel.hasSyncableAccount)
                .copy(shouldDismiss: false)
                .copy(toastType: nil)
                .copy(showCloseConfirmation: false)
                .copy(enableDeleteTabsButton: tabTrayModel.enableDeleteTabsButton)

        case TabTrayActionType.changePanel:
            guard let panelType = action.panelType else { return defaultState(from: state) }
            return state
                .copy(isPrivateMode: panelType == .privateTabs)
                .copy(selectedPanel: panelType)
                .copy(shouldDismiss: false)
                .copy(toastType: nil)
                .copy(showCloseConfirmation: false)
                .copy(enableDeleteTabsButton: nil)

        case TabTrayActionType.dismissTabTray:
            return state
                .copy(shouldDismiss: true)
                .copy(toastType: nil)
                .copy(showCloseConfirmation: false)
                .copy(enableDeleteTabsButton: nil)

        case TabTrayActionType.firefoxAccountChanged:
            guard let isSyncAccountEnabled = action.hasSyncableAccount else { return defaultState(from: state) }
            return state
                .copy(hasSyncableAccount: isSyncAccountEnabled)
                .copy(shouldDismiss: false)
                .copy(toastType: nil)
                .copy(showCloseConfirmation: false)
                .copy(enableDeleteTabsButton: nil)

        default:
            return defaultState(from: state)
        }
    }

    @MainActor
    static func reduceTabPanelMiddlewareAction(action: TabPanelMiddlewareAction, state: TabTrayState) -> TabTrayState {
        switch action.actionType {
        case TabPanelMiddlewareActionType.didChangeTabPanel:
            guard let tabDisplayModel = action.tabDisplayModel else { return defaultState(from: state) }
            let panelType = tabDisplayModel.isPrivateMode ? TabTrayPanelType.privateTabs : TabTrayPanelType.tabs
            return state
                .copy(isPrivateMode: tabDisplayModel.isPrivateMode)
                .copy(selectedPanel: panelType)
                .copy(normalTabsCount: tabDisplayModel.normalTabsCount)
                .copy(privateTabsCount: "\(tabDisplayModel.tabs.filter({ $0.isPrivate == true }).count)")
                .copy(shouldDismiss: false)
                .copy(toastType: nil)
                .copy(showCloseConfirmation: false)
                .copy(enableDeleteTabsButton: tabDisplayModel.enableDeleteTabsButton)

        case TabPanelMiddlewareActionType.refreshTabs:
            // Only update the normal tab count if the tabs being refreshed are not private
            guard let tabDisplayModel = action.tabDisplayModel else { return defaultState(from: state) }
            let isPrivate = tabDisplayModel.tabs.first?.isPrivate ?? false
            let tabCount = isPrivate ? state.normalTabsCount : tabDisplayModel.normalTabsCount
            return state
                .copy(normalTabsCount: tabCount)
                .copy(privateTabsCount: tabDisplayModel.privateTabsCount)
                .copy(shouldDismiss: false)
                .copy(toastType: nil)
                .copy(showCloseConfirmation: false)
                .copy(enableDeleteTabsButton: tabDisplayModel.enableDeleteTabsButton)

        default:
            return defaultState(from: state)
        }
    }

    @MainActor
    static func reduceTabPanelViewAction(action: TabPanelViewAction, state: TabTrayState) -> TabTrayState {
        switch action.actionType {
        case TabPanelViewActionType.closeAllTabs:
            return state
                .copy(shouldDismiss: false)
                .copy(toastType: nil)
                .copy(showCloseConfirmation: true)
                .copy(enableDeleteTabsButton: nil)

        default:
            return defaultState(from: state)
        }
    }

    static func defaultState(from state: TabTrayState) -> TabTrayState {
        return state
            .copy(shouldDismiss: false)
            .copy(toastType: nil)
            .copy(showCloseConfirmation: false)
            .copy(enableDeleteTabsButton: nil)
    }
}
