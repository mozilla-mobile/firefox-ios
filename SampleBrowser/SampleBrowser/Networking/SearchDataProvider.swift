// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class SearchDataProvider: SearchDataProviderProtocol {
    enum SearchEndpoints {
        case suggestions
        case searchTerm

        var baseURL: String {
            switch self {
            case .suggestions:
                return "https://api.bing.com/osjson.aspx"
            case .searchTerm:
                return "https://www.bing.com/search?q="
            }
        }
    }

    let defaultSession = URLSession(configuration: .default)
    var dataTask: URLSessionDataTask?
    var searchModel: SearchModel?
    var error: BrowserError?
    let suggestionQuery = "query="

    func getSearchResults(text: String, completion: @escaping (SearchModel?, BrowserError?) -> Void) {
        dataTask?.cancel()

        guard var urlComponents = URLComponents(string: SearchEndpoints.suggestions.baseURL) else {
            return
        }

        urlComponents.query = "\(suggestionQuery)\(text)"
        guard let url = urlComponents.url else { return }

        dataTask = defaultSession.dataTask(with: url, completionHandler: { [weak self] data, response, error in
            defer {
                self?.dataTask = nil
            }

            if let error = error, (error as NSError).code != NSURLErrorCancelled {
                self?.error = BrowserError.dataTaskError(error.localizedDescription)
            } else if let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 {
                self?.updateResults(data: data)

                DispatchQueue.main.async {
                    completion(self?.searchModel, self?.error)
                }
            }
        })
        dataTask?.resume()
    }
}
