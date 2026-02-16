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
    let merinoData: [MerinoStoryConfiguration]
    let shouldShowSection: Bool
    let sectionHeaderState = initializeSectionHeaderState()

    let footerURL = SupportUtils.URLForPocketLearnMore

    init(profile: Profile = AppContainer.shared.resolve(), windowUUID: WindowUUID) {
        let userPrefs = profile.prefs.boolForKey(PrefsKeys.UserFeatureFlagPrefs.ASPocketStories) ?? true
        let isLocaleSupported = MerinoProvider.isLocaleSupported(Locale.current.identifier)
        let shouldShowSection = userPrefs && isLocaleSupported

        self.init(
            windowUUID: windowUUID,
            merinoData: [],
            shouldShowSection: shouldShowSection
        )
    }

    private init(
        windowUUID: WindowUUID,
        merinoData: [MerinoStoryConfiguration],
        shouldShowSection: Bool
    ) {
        self.windowUUID = windowUUID
        self.merinoData = merinoData
        self.shouldShowSection = shouldShowSection
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case MerinoMiddlewareActionType.retrievedUpdatedHomepageStories:
            return handlePocketStoriesAction(action, state: state)
        case MerinoActionType.toggleShowSectionSetting:
            return handleSettingsToggleAction(action, state: state)
        default:
            return defaultState(from: state)
        }
    }

    private static func handlePocketStoriesAction(_ action: Action, state: MerinoState) -> MerinoState {
        guard let pocketAction = action as? MerinoAction,
              let pocketStories = pocketAction.merinoStories
        else {
            return defaultState(from: state)
        }

        return MerinoState(
            windowUUID: state.windowUUID,
            merinoData: pocketStories,
            shouldShowSection: !pocketStories.isEmpty && state.shouldShowSection
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
            shouldShowSection: isEnabled
        )
    }

    static func defaultState(from state: MerinoState) -> MerinoState {
        return MerinoState(
            windowUUID: state.windowUUID,
            merinoData: state.merinoData,
            shouldShowSection: state.shouldShowSection
        )
    }

    private static func initializeSectionHeaderState() -> SectionHeaderConfiguration {
        let scrollDirection: ScrollDirection = LegacyFeatureFlagsManager.shared
             .getCustomState(for: .homepageStoriesScrollDirection) ?? .baseline
         let isScrollDirectionCustomized = scrollDirection != .baseline

        return SectionHeaderConfiguration(
            title: .FirefoxHomepage.Pocket.PopularTodaySectionTitle,
            a11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.SectionTitles.merino,
            isButtonHidden: isScrollDirectionCustomized,
            buttonA11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.stories,
            buttonTitle: String.FirefoxHomepage.Pocket.AllStoriesButtonTitle
        )
    }
}
