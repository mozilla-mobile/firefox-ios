/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Alamofire
import Foundation
import Shared

let SearchSuggestClientErrorDomain = "org.mozilla.firefox.SearchSuggestClient"
let SearchSuggestClientErrorInvalidEngine = 0
let SearchSuggestClientErrorInvalidResponse = 1

/*
 * Clients of SearchSuggestionClient should retain the object during the
 * lifetime of the search suggestion query, as requests are canceled during destruction.
 *
 * Query callbacks that must run even if they are cancelled should wrap their contents in `withExtendendLifetime`.
 */
class SearchSuggestClient {
    private let searchEngine: OpenSearchEngine
    private weak var request: Request?
    private let userAgent: String

    lazy private var alamofire: Alamofire.Manager = {
        let configuration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        return Alamofire.Manager.managerWithUserAgent(self.userAgent, configuration: configuration)
    }()

    init(searchEngine: OpenSearchEngine, userAgent: String) {
        self.searchEngine = searchEngine
        self.userAgent = userAgent
    }

    func query(query: String, callback: (response: [String]?, error: NSError?) -> ()) {
        let url = searchEngine.suggestURLForQuery(query)
        if url == nil {
            let error = NSError(domain: SearchSuggestClientErrorDomain, code: SearchSuggestClientErrorInvalidEngine, userInfo: nil)
            callback(response: nil, error: error)
            return
        }

        request = alamofire.request(.GET, url!)
            .validate(statusCode: 200..<300)
            .responseJSON { (request, response, result) in
                if let error = result.error as? NSError {
                    callback(response: nil, error: error)
                    return
                }

                // The response will be of the following format:
                //    ["foobar",["foobar","foobar2000 mac","foobar skins",...]]
                // That is, an array of at least two elements: the search term and an array of suggestions.
                let array = result.value as? NSArray
                if array?.count ?? 0 < 2 {
                    let error = NSError(domain: SearchSuggestClientErrorDomain, code: SearchSuggestClientErrorInvalidResponse, userInfo: nil)
                    callback(response: nil, error: error)
                    return
                }

                let suggestions = array?[1] as? [String]
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
