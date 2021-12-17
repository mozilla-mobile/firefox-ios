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

    var showMorePocketAction: (() -> Void)? = nil

    init(profile: Profile) {
        self.profile = profile
    }

    var pocketStories: [PocketStory] = []
    var hasData: Bool {
        return !pocketStories.isEmpty
    }

    func updateData(completion: @escaping () -> Void) {
        getPocketSites().uponQueue(.main) { _ in
//       Laurie - self.collectionView?.reloadData()
            completion()
        }
    }

    func getPocketSites() -> Success {
        return pocketAPI.globalFeed(items: 11).bindQueue(.main) { pocketStory in
            self.pocketStories = pocketStory
            return succeed()
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
}
