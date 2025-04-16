// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux
import Shared

struct PocketDiscoverConfiguration: Equatable, Hashable {
    var title: String
    var url: URL?
}

/// State for the pocket section that is used in the homepage
struct PocketState: StateType, Equatable {
    var windowUUID: WindowUUID
    let pocketData: [PocketStoryConfiguration]
    let shouldShowSection: Bool

    let sectionHeaderState = SectionHeaderConfiguration(
        title: .FirefoxHomepage.Pocket.SectionTitle,
        a11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.SectionTitles.pocket
    )

    let pocketDiscoverItem = PocketDiscoverConfiguration(
        title: .FirefoxHomepage.Pocket.DiscoverMore,
        url: PocketProvider.MoreStoriesURL
    )
    let footerURL = SupportUtils.URLForPocketLearnMore

    init(profile: Profile = AppContainer.shared.resolve(), windowUUID: WindowUUID) {
        let userPrefs = profile.prefs.boolForKey(PrefsKeys.UserFeatureFlagPrefs.ASPocketStories) ?? true
        let isLocaleSupported = PocketProvider.islocaleSupported(Locale.current.identifier)
        let shouldShowSection = userPrefs && isLocaleSupported

        self.init(
            windowUUID: windowUUID,
            pocketData: [],
            shouldShowSection: shouldShowSection
        )
    }

    private init(
        windowUUID: WindowUUID,
        pocketData: [PocketStoryConfiguration],
        shouldShowSection: Bool
    ) {
        self.windowUUID = windowUUID
        self.pocketData = pocketData
        self.shouldShowSection = shouldShowSection
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case PocketMiddlewareActionType.retrievedUpdatedStories:
            return handlePocketStoriesAction(action, state: state)
        case PocketActionType.toggleShowSectionSetting:
            return handleSettingsToggleAction(action, state: state)
        default:
            return defaultState(from: state)
        }
    }

    private static func handlePocketStoriesAction(_ action: Action, state: PocketState) -> PocketState {
        guard let pocketAction = action as? PocketAction,
              let pocketStories = pocketAction.pocketStories
        else {
            return defaultState(from: state)
        }

        return PocketState(
            windowUUID: state.windowUUID,
            pocketData: pocketStories,
            shouldShowSection: !pocketStories.isEmpty && state.shouldShowSection
        )
    }

    private static func handleSettingsToggleAction(_ action: Action, state: PocketState) -> PocketState {
        guard let pocketAction = action as? PocketAction,
              let isEnabled = pocketAction.isEnabled
        else {
            return defaultState(from: state)
        }

        return PocketState(
            windowUUID: state.windowUUID,
            pocketData: state.pocketData,
            shouldShowSection: isEnabled
        )
    }

    static func defaultState(from state: PocketState) -> PocketState {
        return PocketState(
            windowUUID: state.windowUUID,
            pocketData: state.pocketData,
            shouldShowSection: state.shouldShowSection
        )
    }
}
