// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices

protocol HomepageViewModelDelegate: AnyObject {
    func reloadSection(section: HomepageViewModelProtocol)
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
    var shownSections = [HomepageSectionType]()
    weak var delegate: HomepageViewModelDelegate?
    
    // Child View models
    private var childViewModels: [HomepageViewModelProtocol]
    var headerViewModel: HomeLogoHeaderViewModel
    var topSiteViewModel: TopSitesViewModel
    var recentlySavedViewModel: RecentlySavedCellViewModel
    var jumpBackInViewModel: JumpBackInViewModel
    var historyHighlightsViewModel: HistoryHightlightsViewModel
    var pocketViewModel: PocketViewModel
    var customizeButtonViewModel: CustomizeHomepageSectionViewModel
    
    // MARK: - Initializers
    init(profile: Profile,
         isZeroSearch: Bool = false,
         isPrivate: Bool,
         nimbus: FxNimbus = FxNimbus.shared) {
        self.profile = profile
        self.isZeroSearch = isZeroSearch
        
        self.headerViewModel = HomeLogoHeaderViewModel(profile: profile)
        self.topSiteViewModel = TopSitesViewModel(
            profile: profile,
            isZeroSearch: isZeroSearch)
        self.jumpBackInViewModel = JumpBackInViewModel(
            isZeroSearch: isZeroSearch,
            profile: profile,
            isPrivate: isPrivate)
        self.recentlySavedViewModel = RecentlySavedCellViewModel(
            isZeroSearch: isZeroSearch,
            profile: profile)
        self.historyHighlightsViewModel = HistoryHightlightsViewModel(
            with: profile,
            isPrivate: isPrivate)
        self.pocketViewModel = PocketViewModel(
            isZeroSearch: isZeroSearch)
        self.customizeButtonViewModel = CustomizeHomepageSectionViewModel()
        self.childViewModels = [headerViewModel,
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
        
        updateEnabledSections()
    }
    
    // MARK: - Interfaces
    
    func recordViewAppeared() {
        nimbus.features.homescreenFeature.recordExposure()
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .view,
                                     object: .firefoxHomepage,
                                     value: .fxHomepageOrigin,
                                     extras: TelemetryWrapper.getOriginExtras(isZeroSearch: isZeroSearch))
    }
    
    // MARK: - Fetch section data
    
    func updateData() {
        childViewModels.forEach { section in
            guard section.isEnabled else { return }
            self.updateData(section: section)
        }
    }
    
    private func updateData(section: HomepageViewModelProtocol) {
        section.updateData {
            self.delegate?.reloadSection(section: section)
        }
    }
    
    // MARK: - Manage sections and order
    
    /// Add the section if it doesn't
    func reloadSection(_ section: HomepageViewModelProtocol, with collectionView: UICollectionView) {
        if !shownSections.contains(section.sectionType) {
            addShownSection(section: section.sectionType)
        }
        
        collectionView.reloadData()
    }
    
    func addShownSection(section: HomepageSectionType) {
        let positionToInsert = getPositionToInsert(section: section)
        if positionToInsert >= shownSections.count {
            shownSections.append(section)
        } else {
            shownSections.insert(section, at: positionToInsert)
        }
    }
    
    func removeShownSection(section: HomepageSectionType) {
        if let index = shownSections.firstIndex(of: section) {
            shownSections.remove(at: index)
        }
    }
    
    func getPositionToInsert(section: HomepageSectionType) -> Int {
        let indexes = shownSections.filter { $0.rawValue < section.rawValue }
        return indexes.count
    }
    
    func updateEnabledSections() {
        shownSections.removeAll()
        
        childViewModels.forEach {
            if $0.shouldShow { shownSections.append($0.sectionType) }
        }
    }
    
    // MARK: - Section ViewModel helper
    
    func getSectionViewModel(shownSection: Int) -> HomepageViewModelProtocol? {
        guard let actualSectionNumber = shownSections[safe: shownSection]?.rawValue else { return nil }
        return childViewModels[safe: actualSectionNumber]
    }
}

// MARK: - FxHomeTopSitesViewModelDelegate
extension HomepageViewModel: TopSitesViewModelDelegate {
    func reloadTopSites() {
        updateData(section: topSiteViewModel)
    }
}

extension HomepageViewModel: HomeHistoryHighlightsDelegate {
    func reloadHighlights() {
        updateData(section: historyHighlightsViewModel)
    }
}
