// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import CopyWithUpdates
import Foundation
import Redux
import Shared

/// State for the top sites section that is used in the homepage
/// The state does not only contain the top sites list, but needs to also know about the number of rows
/// and tiles per row in order to only show a specific amount of the top sites data.
@CopyWithUpdates
struct TopSitesSectionState: StateType, Equatable {
    var windowUUID: WindowUUID
    let topSitesData: [TopSiteConfiguration]
    let numberOfRows: Int
    let numberOfTilesPerRow: Int
    let shouldShowSection: Bool
    let shouldShowSectionHeader: Bool

    struct Constants {
        static let sectionHeaderConfiguration = SectionHeaderConfiguration(
            title: .FirefoxHomepage.Shortcuts.SectionTitle,
            a11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.SectionTitles.topSites,
            isButtonHidden: false,
            buttonA11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.shortcuts,
            buttonTitle: .BookmarksSavedShowAllText
        )
    }

    init(profile: Profile = AppContainer.shared.resolve(), windowUUID: WindowUUID) {
        let preferredNumberOfRows = profile.prefs.intForKey(PrefsKeys.NumberOfTopSiteRows)
        let defaultNumberOfRows = TopSitesRowCountSettingsController.defaultNumberOfRows
        let numberOfRows = Int(preferredNumberOfRows ?? defaultNumberOfRows)
        let shouldShowSection = profile.prefs.boolForKey(PrefsKeys.UserFeatureFlagPrefs.TopSiteSection) ?? true

        self.init(
            windowUUID: windowUUID,
            topSitesData: [],
            numberOfRows: numberOfRows,
            numberOfTilesPerRow: TopSitesSectionLayoutProvider.UX.minCards,
            shouldShowSection: shouldShowSection,
            shouldShowSectionHeader: false
        )
    }

    private init(
        windowUUID: WindowUUID,
        topSitesData: [TopSiteConfiguration],
        numberOfRows: Int,
        numberOfTilesPerRow: Int,
        shouldShowSection: Bool,
        shouldShowSectionHeader: Bool,
    ) {
        self.windowUUID = windowUUID
        self.topSitesData = topSitesData
        self.numberOfRows = numberOfRows
        self.numberOfTilesPerRow = numberOfTilesPerRow
        self.shouldShowSection = shouldShowSection
        self.shouldShowSectionHeader = shouldShowSectionHeader
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case TopSitesMiddlewareActionType.retrievedUpdatedSites:
            return handleRetrievedUpdatedSitesAction(action: action, state: state)
        case TopSitesActionType.updatedNumberOfRows:
            return handleUpdatedNumberOfRowsAction(action: action, state: state)
        case TopSitesActionType.toggleShowSectionSetting:
            return handleToggleShowSectionSettingAction(action: action, state: state)
        case HomepageActionType.initialize, HomepageActionType.viewWillTransition, HomepageActionType.viewDidLayoutSubviews:
            return handleViewChangeAction(action: action, state: state)
        default:
            return defaultState(from: state)
        }
    }

    private static func handleRetrievedUpdatedSitesAction(action: Action, state: Self) -> TopSitesSectionState {
        guard let topSitesAction = action as? TopSitesAction,
              let sites = topSitesAction.topSites
        else {
            return defaultState(from: state)
        }

        let shouldShowSectionHeader = sites.count > state.numberOfRows * state.numberOfTilesPerRow

        return state.copyWithUpdates(
            topSitesData: sites,
            shouldShowSectionHeader: shouldShowSectionHeader
        )
    }

    private static func handleUpdatedNumberOfRowsAction(action: Action, state: Self) -> TopSitesSectionState {
        guard let topSitesAction = action as? TopSitesAction,
              let numberOfRows = topSitesAction.numberOfRows
        else {
            return defaultState(from: state)
        }

        let shouldShowSectionHeader = state.topSitesData.count > numberOfRows * state.numberOfTilesPerRow

        return state.copyWithUpdates(
            numberOfRows: numberOfRows,
            shouldShowSectionHeader: shouldShowSectionHeader
        )
    }

    private static func handleViewChangeAction(action: Action, state: Self) -> TopSitesSectionState {
        guard let homepageAction = action as? HomepageAction,
              let numberOfTilesPerRow = homepageAction.numberOfTopSitesPerRow
        else {
            return defaultState(from: state)
        }

        let shouldShowSectionHeader = state.topSitesData.count > state.numberOfRows * numberOfTilesPerRow

        return state.copyWithUpdates(
            numberOfTilesPerRow: numberOfTilesPerRow,
            shouldShowSectionHeader: shouldShowSectionHeader
        )
    }

    private static func handleToggleShowSectionSettingAction(action: Action, state: Self) -> TopSitesSectionState {
        guard let topSitesAction = action as? TopSitesAction,
              let isEnabled = topSitesAction.isEnabled
        else {
            return defaultState(from: state)
        }

        return state.copyWithUpdates(
            shouldShowSection: isEnabled
        )
    }

    static func defaultState(from state: TopSitesSectionState) -> TopSitesSectionState {
        return state.copyWithUpdates()
    }
}
