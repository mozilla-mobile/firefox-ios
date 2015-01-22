/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Alamofire
import Foundation
import UIKit

let SearchSuggestClientErrorDomain = "org.mozilla.firefox.SearchSuggestClient"
let SearchSuggestClientErrorInvalidEngine = 0
let SearchSuggestClientErrorInvalidResponse = 1

enum SearchStatus {
    case None
    case Searching
    case Error
}

class SearchSuggestClient<T> : ArrayCursor<String> {
    private let searchEngine: OpenSearchEngine?
    private weak var request: Request?
    var maxResults = -1

    init(searchEngine: OpenSearchEngine? = nil, factory: ((Any) -> Any?)? = nil) {
        self.searchEngine = searchEngine
        super.init(data: [String](), factory: factory)
    }

    func clear(err: NSError? = nil) {
        setData([String]())
        if let err = err {
            status = .Failure
            statusMessage = err.description
        } else {
            status = .Success
            statusMessage = ""
        }
    }

    func cancelPendingRequest() {
        if let req = request {
            req.cancel()
        }
    }

    func query(filter: String, callback: ()->Void) {
        if let searchEngine = searchEngine {
            let url = searchEngine.suggestURLForQuery(filter)
            if url == nil {
                let error = NSError(domain: SearchSuggestClientErrorDomain, code: SearchSuggestClientErrorInvalidEngine, userInfo: [NSLocalizedDescriptionKey: "Invalid engine"])
                clear(err: error)
                callback()
                return
            }

            request = Alamofire.request(.GET, url!)
                .validate(statusCode: 200..<300)
                .responseJSON { (_, _, data, err) in
                    if let err = err {
                        self.clear(err: err)
                        callback()
                        return
                    }

                    // The response will be of the following format:
                    //    ["foobar",["foobar","foobar2000 mac","foobar skins",...]]
                    // That is, an array of at least two elements: the search term and an array of suggestions.
                    let array = data as? NSArray
                    if array == nil || array?.count < 2 {
                        let error = NSError(domain: SearchSuggestClientErrorDomain, code: SearchSuggestClientErrorInvalidResponse, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                        self.clear(err: error)
                        callback()
                        return
                    }

                    if var suggestions = array![1] as? [String] {
                        self.status = .Success
                        // If we got more than maxCount suggestions, clip the list
                        if self.maxResults > -1 && suggestions.count > self.maxResults {
                            suggestions.removeRange(self.maxResults..<suggestions.count)
                        }
                        self.setData(suggestions)
                        self.statusMessage = ""
                        callback()
                    } else {
                        let error = NSError(domain: SearchSuggestClientErrorDomain, code: SearchSuggestClientErrorInvalidResponse, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                        self.clear(err: error)
                        callback()
                    }
            }
        } else {
            self.clear()
            self.statusMessage = "No search engine"
            callback()
        }
    }
}