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

    public func delete(_ sites: [String]) {
        deleteFromHistory(sites)
        deleteMetadata(sites)
    }

    private func deleteFromHistory(_ sites: [String]) {
        sites.forEach { site in
            profile.history.removeHistoryForURL(site)
        }
    }

    private func deleteMetadata(_ sites: [String]) {
        sites.forEach { site in
            let metadataKey = HistoryMetadataKey(url: site,
                                                 searchTerm: nil,
                                                 referrerUrl: nil)
            _ = profile.places.deleteHistoryMetadata(key: metadataKey)
        }
    }
}
