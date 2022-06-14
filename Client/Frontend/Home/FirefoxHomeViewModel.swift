// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices

protocol FirefoxHomeViewModelDelegate: AnyObject {
    func reloadSection(section: FXHomeViewModelProtocol)
}

class FirefoxHomeViewModel: FeatureFlaggable {

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
    var shownSections = [FirefoxHomeSectionType]()
    weak var delegate: FirefoxHomeViewModelDelegate?

    // Child View models
    private var childViewModels: [FXHomeViewModelProtocol]
    var headerViewModel: FxHomeLogoHeaderViewModel
    var topSiteViewModel: FxHomeTopSitesViewModel
    var recentlySavedViewModel: FxHomeRecentlySavedViewModel
    var jumpBackInViewModel: FirefoxHomeJumpBackInViewModel
    var historyHighlightsViewModel: FxHomeHistoryHightlightsViewModel
    var pocketViewModel: FxHomePocketViewModel
    var customizeButtonViewModel: FxHomeCustomizeButtonViewModel

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
        self.recentlySavedViewModel = FxHomeRecentlySavedViewModel(
            isZeroSearch: isZeroSearch,
            profile: profile)
        self.historyHighlightsViewModel = FxHomeHistoryHightlightsViewModel(
            with: profile,
            isPrivate: isPrivate)
        self.pocketViewModel = FxHomePocketViewModel(
            isZeroSearch: isZeroSearch)
        self.customizeButtonViewModel = FxHomeCustomizeButtonViewModel()
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

    private func updateData(section: FXHomeViewModelProtocol) {
        section.updateData {
            // Once section has data loaded with new data, we check if it needs to show
            guard section.shouldShow else { return }

            self.delegate?.reloadSection(section: section)
        }
    }

    // MARK: - Manage sections and order

    /// Add the section if it doesn't
    func reloadSection(_ section: FXHomeViewModelProtocol, with collectionView: UICollectionView) {
        if !shownSections.contains(section.sectionType) {
            addShownSection(section: section.sectionType)
        }

        collectionView.reloadData()
    }

    func addShownSection(section: FirefoxHomeSectionType) {
        let positionToInsert = getPositionToInsert(section: section)
        if positionToInsert >= shownSections.count {
            shownSections.append(section)
        } else {
            shownSections.insert(section, at: positionToInsert)
        }
    }

    func removeShownSection(section: FirefoxHomeSectionType) {
        if let index = shownSections.firstIndex(of: section) {
            shownSections.remove(at: index)
        }
    }

    func getPositionToInsert(section: FirefoxHomeSectionType) -> Int {
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

    func getSectionViewModel(shownSection: Int) -> FXHomeViewModelProtocol? {
        let actualSectionNumber = shownSections[shownSection].rawValue
        return childViewModels[safe: actualSectionNumber]
    }
}

// MARK: - FxHomeTopSitesViewModelDelegate
extension FirefoxHomeViewModel: FxHomeTopSitesViewModelDelegate {
    func reloadTopSites() {
        updateData(section: topSiteViewModel)
    }
}
