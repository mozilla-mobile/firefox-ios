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
    private var hasSentPocketSectionEvent = false

    var onTapPocketTileAction: ((PocketStory) -> Void)? = nil
    var showMorePocketAction: (() -> Void)? = nil

    init(profile: Profile) {
        self.profile = profile
    }

    var pocketStories: [PocketStory] = []
    var hasData: Bool {
        return !pocketStories.isEmpty
    }

    // The dimension of a cell
    // Fractions for iPhone to only show a slight portion of the next column
    static var widthDimension: NSCollectionLayoutDimension {
        if deviceIsiPad {
            return .absolute(FxHomeHorizontalCellUX.cellWidth) // iPad
        } else if deviceIsInLandscapeMode {
            return .fractionalWidth(7/15) // iPhone in landscape
        } else {
            return .fractionalWidth(29/30) // iPhone in portrait
        }
    }

    var numberOfCells: Int {
        return pocketStories.count != 0 ? pocketStories.count + 1 : 0
    }

    func updateData(completion: @escaping () -> Void) {
        getPocketSites().uponQueue(.main) { _ in
            completion()
        }
    }

    // TODO: Laurie - Call this when section is shown
    func recordSectionHasShown() {
        if !hasSentPocketSectionEvent {
            TelemetryWrapper.recordEvent(category: .action, method: .view, object: .pocketSectionImpression, value: nil, extras: nil)
            hasSentPocketSectionEvent = true
        }
    }

    func getSitesDetail(for index: Int) -> Site {
        return Site(url: pocketStories[index].url.absoluteString, title: pocketStories[index].title)
    }

    // MARK: - Private

    private func getPocketSites() -> Success {
        return pocketAPI.globalFeed(items: FxHomePocketCollectionCellUX.numberOfItemsInSection).bindQueue(.main) { pocketStory in
            self.pocketStories = pocketStory
            return succeed()
        }
    }

    private static var deviceIsiPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private static var deviceIsInLandscapeMode: Bool {
        UIWindow.isLandscape
    }
}
