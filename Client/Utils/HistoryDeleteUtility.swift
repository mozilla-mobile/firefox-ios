// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

class HistoryDeleteUtility {

    private var profile: Profile

    init(with profile: Profile) {
        self.profile = profile
    }

    public func delete(_ sites: [URL]) {
        deleteFromProfile(sites)
        deleteMetadata(sites)
    }

    private func deleteFromProfile(_ sites: [URL]) {
        sites.forEach { site in
            profile.history.removeHistoryForURL(site.absoluteString)
        }
    }

    private func deleteMetadata(_ sites: [URL]) {
        sites.forEach { site in
            let metadataKey = HistoryMetadataKey(url: site.absoluteString,
                                                 searchTerm: nil,
                                                 referrerUrl: nil)
            _ = profile.places.deleteHistoryMetadata(key: metadataKey)
        }
    }
}
