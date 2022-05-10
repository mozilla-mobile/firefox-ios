// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

class HistoryDeletionUtility {

    private var profile: Profile

    init(with profile: Profile) {
        self.profile = profile
    }

    /// Deletes sites from the history and from metadata.
    ///
    /// Completion block is included for testing and should not be used otherwise.
    public func delete(_ sites: [String], completion: ((Bool) -> Void)? = nil) {
        deleteFromHistory(sites)
        deleteMetadata(sites) { result in
            completion?(result)
        }
    }

    private func deleteFromHistory(_ sites: [String]) {
        sites.forEach { profile.history.removeHistoryForURL($0) }
    }

    private func deleteMetadata(_ sites: [String], completion: ((Bool) -> Void)? = nil) {
        sites.forEach { currentSite in
            profile.places.deleteVisitsFor(url: currentSite).uponQueue(.global(qos: .userInitiated)) { result in
                guard let lastSite = sites.last,
                      lastSite == currentSite
                else { return }

                completion?(result.isSuccess)
            }
        }
    }
}
