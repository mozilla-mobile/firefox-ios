// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

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
    fileprivate let searchEngine: OpenSearchEngine
    fileprivate let userAgent: String
    fileprivate var task: URLSessionTask?

    fileprivate lazy var urlSession: URLSession = makeURLSession(
        userAgent: self.userAgent,
        configuration: URLSessionConfiguration.ephemeralMPTCP
    )

    init(searchEngine: OpenSearchEngine, userAgent: String) {
        self.searchEngine = searchEngine
        self.userAgent = userAgent
    }

    func query(
        _ query: String,
        callback: @escaping (_ response: [String]?, _ error: NSError?) -> Void
    ) {
        let url = searchEngine.suggestURLForQuery(query)
        if url == nil {
            let error = NSError(
                domain: SearchSuggestClientErrorDomain,
                code: SearchSuggestClientErrorInvalidEngine,
                userInfo: nil
            )
            callback(nil, error)
            return
        }

        task = urlSession.dataTask(with: url!) { (data, response, error) in
            if let error = error {
                callback(nil, error as NSError?)
                return
            }

            guard let data = data,
                  validatedHTTPResponse(response, statusCode: 200..<300) != nil
            else {
                self.handleInvalidResponseError(callback: callback)
                return
            }

            let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            let array = json as? [Any]

            // The response will be of the following format:
            //    ["foobar",["foobar","foobar2000 mac","foobar skins",...]]
            // That is, an array of at least two elements: the search term and an array of suggestions.

            if array?.count ?? 0 < 2 {
                self.handleInvalidResponseError(callback: callback)
                return
            }

            guard let suggestions = array?[1] as? [String] else {
                self.handleInvalidResponseError(callback: callback)
                return
            }

            callback(suggestions, nil)
        }
        task?.resume()
    }

    private func handleInvalidResponseError(callback: @escaping (_ response: [String]?, _ error: NSError?) -> Void) {
        let error = NSError(
            domain: SearchSuggestClientErrorDomain,
            code: SearchSuggestClientErrorInvalidResponse,
            userInfo: nil
        )
        callback(nil, error)
    }

    func cancelPendingRequest() {
        task?.cancel()
    }
}
