// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import Shared
import Common

protocol InactiveTabsCFRProtocol: AnyObject {
    func setupCFR(with view: UILabel)
    func presentCFR()
    func presentUndoToast(tabsCount: Int, completion: @escaping (Bool) -> Void)
    func presentUndoSingleToast(completion: @escaping (Bool) -> Void)
}

class LegacyInactiveTabViewModel {
    private var inactiveTabModel = LegacyInactiveTabModel()
    private var allTabs = [Tab]()
    private var selectedTab: Tab?
    var inactiveTabs = [Tab]()
    var activeTabs = [Tab]()
    var shouldHideInactiveTabs = false
    var theme: Theme

    private var appSessionManager: AppSessionProvider

    var isActiveTabsEmpty: Bool {
        return activeTabs.isEmpty || shouldHideInactiveTabs
    }

    init(theme: Theme,
         appSessionManager: AppSessionProvider = AppContainer.shared.resolve()) {
        self.theme = theme
        self.appSessionManager = appSessionManager
    }

    func updateInactiveTabs(with selectedTab: Tab?, tabs: [Tab]) {
        self.allTabs = tabs
        self.selectedTab = selectedTab
        clearAll()

        inactiveTabModel.tabWithStatus = LegacyInactiveTabModel.get()?.tabWithStatus ?? [String: InactiveTabStates]()

        updateModelState(state: appSessionManager.tabUpdateState)
        appSessionManager.tabUpdateState = .sameSession

        updateFilteredTabs()
    }

    // FIXME What is this comment saying? I don't have context... the dates described are wrong, and it didn't use the
    // debug test wrapper like the 2 other places this logic was used.
    //
    /// This function returns any tabs that are less than four days old.
    ///
    /// Because the "Jump Back In" and "Inactive Tabs" features are separate features,
    /// it is not a given that a tab has an active/inactive state. Thus, we must
    /// assume that if we want to use active/inactive state, we can do so without
    /// that particular feature being active but still respecting that logic.
    static func getActiveEligibleTabsFrom(_ tabs: [Tab]) -> [Tab] {
        return tabs.filter({ $0.isActive })
    }

    // MARK: - Private functions
    private func updateModelState(state: TabUpdateState) {
        let hasRunInactiveTabFeatureBefore = LegacyInactiveTabModel.hasRunInactiveTabFeatureBefore
        if hasRunInactiveTabFeatureBefore == false { LegacyInactiveTabModel.hasRunInactiveTabFeatureBefore = true }

        for tab in self.allTabs {
<<<<<<< HEAD
            // Append selected tab to normal tab as we don't want to remove that
            let tabTimeStamp = tab.lastExecutedTime ?? tab.firstCreatedTime ?? 0
            let tabDate = Date.fromTimestamp(tabTimeStamp)

=======
>>>>>>> c9e42869c (Add FXIOS-9987 Add Tab unit tests for isActive and isInactive (#21935))
            // 1. Initializing and assigning an empty inactive tab state to the inactiveTabModel mode
            if inactiveTabModel.tabWithStatus[tab.tabUUID] == nil {
                inactiveTabModel.tabWithStatus[tab.tabUUID] = InactiveTabStates()
            }

            // 2. Current tab type from inactive tab model
            // Note:
            //  a) newly assigned inactive tab model will have empty `tabWithStatus`
            //     with nil current and next states
            //  b) an older inactive tab model will have a proper `tabWithStatus`
            let tabType = inactiveTabModel.tabWithStatus[tab.tabUUID]

            // 3. All tabs should start with a normal current state if they don't have any current state
            if tabType?.currentState == nil { inactiveTabModel.tabWithStatus[tab.tabUUID]?.currentState = .normal }

            if tab == selectedTab {
                inactiveTabModel.tabWithStatus[tab.tabUUID]?.currentState = .normal
            } else if tabType?.nextState == .shouldBecomeInactive && state == .sameSession {
                continue
            } else if tab == selectedTab || tab.isActive {
                inactiveTabModel.tabWithStatus[tab.tabUUID]?.currentState = .normal
            } else if tab.isInactive {
                if hasRunInactiveTabFeatureBefore == false {
                    inactiveTabModel.tabWithStatus[tab.tabUUID]?.nextState = .shouldBecomeInactive
                } else if state == .coldStart {
                    inactiveTabModel.tabWithStatus[tab.tabUUID]?.currentState = .inactive
                    inactiveTabModel.tabWithStatus[tab.tabUUID]?.nextState = nil
                } else if state == .sameSession && tabType?.currentState != .inactive {
                    inactiveTabModel.tabWithStatus[tab.tabUUID]?.nextState = .shouldBecomeInactive
                }
            }
        }

        LegacyInactiveTabModel.save(tabModel: inactiveTabModel)
    }

    private func updateFilteredTabs() {
        inactiveTabModel.tabWithStatus = LegacyInactiveTabModel.get()?.tabWithStatus ?? [String: InactiveTabStates]()
        clearAll()
        for tab in self.allTabs {
            let status = inactiveTabModel.tabWithStatus[tab.tabUUID]
            if status == nil {
                activeTabs.append(tab)
            } else if let status = status, let currentState = status.currentState {
                addTab(state: currentState, tab: tab)
            }
        }
    }

    private func addTab(state: InactiveTabStatus?, tab: Tab) {
        switch state {
        case .inactive:
            inactiveTabs.append(tab)
        case .normal, .none:
            activeTabs.append(tab)
        case .shouldBecomeInactive: break
        }
    }

    private func clearAll() {
        activeTabs.removeAll()
        inactiveTabs.removeAll()
    }
}
