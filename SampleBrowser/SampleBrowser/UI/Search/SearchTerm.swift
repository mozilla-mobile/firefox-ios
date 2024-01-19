// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct SearchTerm {
    var baseURL = SearchDataProvider.SearchEndpoints.searchTerm.baseURL
    var searchTerm: String

    var urlWithTerm: String {
        return "\(baseURL)\(searchTerm)"
    }

    var isValidUrl: Bool {
        return searchTerm.validURL
    }

    var encodedURL: URL? {
        guard let encodedURL = urlWithTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedURL) else {
            return nil
        }
        return url
    }
}
