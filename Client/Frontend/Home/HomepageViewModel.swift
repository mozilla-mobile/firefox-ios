// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices

protocol HomepageViewModelDelegate: AnyObject {
    func reloadView()
}

protocol HomepageDataModelDelegate: AnyObject {
    func reloadView()
}

class HomepageViewModel: FeatureFlaggable {

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

    let nimbus: FxNimbus
    let profile: Profile
    var isZeroSearch: Bool {
        didSet {
            topSiteViewModel.isZeroSearch = isZeroSearch
            jumpBackInViewModel.isZeroSearch = isZeroSearch
            recentlySavedViewModel.isZeroSearch = isZeroSearch
            pocketViewModel.isZeroSearch = isZeroSearch
        }
    }

    /// Record view appeared is sent multiple times, this avoids recording telemetry multiple times for one appearance
    private var viewAppeared: Bool = false

    var shownSections = [HomepageSectionType]()
    weak var delegate: HomepageViewModelDelegate?
    private var wallpaperManager: WallpaperManager

    // Child View models
    private var childViewModels: [HomepageViewModelProtocol]
    var headerViewModel: HomeLogoHeaderViewModel
    var messageCardViewModel: HomepageMessageCardViewModel
    var topSiteViewModel: TopSitesViewModel
    var recentlySavedViewModel: RecentlySavedViewModel
    var jumpBackInViewModel: JumpBackInViewModel
    var historyHighlightsViewModel: HistoryHighlightsViewModel
    var pocketViewModel: PocketViewModel
    var customizeButtonViewModel: CustomizeHomepageSectionViewModel

    var shouldDisplayHomeTabBanner: Bool {
        return messageCardViewModel.shouldDisplayMessageCard
    }

    // MARK: - Initializers
    init(profile: Profile,
         isPrivate: Bool,
         tabManager: TabManagerProtocol,
         urlBar: URLBarViewProtocol,
         nimbus: FxNimbus = FxNimbus.shared,
         isZeroSearch: Bool = false,
         wallpaperManager: WallpaperManager = WallpaperManager()) {
        self.profile = profile
        self.isZeroSearch = isZeroSearch

        self.headerViewModel = HomeLogoHeaderViewModel(profile: profile)
        let messageCardAdaptor = MessageCardDataAdaptorImplementation()
        self.messageCardViewModel = HomepageMessageCardViewModel(dataAdaptor: messageCardAdaptor)
        messageCardAdaptor.delegate = messageCardViewModel
        self.topSiteViewModel = TopSitesViewModel(profile: profile, wallpaperManager: wallpaperManager)
        self.wallpaperManager = wallpaperManager

        let adaptor = JumpBackInDataAdaptorImplementation(profile: profile,
                                                          tabManager: tabManager)
        self.jumpBackInViewModel = JumpBackInViewModel(
            profile: profile,
            isPrivate: isPrivate,
            tabManager: tabManager,
            adaptor: adaptor,
            wallpaperManager: wallpaperManager)
        adaptor.delegate = jumpBackInViewModel

        self.recentlySavedViewModel = RecentlySavedViewModel(profile: profile, wallpaperManager: wallpaperManager)
        let deletionUtility = HistoryDeletionUtility(with: profile)
        let historyDataAdaptor = HistoryHighlightsDataAdaptorImplementation(
            profile: profile,
            tabManager: tabManager,
            deletionUtility: deletionUtility)
        self.historyHighlightsViewModel = HistoryHighlightsViewModel(
            with: profile,
            isPrivate: isPrivate,
            urlBar: urlBar,
            historyHighlightsDataAdaptor: historyDataAdaptor,
            wallpaperManager: wallpaperManager)

        let pocketDataAdaptor = PocketDataAdaptorImplementation(
            pocketAPI: PocketProvider(),
            pocketSponsoredAPI: MockPocketSponsoredStoriesProvider())
        self.pocketViewModel = PocketViewModel(pocketDataAdaptor: pocketDataAdaptor,
                                               wallpaperManager: wallpaperManager)
        pocketDataAdaptor.delegate = pocketViewModel

        self.customizeButtonViewModel = CustomizeHomepageSectionViewModel()
        self.childViewModels = [headerViewModel,
                                messageCardViewModel,
                                topSiteViewModel,
                                jumpBackInViewModel,
                                recentlySavedViewModel,
                                historyHighlightsViewModel,
                                pocketViewModel,
                                customizeButtonViewModel]
        self.isPrivate = isPrivate

        self.nimbus = nimbus
        topSiteViewModel.delegate = self
        historyHighlightsViewModel.delegate = self
        recentlySavedViewModel.delegate = self
        pocketViewModel.delegate = self
        jumpBackInViewModel.delegate = self
        messageCardViewModel.delegate = self

        updateEnabledSections()
    }

    // MARK: - Interfaces

    func recordViewAppeared() {
        guard !viewAppeared else { return }

        viewAppeared = true
        nimbus.features.homescreenFeature.recordExposure()
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .view,
                                     object: .firefoxHomepage,
                                     value: .fxHomepageOrigin,
                                     extras: TelemetryWrapper.getOriginExtras(isZeroSearch: isZeroSearch))

        // Firefox home page tracking i.e. being shown from awesomebar vs bottom right hamburger menu
        let trackingValue: TelemetryWrapper.EventValue = isZeroSearch
        ? .openHomeFromAwesomebar : .openHomeFromPhotonMenuButton
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .open,
                                     object: .firefoxHomepage,
                                     value: trackingValue,
                                     extras: nil)
        childViewModels.forEach { $0.screenWasShown() }
    }

    func recordViewDisappeared() {
        viewAppeared = false
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
}

// MARK: - HomepageDataModelDelegate
extension HomepageViewModel: HomepageDataModelDelegate {
    func reloadView() {
        delegate?.reloadView()
    }
}
