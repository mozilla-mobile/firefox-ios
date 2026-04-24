// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import CopyWithUpdates
import Redux
import Shared
import Storage

/// State for the jump back in section that is used in the homepage view
@CopyWithUpdates
struct JumpBackInSectionState: StateType, Equatable, Hashable {
    var windowUUID: WindowUUID
    let jumpBackInTabs: [JumpBackInTabConfiguration]
    let mostRecentSyncedTab: JumpBackInSyncedTabConfiguration?
    let shouldShowSection: Bool

    struct Constants {
        static let sectionHeaderConfiguration = SectionHeaderConfiguration(
            title: .FirefoxHomeJumpBackInSectionTitle,
            a11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.SectionTitles.jumpBackIn,
            isButtonHidden: false,
            buttonA11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.jumpBackIn,
            buttonTitle: .BookmarksSavedShowAllText
        )
    }

    init(
        profile: Profile = AppContainer.shared.resolve(),
        userPreferences: UserFeaturePreferring = AppContainer.shared.resolve(),
        windowUUID: WindowUUID
    ) {
        self.init(
            windowUUID: windowUUID,
            jumpBackInTabs: [],
            mostRecentSyncedTab: nil,
            shouldShowSection: userPreferences.isHomepageJumpBackInSectionEnabled
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
        // TODO: FXIOS-12557 We assume that we are isolated to the Main Actor
        // because we dispatch to the main thread in the store. We will want to
        // also isolate that to the @MainActor to remove this.
        guard Thread.isMainThread else {
            assertionFailure("JumpBackInSectionState reducer is not being called from the main thread!")
            return defaultState(from: state)
        }

        return MainActor.assumeIsolated {
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
    }

    @MainActor
    private static func handleInitializeAction(
        for state: JumpBackInSectionState,
        with action: Action
    ) -> JumpBackInSectionState {
        guard let tabManagerAction = action as? TabManagerAction,
              let recentTabs = tabManagerAction.recentTabs
        else {
            return defaultState(from: state)
        }

        return state.copyWithUpdates(
            jumpBackInTabs: recentTabs.compactMap { tab in
                let itemURL = tab.lastKnownUrl?.absoluteString ?? ""
                let site = Site.createBasicSite(url: itemURL, title: tab.displayTitle)
                return JumpBackInTabConfiguration(
                    tab: tab,
                    titleText: site.title,
                    descriptionText: site.tileURL.shortDisplayString.capitalized,
                    siteURL: itemURL
                )
            }
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

        return state.copyWithUpdates(
            mostRecentSyncedTab: JumpBackInSyncedTabConfiguration(
                titleText: site.title,
                descriptionText: descriptionText,
                url: mostRecentSyncedTab.tab.URL
            )
        )
    }

    private static func handleToggleShowSectionSettingAction(action: Action, state: Self) -> JumpBackInSectionState {
        guard let jumpBackInAction = action as? JumpBackInAction,
              let isEnabled = jumpBackInAction.isEnabled
        else {
            return defaultState(from: state)
        }

        return state.copyWithUpdates(
            shouldShowSection: isEnabled
        )
    }

    static func defaultState(from state: JumpBackInSectionState) -> JumpBackInSectionState {
        return state.copyWithUpdates()
    }
}
