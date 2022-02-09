// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import Shared

class FxHomePocketViewModel {

    // MARK: - Properties

    private let profile: Profile
    private let pocketAPI = Pocket()

    private let isZeroSearch: Bool
    private var hasSentPocketSectionEvent = false

    var onTapTileAction: ((URL) -> Void)? = nil
    var onLongPressTileAction: ((IndexPath) -> Void)? = nil
    // Need to save the parent's section for the long press action
    // since it's currently handled in FirefoxHomeViewController
    // TODO: Each section should handle the long press details - not the parent
    var pocketShownInSection: Int = 0

    init(profile: Profile, isZeroSearch: Bool) {
        self.profile = profile
        self.isZeroSearch = isZeroSearch
    }

    var pocketStories: [PocketStory] = []
    var hasData: Bool {
        return !pocketStories.isEmpty
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
        return pocketStories.count != 0 ? pocketStories.count + 1 : 0
    }

    static var numberOfItemsInColumn: CGFloat {
        return 3
    }

    func isStoryCell(index: Int) -> Bool {
        return index < pocketStories.count
    }

    func updateData(completion: @escaping () -> Void) {
        getPocketSites().uponQueue(.main) { _ in
            completion()
        }
    }

    func getSitesDetail(for index: Int) -> Site {
        if isStoryCell(index: index) {
            return Site(url: pocketStories[index].url.absoluteString, title: pocketStories[index].title)
        } else {
            return Site(url: Pocket.MoreStoriesURL.absoluteString, title: .PocketMoreStoriesText)
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
        let siteExtra = [key : "\(index)"]

        // Origin extra
        let originExtra = TelemetryWrapper.getOriginExtras(isZeroSearch: isZeroSearch)
        let extras = originExtra.merge(with: siteExtra)

        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .pocketStory, value: nil, extras: extras)
    }

    // MARK: - Private

    private func getPocketSites() -> Success {
        return pocketAPI.globalFeed(items: FxHomePocketCollectionCellUX.numberOfItemsInSection).bindQueue(.main) { pocketStory in
            self.pocketStories = pocketStory
            return succeed()
        }
    }
}
