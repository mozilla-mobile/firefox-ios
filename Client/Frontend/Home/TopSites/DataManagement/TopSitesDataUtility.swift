// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

protocol TopSitesDataUtilityInterface {
    func removeSiteMatchingSites(in searchEngine: OpenSearchEngine?, from sites: [Site]) -> [Site]
}

struct TopSitesDataUtility: TopSitesDataUtilityInterface {
    func removeSiteMatchingSites(in searchEngine: OpenSearchEngine?, from sites: [Site]) -> [Site] {
        guard let defaultSearchEngine = searchEngine else { return sites }

        let filteredSites = sites.filter {
            guard let secondLevelDomain = $0.secondLevelDomain else { return false }
            let hasMatchedEngine = defaultSearchEngine.shortName.localizedCaseInsensitiveContains(secondLevelDomain)

            return !hasMatchedEngine
        }

        return filteredSites
    }
}
