// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct SearchTerm {
    private var baseURL = SearchDataProvider.SearchEndpoints.searchTerm.baseURL
    var term: String

    init(term: String) {
        self.term = term
    }

    var urlWithSearchTerm: String {
        return "\(baseURL)\(term)"
    }
}
