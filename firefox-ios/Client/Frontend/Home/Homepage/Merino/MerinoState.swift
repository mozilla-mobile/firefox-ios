// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux
import Shared

/// State for the Merino stories section that is used in the homepage
struct MerinoState: StateType, Equatable {
    var windowUUID: WindowUUID
    let merinoData: MerinoStoryResponse
    let hasMerinoResponseContent: Bool
    let shouldShowSection: Bool
    let sectionHeaderState = initializeSectionHeaderState()

    let footerURL = SupportUtils.URLForPocketLearnMore

    init(profile: Profile = AppContainer.shared.resolve(), windowUUID: WindowUUID) {
        let userPrefs = profile.prefs.boolForKey(PrefsKeys.UserFeatureFlagPrefs.ASPocketStories) ?? true
        let isLocaleSupported = MerinoProvider.isLocaleSupported(Locale.current.identifier)
        let shouldShowSection = userPrefs && isLocaleSupported

        self.init(
            windowUUID: windowUUID,
            merinoData: MerinoStoryResponse(),
            hasMerinoResponseContent: false,
            shouldShowSection: shouldShowSection
        )
    }

    private init(
        windowUUID: WindowUUID,
        merinoData: MerinoStoryResponse,
        hasMerinoResponseContent: Bool,
        shouldShowSection: Bool
    ) {
        self.windowUUID = windowUUID
        self.merinoData = merinoData
        self.hasMerinoResponseContent = hasMerinoResponseContent
        self.shouldShowSection = shouldShowSection
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case MerinoMiddlewareActionType.retrievedUpdatedHomepageStories:
            return handleMerinoStoriesAction(action, state: state)
        case MerinoActionType.toggleShowSectionSetting:
            return handleSettingsToggleAction(action, state: state)
        default:
            return defaultState(from: state)
        }
    }

    private static func handleMerinoStoriesAction(_ action: Action, state: MerinoState) -> MerinoState {
        guard let merinoAction = action as? MerinoAction,
              let merinoResponse = merinoAction.merinoResponse
        else {
            return defaultState(from: state)
        }

        let merinoContentExists = if let stories = merinoResponse.stories {
            !stories.isEmpty
        } else if let categories = merinoResponse.categories {
            !categories.isEmpty
        } else {
            false
        }

        return MerinoState(
            windowUUID: state.windowUUID,
            merinoData: merinoResponse,
            hasMerinoResponseContent: merinoContentExists,
            shouldShowSection: merinoContentExists && state.shouldShowSection
        )
    }

    private static func handleSettingsToggleAction(_ action: Action, state: MerinoState) -> MerinoState {
        guard let pocketAction = action as? MerinoAction,
              let isEnabled = pocketAction.isEnabled
        else {
            return defaultState(from: state)
        }

        return MerinoState(
            windowUUID: state.windowUUID,
            merinoData: state.merinoData,
            hasMerinoResponseContent: state.hasMerinoResponseContent,
            shouldShowSection: isEnabled
        )
    }

    static func defaultState(from state: MerinoState) -> MerinoState {
        return MerinoState(
            windowUUID: state.windowUUID,
            merinoData: state.merinoData,
            hasMerinoResponseContent: state.hasMerinoResponseContent,
            shouldShowSection: state.shouldShowSection
        )
    }

    private static func initializeSectionHeaderState() -> SectionHeaderConfiguration {
        let scrollDirection: ScrollDirection = LegacyFeatureFlagsManager.shared
             .getCustomState(for: .homepageStoriesScrollDirection) ?? .baseline
        let isScrollDirectionVertical = scrollDirection == .vertical

        return SectionHeaderConfiguration(
            title: .FirefoxHomepage.Pocket.NewsSectionTitle,
            a11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.SectionTitles.merino,
            style: isScrollDirectionVertical ? .newsAffordance : .sectionTitle
        )
    }
}
