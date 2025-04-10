// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared
import Storage

/// State for the jump back in section that is used in the homepage view
struct JumpBackInSectionState: StateType, Equatable, Hashable {
    var windowUUID: WindowUUID
    let jumpBackInTabs: [JumpBackInTabConfiguration]
    let mostRecentSyncedTab: JumpBackInSyncedTabConfiguration?
    let shouldShowSection: Bool

    let sectionHeaderState = SectionHeaderConfiguration(
        title: .FirefoxHomeJumpBackInSectionTitle,
        a11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.SectionTitles.jumpBackIn,
        isButtonHidden: false,
        buttonA11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.jumpBackIn,
        buttonTitle: .BookmarksSavedShowAllText
    )

    init(
        profile: Profile = AppContainer.shared.resolve(),
        windowUUID: WindowUUID
    ) {
        // TODO: FXIOS-11412 / 11226 - Move profile dependency and show section also based on feature flags
        let shouldShowSection = profile.prefs.boolForKey(PrefsKeys.FeatureFlags.JumpBackInSection) ?? true
        self.init(
            windowUUID: windowUUID,
            jumpBackInTabs: [],
            mostRecentSyncedTab: nil,
            shouldShowSection: shouldShowSection
        )
    }

    private init(
        windowUUID: WindowUUID,
        jumpBackInTabs: [JumpBackInTabConfiguration],
        mostRecentSyncedTab: JumpBackInSyncedTabConfiguration? = nil,
        shouldShowSection: Bool
    ) {
        self.windowUUID = windowUUID
        self.jumpBackInTabs = jumpBackInTabs
        self.mostRecentSyncedTab = mostRecentSyncedTab
        self.shouldShowSection = shouldShowSection
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case TabManagerMiddlewareActionType.fetchedRecentTabs:
            return handleInitializeAction(for: state, with: action)
        case RemoteTabsMiddlewareActionType.fetchedMostRecentSyncedTab:
            return handleRemoteTabsAction(for: state, with: action)
        case JumpBackInActionType.toggleShowSectionSetting:
            return handleToggleShowSectionSettingAction(action: action, state: state)
        default:
            return defaultState(from: state)
        }
    }

    private static func handleInitializeAction(
        for state: JumpBackInSectionState,
        with action: Action
    ) -> JumpBackInSectionState {
        guard let tabManagerAction = action as? TabManagerAction,
              let recentTabs = tabManagerAction.recentTabs
        else {
            return defaultState(from: state)
        }

        return JumpBackInSectionState(
            windowUUID: state.windowUUID,
            jumpBackInTabs: recentTabs.compactMap { tab in
                let itemURL = tab.lastKnownUrl?.absoluteString ?? ""
                let site = Site.createBasicSite(url: itemURL, title: tab.displayTitle)
                return JumpBackInTabConfiguration(
                    tab: tab,
                    titleText: site.title,
                    descriptionText: site.tileURL.shortDisplayString.capitalized,
                    siteURL: itemURL
                )
            },
            mostRecentSyncedTab: state.mostRecentSyncedTab,
            shouldShowSection: state.shouldShowSection
        )
    }

    private static func handleRemoteTabsAction(
        for state: JumpBackInSectionState,
        with action: Action
    ) -> JumpBackInSectionState {
        guard let tabManagerAction = action as? RemoteTabsAction,
              let mostRecentSyncedTab = tabManagerAction.mostRecentSyncedTab
        else {
            return defaultState(from: state)
        }

        let itemURL = mostRecentSyncedTab.tab.URL.absoluteString
        let site = Site.createBasicSite(url: itemURL, title: mostRecentSyncedTab.tab.title)
        let descriptionText = mostRecentSyncedTab.client.name

        return JumpBackInSectionState(
            windowUUID: state.windowUUID,
            jumpBackInTabs: state.jumpBackInTabs,
            mostRecentSyncedTab: JumpBackInSyncedTabConfiguration(
                titleText: site.title,
                descriptionText: descriptionText,
                url: mostRecentSyncedTab.tab.URL
            ),
            shouldShowSection: state.shouldShowSection
        )
    }

    private static func handleToggleShowSectionSettingAction(action: Action, state: Self) -> JumpBackInSectionState {
        guard let jumpBackInAction = action as? JumpBackInAction,
              let isEnabled = jumpBackInAction.isEnabled
        else {
            return defaultState(from: state)
        }

        return JumpBackInSectionState(
            windowUUID: state.windowUUID,
            jumpBackInTabs: state.jumpBackInTabs,
            mostRecentSyncedTab: state.mostRecentSyncedTab,
            shouldShowSection: isEnabled
        )
    }

    static func defaultState(from state: JumpBackInSectionState) -> JumpBackInSectionState {
        return JumpBackInSectionState(
            windowUUID: state.windowUUID,
            jumpBackInTabs: state.jumpBackInTabs,
            mostRecentSyncedTab: state.mostRecentSyncedTab,
            shouldShowSection: state.shouldShowSection
        )
    }
}
