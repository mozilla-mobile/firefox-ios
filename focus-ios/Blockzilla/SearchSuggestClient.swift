/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

let SearchSuggestClientErrorDomain = "org.mozilla.firefox.SearchSuggestClient"
let SearchSuggestClientErrorInvalidEngine = 0
let SearchSuggestClientErrorInvalidResponse = 1

class SearchSuggestClient {
    private var request: NSMutableURLRequest?
    
    func getSuggestions(_ query: String, callback: @escaping (_ response: [String]?, _ error: NSError?) -> Void) {
        guard let url = SearchEngineManager(prefs: UserDefaults.standard).activeEngine.urlForSuggestions(query) else {
            let error = NSError(domain: SearchSuggestClientErrorDomain, code: SearchSuggestClientErrorInvalidEngine, userInfo: nil)
            callback(nil, error)
            return
        }
        
        let request = URLRequest(url:url)
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            do {
                // The response will be of the following format:
                //    ["foobar",["foobar","foobar2000 mac","foobar skins",...]]
                // That is, an array of at least two elements: the search term and an array of suggestions.
                guard let myData = data, let array = try JSONSerialization.jsonObject(with: myData, options: []) as? [Any] else {
                    throw NSError(domain: SearchSuggestClientErrorDomain, code: SearchSuggestClientErrorInvalidResponse, userInfo: nil)
                }
                
                if array.count < 2 {
                    throw NSError(domain: SearchSuggestClientErrorDomain, code: SearchSuggestClientErrorInvalidResponse, userInfo: nil)
                }
                
                if var suggestions = array[1] as? [String] {
                    if let searchWord = array[0] as? String {
                        suggestions = suggestions.filter { $0 != searchWord }
                        suggestions.insert(searchWord, at: 0)
                    }
                    callback(suggestions, nil)
                    return
                }
                throw NSError(domain: SearchSuggestClientErrorDomain, code: SearchSuggestClientErrorInvalidResponse, userInfo: nil)
            } catch let error as NSError {
                callback(nil, error)
                return
            }
            }.resume()
    }
}
