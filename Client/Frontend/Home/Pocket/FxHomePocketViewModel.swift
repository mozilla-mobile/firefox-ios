// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import Shared

class FxHomePocketViewModel {

    // MARK: - Properties

    private let pocketAPI: Pocket
    private let pocketSponsoredAPI: PocketSponsoredStoriesProviderInterface

    private let isZeroSearch: Bool
    private var hasSentPocketSectionEvent = false

    var onTapTileAction: ((URL) -> Void)?
    var onLongPressTileAction: ((Site, UIView?) -> Void)?
    var onScroll: (([UICollectionViewCell]) -> Void)?

    private(set) var pocketStoriesViewModels: [FxPocketHomeHorizontalCellViewModel] = []

    init(pocketAPI: Pocket, pocketSponsoredAPI: PocketSponsoredStoriesProviderInterface, isZeroSearch: Bool) {
        self.isZeroSearch = isZeroSearch
        self.pocketAPI = pocketAPI
        self.pocketSponsoredAPI = pocketSponsoredAPI
    }

    private func bind(pocketStoryViewModel: FxPocketHomeHorizontalCellViewModel) {
        pocketStoryViewModel.onTap = { [weak self] indexPath in
            self?.recordTapOnStory(index: indexPath.row)
            let siteUrl = self?.pocketStoriesViewModels[indexPath.row].url
            siteUrl.map { self?.onTapTileAction?($0) }
        }

        pocketStoriesViewModels.append(pocketStoryViewModel)
    }

    // The dimension of a cell
    // Fractions for iPhone to only show a slight portion of the next column
    static var widthDimension: NSCollectionLayoutDimension {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .absolute(FxHomeHorizontalCellUX.cellWidth) // iPad
        } else if UIWindow.isLandscape {
            return .fractionalWidth(FxHomePocketCollectionCellUX.fractionalWidthiPhoneLanscape)
        } else {
            return .fractionalWidth(FxHomePocketCollectionCellUX.fractionalWidthiPhonePortrait)
        }
    }

    var numberOfCells: Int {
        return pocketStoriesViewModels.count != 0 ? pocketStoriesViewModels.count + 1 : 0
    }

    func isStoryCell(index: Int) -> Bool {
        return index < pocketStoriesViewModels.count
    }

    func getSitesDetail(for index: Int) -> Site {
        if isStoryCell(index: index) {
            return Site(url: pocketStoriesViewModels[index].url?.absoluteString ?? "", title: pocketStoriesViewModels[index].title)
        } else {
            return Site(url: Pocket.MoreStoriesURL.absoluteString, title: .FirefoxHomepage.Pocket.DiscoverMore)
        }
    }

    // MARK: - Telemetry

    func recordSectionHasShown() {
        if !hasSentPocketSectionEvent {
            TelemetryWrapper.recordEvent(category: .action, method: .view, object: .pocketSectionImpression, value: nil, extras: nil)
            hasSentPocketSectionEvent = true
        }
    }

    func recordTapOnStory(index: Int) {
        // Pocket site extra
        let key = TelemetryWrapper.EventExtraKey.pocketTilePosition.rawValue
        let siteExtra = [key: "\(index)"]

        // Origin extra
        let originExtra = TelemetryWrapper.getOriginExtras(isZeroSearch: isZeroSearch)
        let extras = originExtra.merge(with: siteExtra)

        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .pocketStory, value: nil, extras: extras)
    }

    // MARK: - Private

    // MARK: - TODO: Use settings toggle to determine if we show sponsored stories
    var showSponsors = true

    private func insert(sponsored: inout [PocketStory], into globalFeed: inout [PocketStory], indexes: [Int]) {
        for index in indexes {
            // Making sure we insert a sponsored story at a valid index
            let normalisedIndex = min(index, globalFeed.endIndex)
            if let first = sponsored.first {
                globalFeed.insert(first, at: normalisedIndex)
                sponsored.removeAll(where: { $0 == first })
            }
        }
    }

    private func updatePocketSites() async {
        do {
            let global = try await pocketAPI.globalFeed(items: FxHomePocketCollectionCellUX.numberOfItemsInSection)

            // Convert global feed to PocketStory
            var globalTemp = global.map(PocketStory.init)
            let sponsored = try await pocketSponsoredAPI.fetchSponsoredStories()

            if showSponsors {
                // Convert sponsored feed to PocketStory, take the desired number of sponsored stories
                var sponsoredTemp = Array(sponsored.map(PocketStory.init).prefix(FxHomePocketCollectionCellUX.numberOfSponsoredItemsInSection))
                self.insert(
                    sponsored: &sponsoredTemp,
                    into: &globalTemp,
                    indexes: [FxHomePocketCollectionCellUX.indexOfFirstSponsoredItem, FxHomePocketCollectionCellUX.indexOfSecondSponsoredItem]
                )
            }

            // Add the story in the view models list
            for story in globalTemp {
                self.bind(pocketStoryViewModel: .init(story: story))
            }
        } catch { }
    }

    func showDiscoverMore() {
        onTapTileAction?(Pocket.MoreStoriesURL)
    }
}

// MARK: FXHomeViewModelProtocol
extension FxHomePocketViewModel: FXHomeViewModelProtocol, FeatureFlaggable {

    var sectionType: FirefoxHomeSectionType {
        return .pocket
    }

    var isEnabled: Bool {
        // For Pocket, the user preference check returns a user preference if it exists in
        // UserDefaults, and, if it does not, it will return a default preference based on
        // a (nimbus pocket section enabled && Pocket.isLocaleSupported) check
        guard featureFlags.isFeatureEnabled(.pocket, checking: .buildAndUser) else { return false }

        return true
    }

    var hasData: Bool {
        return !pocketStoriesViewModels.isEmpty
    }

    func updateData(completion: @escaping () -> Void) {
        Task {
            await updatePocketSites()
            completion()
        }
    }

    var shouldReloadSection: Bool { return true }
}
