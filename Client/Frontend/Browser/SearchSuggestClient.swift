/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Alamofire
import Foundation

let SearchSuggestClientErrorDomain = "org.mozilla.firefox.SearchSuggestClient"
let SearchSuggestClientErrorInvalidEngine = 0
let SearchSuggestClientErrorInvalidResponse = 1

class SearchSuggestClient {
    private let searchEngine: OpenSearchEngine
    private weak var request: Request?

    init(searchEngine: OpenSearchEngine) {
        self.searchEngine = searchEngine
    }

    func query(query: String, callback: (response: [String]?, error: NSError?) -> ()) {
        let url = searchEngine.suggestURLForQuery(query)
        if url == nil {
            let error = NSError(domain: SearchSuggestClientErrorDomain, code: SearchSuggestClientErrorInvalidEngine, userInfo: nil)
            callback(response: nil, error: error)
            return
        }

        request = Alamofire.request(.GET, url!)
            .validate(statusCode: 200..<300)
            .responseJSON { (_, _, data, err) in
                if err != nil {
                    callback(response: nil, error: err)
                    return
                }

                // The response will be of the following format:
                //    ["foobar",["foobar","foobar2000 mac","foobar skins",...]]
                // That is, an array of at least two elements: the search term and an array of suggestions.
                let array = data as? NSArray
                if array == nil || array?.count < 2 {
                    let error = NSError(domain: SearchSuggestClientErrorDomain, code: SearchSuggestClientErrorInvalidResponse, userInfo: nil)
                    callback(response: nil, error: error)
                    return
                }

                let suggestions = array![1] as? [String]
                if suggestions == nil {
                    let error = NSError(domain: SearchSuggestClientErrorDomain, code: SearchSuggestClientErrorInvalidResponse, userInfo: nil)
                    callback(response: nil, error: error)
                    return
                }

                callback(response: suggestions!, error: nil)
        }
    }

    func cancelPendingRequest() {
        request?.cancel()
    }
}
