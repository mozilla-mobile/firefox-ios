// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

protocol TopSitesDataUtilityInterface {
    func removeSiteMatching(_ engine: OpenSearchEngine?, from sites: [Site]) -> [Site]
}

struct TopSitesDataUtility: TopSitesDataUtilityInterface {
    func removeSiteMatching(_ engine: OpenSearchEngine?, from sites: [Site]) -> [Site] {
        if let defaultSearchEngine = engine {
            let filteredSites = sites.filter {
                guard let secondLevelDomain = $0.secondLevelDomain else { return false }
                let hasMatchedEngine = defaultSearchEngine.shortName.localizedCaseInsensitiveContains(secondLevelDomain)

                return !hasMatchedEngine
            }
            return filteredSites
        }

        return sites
    }
}
