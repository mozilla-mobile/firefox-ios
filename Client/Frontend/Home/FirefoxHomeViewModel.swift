// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices

class FirefoxHomeViewModel: FeatureFlagsProtocol {

    // MARK: - Properties
    
    // Privacy of home page is controlled throught notifications since tab manager selected tab
    // isn't always the proper privacy mode that should be reflected on the home page
    var isPrivate: Bool
    let experiments: NimbusApi
    let profile: Profile
    var isZeroSearch: Bool
    var enabledSections = [FirefoxHomeSectionType]()

    // Child View models
    var recentlySavedViewModel: FirefoxHomeRecentlySavedViewModel
    var jumpBackInViewModel: FirefoxHomeJumpBackInViewModel
    var historyHighlightsViewModel: FxHomeHistoryHightlightsVM
    var pocketViewModel: FxHomePocketViewModel

    lazy var homescreen = experiments.withVariables(featureId: .homescreen, sendExposureEvent: false) {
        Homescreen(variables: $0)
    }

    lazy var topSitesManager: ASHorizontalScrollCellManager = {
        let manager = ASHorizontalScrollCellManager()
        return manager
    }()

    // MARK: - Section availability variables
    var shouldShowFxLogoHeader: Bool {
        return featureFlags.isFeatureActiveForBuild(.wallpapers)
    }

    var isTopSitesSectionEnabled: Bool {
        homescreen.sectionsEnabled[.topSites] == true
    }

    var isYourLibrarySectionEnabled: Bool {
        UIDevice.current.userInterfaceIdiom != .pad &&
            homescreen.sectionsEnabled[.libraryShortcuts] == true
    }

    var isJumpBackInSectionEnabled: Bool {
        guard featureFlags.isFeatureActiveForBuild(.jumpBackIn),
              homescreen.sectionsEnabled[.jumpBackIn] == true,
              featureFlags.userPreferenceFor(.jumpBackIn) == UserFeaturePreference.enabled
        else { return false }

        let tabManager = BrowserViewController.foregroundBVC().tabManager
        return !isPrivate && !tabManager.recentlyAccessedNormalTabs.isEmpty
    }

    var shouldShowJumpBackInSection: Bool {
        guard isJumpBackInSectionEnabled else { return false }
        return jumpBackInViewModel.jumpBackInList.itemsToDisplay != 0
    }

    var isRecentlySavedSectionEnabled: Bool {
        return featureFlags.isFeatureActiveForBuild(.recentlySaved)
        && homescreen.sectionsEnabled[.recentlySaved] == true
        && featureFlags.userPreferenceFor(.recentlySaved) == UserFeaturePreference.enabled
    }

    // Recently saved section can be enabled but not shown if it has no data - Data is loaded asynchronously
    var shouldShowRecentlySavedSection: Bool {
        guard isRecentlySavedSectionEnabled else { return false }
        return recentlySavedViewModel.hasData
    }

    var isHistoryHightlightsSectionEnabled: Bool {
        return featureFlags.isFeatureActiveForBuild(.historyHighlights)
        && featureFlags.userPreferenceFor(.historyHighlights) == UserFeaturePreference.enabled && !isPrivate
    }

    var shouldShowHistoryHightlightsSection: Bool {
        guard isHistoryHightlightsSectionEnabled else { return false }

        return historyHighlightsViewModel.hasData
    }

    var isPocketSectionEnabled: Bool {
        // For Pocket, the user preference check returns a user preference if it exists in
        // UserDefaults, and, if it does not, it will return a default preference based on
        // a (nimbus pocket section enabled && Pocket.isLocaleSupported) check
        guard featureFlags.isFeatureActiveForBuild(.pocket),
              featureFlags.userPreferenceFor(.pocket) == UserFeaturePreference.enabled
        else { return false }

        return true
    }

    var shouldShowPocketSection: Bool {
        guard isPocketSectionEnabled else { return false }
        return pocketViewModel.hasData
    }

    // MARK: - Initializers
    init(profile: Profile,
         isZeroSearch: Bool = false,
         isPrivate: Bool,
         experiments: NimbusApi) {
        self.profile = profile
        self.isZeroSearch = isZeroSearch
        
        self.jumpBackInViewModel = FirefoxHomeJumpBackInViewModel(isZeroSearch: isZeroSearch, profile: profile)
        self.recentlySavedViewModel = FirefoxHomeRecentlySavedViewModel(isZeroSearch: isZeroSearch, profile: profile)
        self.historyHighlightsViewModel = FxHomeHistoryHightlightsVM(with: profile)
        self.pocketViewModel = FxHomePocketViewModel(profile: profile, isZeroSearch: isZeroSearch)
        self.experiments = experiments
        self.isPrivate = isPrivate
    }
    
    // MARK: - Interfaces
    
    public func updateEnabledSections() {
        enabledSections.removeAll()

        for section in FirefoxHomeSectionType.allCases {
            switch section {
            case .logoHeader:
                if shouldShowFxLogoHeader {
                    enabledSections.append(.logoHeader)
                }
            case .topSites:
                if isTopSitesSectionEnabled && !topSitesManager.content.isEmpty {
                    enabledSections.append(.topSites)
                }
            case .pocket:
                if shouldShowPocketSection {
                    enabledSections.append(.pocket)
                }
            case .jumpBackIn:
                if shouldShowJumpBackInSection {
                    enabledSections.append(.jumpBackIn)
                }
            case .recentlySaved:
                if shouldShowRecentlySavedSection {
                    enabledSections.append(.recentlySaved)
                }
            case .historyHighlights:
                if shouldShowHistoryHightlightsSection {
                    enabledSections.append(.historyHighlights)
                }
            case .libraryShortcuts:
                if  isYourLibrarySectionEnabled {
                    enabledSections.append(.libraryShortcuts)
                }
            case .customizeHome:
                enabledSections.append(.customizeHome)
            }
        }
    }
}
