// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol SearchDataProviderProtocol: AnyObject {
    var searchModel: SearchModel? { get set }
    var error: BrowserError? { get set }
    func getSearchResults(text: String, completion: @escaping (SearchModel?, BrowserError?) -> Void)
}

extension SearchDataProviderProtocol {
    func updateResults(data: Data) {
        var response: [Any]?

        do {
            response = try JSONSerialization.jsonObject(with: data, options: []) as? [Any]
        } catch let parseError as NSError {
            error = BrowserError.jsonSerialization(parseError.localizedDescription)
            return
        }

        guard let response = response, !response.isEmpty else {
            error = BrowserError.emptyResponse
            return
        }

        guard let searchTerm = response[0] as? String,
              let suggestion = response[1] as? [String] else {
            error = BrowserError.suggestionsNotAvailable
            return
        }

        searchModel = SearchModel(searchTerm: searchTerm, suggestions: suggestion)
    }
}
