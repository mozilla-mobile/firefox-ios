// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Core

protocol HomepageViewModelDelegate: AnyObject {
    func reloadView()
}

protocol HomepageDataModelDelegate: AnyObject {
    func reloadView()
}

class HomepageViewModel: FeatureFlaggable, NTPLayoutHighlightDataSource {

    struct UX {
        static let spacingBetweenSections: CGFloat = 32
        static let standardInset: CGFloat = 18
        static let iPadInset: CGFloat = 50
        static let iPadTopSiteInset: CGFloat = 25

        static func leadingInset(traitCollection: UITraitCollection) -> CGFloat {
            guard UIDevice.current.userInterfaceIdiom != .phone else { return standardInset }

            // Handles multitasking on iPad
            return traitCollection.horizontalSizeClass == .regular ? iPadInset : standardInset
        }

        static func topSiteLeadingInset(traitCollection: UITraitCollection) -> CGFloat {
            guard UIDevice.current.userInterfaceIdiom != .phone else { return 0 }

            // Handles multitasking on iPad
            return traitCollection.horizontalSizeClass == .regular ? iPadTopSiteInset : 0
        }
    }

    // MARK: - Properties

    // Privacy of home page is controlled through notifications since tab manager selected tab
    // isn't always the proper privacy mode that should be reflected on the home page
    var isPrivate: Bool {
        didSet {
            childViewModels.forEach {
                $0.updatePrivacyConcernedSection(isPrivate: isPrivate)
            }
        }
    }

    //Ecosia: let nimbus: FxNimbus
    let profile: Profile
    fileprivate let personalCounter = PersonalCounter()

    var isZeroSearch: Bool {
        didSet {
            topSiteViewModel.isZeroSearch = isZeroSearch
            // Ecosia // jumpBackInViewModel.isZeroSearch = isZeroSearch
            // Ecosia // recentlySavedViewModel.isZeroSearch = isZeroSearch
            // Ecosia // pocketViewModel.isZeroSearch = isZeroSearch
        }
    }

    /// Record view appeared is sent multiple times, this avoids recording telemetry multiple times for one appearance
    private var viewAppeared: Bool = false

    var shownSections = [HomepageSectionType]()
    weak var delegate: HomepageViewModelDelegate?

    // Child View models
    private var childViewModels: [HomepageViewModelProtocol]
    var headerViewModel: HomeLogoHeaderViewModel
    var libraryViewModel: NTPLibraryViewModel
    var topSiteViewModel: TopSitesViewModel
    var impactViewModel: NTPImpactViewModel
    var newsViewModel: NTPNewsViewModel

    var shouldDisplayHomeTabBanner: Bool {
        return false // Ecoaia: return messageCardViewModel.shouldDisplayMessageCard
    }

    // MARK: - Initializers
    init(profile: Profile,
         isPrivate: Bool,
         tabManager: TabManagerProtocol,
         urlBar: URLBarViewProtocol,
         //Ecosia: remove experiments // nimbus: FxNimbus = FxNimbus.shared,
         isZeroSearch: Bool = false) {
        self.profile = profile
        self.isZeroSearch = isZeroSearch

        self.headerViewModel = .init()
        self.libraryViewModel = NTPLibraryViewModel()
        self.topSiteViewModel = TopSitesViewModel(profile: profile)
        self.impactViewModel = NTPImpactViewModel(personalCounter: personalCounter)
        self.newsViewModel = NTPNewsViewModel()
        self.childViewModels = [headerViewModel,
                                libraryViewModel,
                                topSiteViewModel,
                                impactViewModel,
                                newsViewModel]
        self.isPrivate = isPrivate
        topSiteViewModel.delegate = self
        newsViewModel.delegate = self
        updateEnabledSections()
    }

    // MARK: - Interfaces

    func recordViewAppeared() {
        guard !viewAppeared else { return }

        viewAppeared = true

        if NTPTooltip.highlight(for: .shared) == .referralSpotlight {
            Analytics.shared.showInvitePromo()
        }

        impactViewModel.startCounter()
    }

    func recordViewDisappeared() {
        viewAppeared = false
        impactViewModel.stopCounter()
    }

    // MARK: - Manage sections

    func updateEnabledSections() {
        shownSections.removeAll()

        childViewModels.forEach {
            if $0.shouldShow { shownSections.append($0.sectionType) }
        }
    }

    func refreshData(for traitCollection: UITraitCollection) {
        updateEnabledSections()
        childViewModels.forEach {
            $0.refreshData(for: traitCollection)
        }
    }

    // MARK: - Section ViewModel helper

    func getSectionViewModel(shownSection: Int) -> HomepageViewModelProtocol? {
        guard let actualSectionNumber = shownSections[safe: shownSection]?.rawValue else { return nil }
        return childViewModels[safe: actualSectionNumber]
    }

    func ntpLayoutHighlightText() -> String? {
        return NTPTooltip.highlight(for: User.shared)?.text
    }

}

// MARK: - HomepageDataModelDelegate
extension HomepageViewModel: HomepageDataModelDelegate {
    func reloadView() {
        delegate?.reloadView()
    }
}
