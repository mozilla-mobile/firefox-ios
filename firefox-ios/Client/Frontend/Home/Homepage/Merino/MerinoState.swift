// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import CopyWithUpdates
import Foundation
import Redux
import Shared

/// State for the Merino stories section that is used in the homepage
@CopyWithUpdates
struct MerinoState: StateType, Equatable {
    var windowUUID: WindowUUID
    let merinoData: MerinoStoryResponse
    let hasMerinoResponseContent: Bool
    let selectedCategoryID: String? // nil = All stories
    let shouldShowSection: Bool

    struct Constants {
        static var sectionHeaderConfiguration: SectionHeaderConfiguration {
            // Computed property because feature flag configuration can change after launch
            MerinoState.initializeSectionHeaderConfiguration()
        }
        static let footerURL = SupportUtils.URLForPocketLearnMore
    }

    init(profile: Profile = AppContainer.shared.resolve(), windowUUID: WindowUUID) {
        let userPrefs = profile.prefs.boolForKey(PrefsKeys.UserFeatureFlagPrefs.ASPocketStories) ?? true
        let isLocaleSupported = MerinoProvider.isLocaleSupported(Locale.current.identifier)
        let shouldShowSection = userPrefs && isLocaleSupported

        self.init(
            windowUUID: windowUUID,
            merinoData: MerinoStoryResponse(),
            hasMerinoResponseContent: false,
            selectedCategoryID: nil,
            shouldShowSection: shouldShowSection
        )
    }

    private init(
        windowUUID: WindowUUID,
        merinoData: MerinoStoryResponse,
        hasMerinoResponseContent: Bool,
        selectedCategoryID: String?,
        shouldShowSection: Bool
    ) {
        self.windowUUID = windowUUID
        self.merinoData = merinoData
        self.hasMerinoResponseContent = hasMerinoResponseContent
        self.selectedCategoryID = selectedCategoryID
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
        case MerinoActionType.categorySelected:
            return handleCategorySelectedAction(action, state: state)
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

        let merinoContentExists = !(merinoResponse.stories?.isEmpty ?? true) ||
                                  !(merinoResponse.categories?.isEmpty ?? true)

        return MerinoState(
            windowUUID: state.windowUUID,
            merinoData: merinoResponse,
            hasMerinoResponseContent: merinoContentExists,
            selectedCategoryID: state.selectedCategoryID,
            shouldShowSection: merinoContentExists && state.shouldShowSection
        )
    }

    private static func handleSettingsToggleAction(_ action: Action, state: MerinoState) -> MerinoState {
        guard let pocketAction = action as? MerinoAction,
              let isEnabled = pocketAction.isEnabled
        else {
            return defaultState(from: state)
        }

        return state.copyWithUpdates(
            shouldShowSection: isEnabled
        )
    }

    private static func handleCategorySelectedAction(_ action: Action, state: MerinoState) -> MerinoState {
        guard let merinoAction = action as? MerinoAction
        else {
            return defaultState(from: state)
        }

        /// `copyWithUpdates` uses a double-optional for optional fields:
        /// - `.some(.some(value))` sets a concrete value
        /// - `.some(nil)` leaves the existing value unchanged
        /// - `nil` clears the property
        /// We need to pass the outer optional explicitly here so tapping the client-side  "All" category can clear
        /// `selectedCategoryID` back to `nil`.
        return state.copyWithUpdates(
            selectedCategoryID: merinoAction.selectedCategoryID == nil
                ? (nil as String??)
                : .some(merinoAction.selectedCategoryID)
        )
    }

    static func defaultState(from state: MerinoState) -> MerinoState {
        return state.copyWithUpdates()
    }

    private static func initializeSectionHeaderConfiguration() -> SectionHeaderConfiguration {
        return SectionHeaderConfiguration(
            title: .FirefoxHomepage.Pocket.NewsSectionTitle,
            a11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.SectionTitles.merino,
            style: .newsAffordance
        )
    }
}

/// `@CopyWithUpdates` currently treats computed properties declared inside the struct as
/// initializer/copy fields, which breaks generation with "extra arguments" errors.
/// Keep derived accessors in this extension as a workaround.
extension MerinoState {
    var availableCategories: [MerinoCategoryConfiguration] {
        (merinoData.categories ?? []).sorted { $0.rank < $1.rank }
    }

    var visibleStories: [MerinoStoryConfiguration] {
        if !availableCategories.isEmpty {
            if let selectedCategoryID {
                return availableCategories.first(where: { $0.feedID == selectedCategoryID })?.recommendations ?? []
            }
            return availableCategories.flatMap(\.recommendations)
        }
        return merinoData.stories ?? []
    }
}
