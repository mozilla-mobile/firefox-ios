// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Storage

enum TabTrayLayoutType: Equatable {
    case regular // iPad
    case compact // iPhone
}

struct TabTrayState: ScreenState, Equatable {
    var isPrivateMode: Bool
    var selectedPanel: TabTrayPanelType
    var normalTabsCount: String
    var hasSyncableAccount: Bool
    var shouldDismiss: Bool
    var shareURL: URL?

    var navigationTitle: String {
        return selectedPanel.navTitle
    }

    var isSyncTabsPanel: Bool {
        return selectedPanel == .syncedTabs
    }

    init(_ appState: AppState) {
        guard let panelState = store.state.screenState(TabTrayState.self, for: .tabsTray) else {
            self.init()
            return
        }

        self.init(isPrivateMode: panelState.isPrivateMode,
                  selectedPanel: panelState.selectedPanel,
                  normalTabsCount: panelState.normalTabsCount,
                  hasSyncableAccount: panelState.hasSyncableAccount,
                  shouldDismiss: panelState.shouldDismiss,
                  shareURL: panelState.shareURL)
    }

    init() {
        self.init(isPrivateMode: false,
                  selectedPanel: .tabs,
                  normalTabsCount: "0",
                  hasSyncableAccount: false)
    }

    init(panelType: TabTrayPanelType) {
        self.init(isPrivateMode: panelType == .privateTabs,
                  selectedPanel: panelType,
                  normalTabsCount: "0",
                  hasSyncableAccount: false)
    }

    init(isPrivateMode: Bool,
         selectedPanel: TabTrayPanelType,
         normalTabsCount: String,
         hasSyncableAccount: Bool,
         shouldDismiss: Bool = false,
         shareURL: URL? = nil) {
        self.isPrivateMode = isPrivateMode
        self.selectedPanel = selectedPanel
        self.normalTabsCount = normalTabsCount
        self.hasSyncableAccount = hasSyncableAccount
        self.shouldDismiss = shouldDismiss
        self.shareURL = shareURL
    }

    static let reducer: Reducer<Self> = { state, action in
        switch action {
        case TabTrayAction.didLoadTabTray(let tabTrayModel):
            return TabTrayState(isPrivateMode: tabTrayModel.isPrivateMode,
                                selectedPanel: tabTrayModel.selectedPanel,
                                normalTabsCount: tabTrayModel.normalTabsCount,
                                hasSyncableAccount: tabTrayModel.hasSyncableAccount)
        case TabTrayAction.changePanel(let panelType):
            return TabTrayState(isPrivateMode: panelType == .privateTabs,
                                selectedPanel: panelType,
                                normalTabsCount: state.normalTabsCount,
                                hasSyncableAccount: state.hasSyncableAccount)
        case TabPanelAction.didLoadTabPanel(let tabState):
            let panelType = tabState.isPrivateMode ? TabTrayPanelType.privateTabs : TabTrayPanelType.tabs
            return TabTrayState(isPrivateMode: tabState.isPrivateMode,
                                selectedPanel: panelType,
                                normalTabsCount: tabState.normalTabsCount,
                                hasSyncableAccount: state.hasSyncableAccount)
        case TabTrayAction.dismissTabTray:
            return TabTrayState(isPrivateMode: state.isPrivateMode,
                                selectedPanel: state.selectedPanel,
                                normalTabsCount: state.normalTabsCount,
                                hasSyncableAccount: state.hasSyncableAccount,
                                shouldDismiss: true)
        case TabTrayAction.firefoxAccountChanged(let isSyncAccountEnabled):
                return TabTrayState(isPrivateMode: state.isPrivateMode,
                                    selectedPanel: state.selectedPanel,
                                    normalTabsCount: state.normalTabsCount,
                                    hasSyncableAccount: isSyncAccountEnabled)
        case TabPanelAction.showShareSheet(let shareURL):
            return TabTrayState(isPrivateMode: state.isPrivateMode,
                                selectedPanel: state.selectedPanel,
                                normalTabsCount: state.normalTabsCount,
                                hasSyncableAccount: state.hasSyncableAccount,
                                shareURL: shareURL)
        default:
            return state
        }
    }
}
