// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices

protocol FirefoxHomeViewModelDelegate: AnyObject {
    func reloadSection(index: Int?)
}

class FirefoxHomeViewModel: FeatureFlagsProtocol {

    struct UX {
        static let topSitesHeight: CGFloat = 90
        static let homeHorizontalCellHeight: CGFloat = 120
        static let recentlySavedCellHeight: CGFloat = 136
        static let historyHighlightsCellHeight: CGFloat = 68
        static let sectionInsetsForSizeClass = UXSizeClasses(compact: 0, regular: 101, other: 15)
        static let spacingBetweenSections: CGFloat = 24
        static let sectionInsetsForIpad: CGFloat = 101
        static let minimumInsets: CGFloat = 15
        static let libraryShortcutsHeight: CGFloat = 90
        static let libraryShortcutsMaxWidth: CGFloat = 375
        static let customizeHomeHeight: CGFloat = 100
        static let logoHeaderHeight: CGFloat = 85
    }

    // MARK: - Properties

    // Privacy of home page is controlled throught notifications since tab manager selected tab
    // isn't always the proper privacy mode that should be reflected on the home page
    var isPrivate: Bool {
        didSet {
            childViewModels.forEach {
                $0.updatePrivacyConcernedSection(isPrivate: isPrivate)
            }
        }
    }

    let nimbus: FxNimbus
    let profile: Profile
    var isZeroSearch: Bool
    var enabledSections = [FirefoxHomeSectionType]()
    weak var delegate: FirefoxHomeViewModelDelegate?

    // Child View models
    private var childViewModels: [FXHomeViewModelProtocol]
    var headerViewModel: FxHomeLogoHeaderViewModel
    var topSiteViewModel: FxHomeTopSitesViewModel
    var recentlySavedViewModel: FirefoxHomeRecentlySavedViewModel
    var jumpBackInViewModel: FirefoxHomeJumpBackInViewModel
    var historyHighlightsViewModel: FxHomeHistoryHightlightsViewModel
    var pocketViewModel: FxHomePocketViewModel

    // MARK: - Section availability variables

    var isYourLibrarySectionEnabled: Bool {
        UIDevice.current.userInterfaceIdiom != .pad && featureFlags.isFeatureActiveForNimbus(.librarySection)
    }

    // MARK: - Initializers
    init(profile: Profile,
         isZeroSearch: Bool = false,
         isPrivate: Bool,
         nimbus: FxNimbus = FxNimbus.shared) {
        self.profile = profile
        self.isZeroSearch = isZeroSearch

        self.headerViewModel = FxHomeLogoHeaderViewModel(profile: profile)
        self.topSiteViewModel = FxHomeTopSitesViewModel(
            profile: profile,
            isZeroSearch: isZeroSearch)
        self.jumpBackInViewModel = FirefoxHomeJumpBackInViewModel(
            isZeroSearch: isZeroSearch,
            profile: profile,
            isPrivate: isPrivate)
        self.recentlySavedViewModel = FirefoxHomeRecentlySavedViewModel(
            isZeroSearch: isZeroSearch,
            profile: profile)
        self.historyHighlightsViewModel = FxHomeHistoryHightlightsViewModel(
            with: profile,
            isPrivate: isPrivate)
        self.pocketViewModel = FxHomePocketViewModel(
            profile: profile,
            isZeroSearch: isZeroSearch)
        self.childViewModels = [headerViewModel,
                                topSiteViewModel,
                                jumpBackInViewModel,
                                recentlySavedViewModel,
                                historyHighlightsViewModel,
                                pocketViewModel]
        self.isPrivate = isPrivate

        self.nimbus = nimbus
        topSiteViewModel.delegate = self
    }

    // MARK: - Interfaces

    func updateData() {
        childViewModels.forEach { section in
            guard section.isEnabled else { return }
            self.update(section: section)
        }
    }

    func updateEnabledSections() {
        enabledSections.removeAll()

        childViewModels.forEach {
            if $0.shouldShow { enabledSections.append($0.sectionType) }
        }

        // Sections that have no view model yet
        // please remove when they have a view model and comform to FXHomeViewModelProtocol
        for section in FirefoxHomeSectionType.allCases {
            switch section {
            case .libraryShortcuts:
                if isYourLibrarySectionEnabled {
                    enabledSections.append(.libraryShortcuts)
                }
            case .customizeHome:
                enabledSections.append(.customizeHome)
            default:
                break
            }
        }
    }

    private func update(section: FXHomeViewModelProtocol) {
        section.updateData {
            guard section.shouldReloadSection else { return }
            let index = self.enabledSections.firstIndex(of: section.sectionType)
            self.delegate?.reloadSection(index: index)
        }
    }
}

extension FirefoxHomeViewModel: FxHomeTopSitesViewModelDelegate {
    func reloadTopSites() {
        update(section: topSiteViewModel)
    }
}
