// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

protocol SponsoredTileDataUtilityInterface {
    func shouldAdd(site: Site, with searchEngine: OpenSearchEngine?) -> Bool
}

struct SponsoredTileDataUtility: SponsoredTileDataUtilityInterface {
    func shouldAdd(site: Site, with searchEngine: OpenSearchEngine?) -> Bool {
        guard let defaultSearchEngine = searchEngine,
              let secondLevelDomain = site.secondLevelDomain else { return true }

        let hasMatchedEngine = defaultSearchEngine.shortName.localizedCaseInsensitiveContains(secondLevelDomain)
        return !hasMatchedEngine
    }
}
