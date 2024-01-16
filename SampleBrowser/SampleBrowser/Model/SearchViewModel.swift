// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class SearchViewModel {
    var searchModel: SearchModel?
    let dataProvider: SearchDataProviderProtocol

    init(dataProvider: SearchDataProviderProtocol = SearchDataProvider()) {
        self.dataProvider = dataProvider
    }

    var searchBarViewModel: SearchBarViewModel {
        return SearchBarViewModel(placeholder: "Search")
    }

    func requestSearch(searchTerm: String, completion: @escaping (BrowserError?) -> Void) {
        searchModel?.searchTerm = searchTerm

        dataProvider.getSearchResults(text: searchTerm) { result, error in
            self.searchModel = result
            completion(error)
        }
    }

    func resetSearch() {
        searchModel?.suggestions.removeAll()
    }
}
